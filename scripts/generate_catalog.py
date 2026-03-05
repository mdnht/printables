#!/usr/bin/env python3
"""
generate_catalog.py – Generate a static HTML catalog page for all published
OpenSCAD projects in the repository.

The script scans ``projects/*/project.json`` for metadata, filters by the
``publish`` flag, and writes a self-contained ``index.html`` to the specified
output directory.

Usage
-----
    python scripts/generate_catalog.py [--output-dir _site] [--repo-root .]
"""

import argparse
import html
import json
import sys
from pathlib import Path

HTML_TEMPLATE = """\
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>3D Model Catalog</title>
<style>
*,*::before,*::after{box-sizing:border-box}
body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  color:#1a1a2e;background:#f5f6fa;line-height:1.6}
header{background:linear-gradient(135deg,#0f3460,#16213e);color:#fff;padding:2rem 1rem;text-align:center}
header h1{margin:0 0 .25rem;font-size:1.75rem}
header p{margin:0;opacity:.85;font-size:.95rem}
main{max-width:960px;margin:2rem auto;padding:0 1rem}
.empty{text-align:center;color:#888;margin-top:3rem}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:1.25rem}
.card{background:#fff;border-radius:10px;box-shadow:0 2px 8px rgba(0,0,0,.08);
  padding:1.5rem;display:flex;flex-direction:column;transition:box-shadow .2s}
.card:hover{box-shadow:0 4px 16px rgba(0,0,0,.13)}
.card h2{margin:0 0 .5rem;font-size:1.2rem}
.card .desc{flex:1;color:#444;font-size:.9rem;margin-bottom:.75rem}
.meta{font-size:.8rem;color:#666;display:flex;flex-wrap:wrap;gap:.35rem .75rem;margin-bottom:.5rem}
.tags{display:flex;flex-wrap:wrap;gap:.35rem}
.tag{background:#e8eaf6;color:#3949ab;border-radius:4px;padding:.15rem .5rem;font-size:.75rem}
footer{text-align:center;color:#aaa;font-size:.8rem;padding:2rem 1rem}
</style>
</head>
<body>
<header>
  <h1>3D Model Catalog</h1>
  <p>OpenSCAD プロジェクト一覧</p>
</header>
<main>
{{content}}
</main>
<footer>Auto-generated from project metadata.</footer>
</body>
</html>
"""

CARD_TEMPLATE = """\
<article class="card">
  <h2>{name}</h2>
  <p class="desc">{description}</p>
  <div class="meta">
    <span>v{version}</span>
    <span>by {author}</span>
  </div>
  <div class="tags">{tags_html}</div>
</article>"""


def load_projects(repo_root: Path) -> list[dict]:
    """Return a sorted list of published project metadata dicts."""
    projects_dir = repo_root / "projects"
    if not projects_dir.is_dir():
        return []

    results: list[dict] = []
    for project_json in sorted(projects_dir.glob("*/project.json")):
        try:
            data = json.loads(project_json.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError) as exc:
            print(f"WARNING: skipping {project_json}: {exc}", file=sys.stderr)
            continue

        if not data.get("publish", False):
            continue

        results.append(data)

    results.sort(key=lambda p: p.get("name", ""))
    return results


def render_card(project: dict) -> str:
    tags = project.get("tags", [])
    tags_html = "".join(
        f'<span class="tag">{html.escape(t)}</span>' for t in tags
    )
    return CARD_TEMPLATE.format(
        name=html.escape(project.get("name", "unknown")),
        description=html.escape(project.get("description", "")),
        version=html.escape(project.get("version", "0.0.0")),
        author=html.escape(project.get("author", "unknown")),
        tags_html=tags_html,
    )


def generate_html(projects: list[dict]) -> str:
    if not projects:
        content = '<p class="empty">公開されているプロジェクトはありません。</p>'
    else:
        cards = "\n".join(render_card(p) for p in projects)
        content = f'<div class="grid">\n{cards}\n</div>'

    return HTML_TEMPLATE.replace("{{content}}", content)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Generate a static HTML catalog for published OpenSCAD projects."
    )
    parser.add_argument(
        "--output-dir",
        default="_site",
        help="Directory to write the generated index.html (default: _site).",
    )
    parser.add_argument(
        "--repo-root",
        default=None,
        help=(
            "Repository root directory.  Defaults to two levels above this "
            "script (i.e. the repo root when the script lives in scripts/)."
        ),
    )

    args = parser.parse_args(argv)

    script_dir = Path(__file__).resolve().parent
    repo_root = Path(args.repo_root).resolve() if args.repo_root else script_dir.parent

    projects = load_projects(repo_root)
    print(f"Found {len(projects)} published project(s).", file=sys.stderr)

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    out_file = out_dir / "index.html"
    out_file.write_text(generate_html(projects), encoding="utf-8")
    print(f"Catalog written to {out_file}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    sys.exit(main())
