#!/usr/bin/env python3
"""
generate_catalog.py – Build the catalog site from source templates.

Reads the HTML template and stylesheet from ``site/``, scans
``projects/*/project.json`` for metadata, and writes a self-contained
``index.html`` to the output directory.

Usage
-----
    python scripts/generate_catalog.py [--output-dir _site] [--repo-root .] [--images-dir images]
"""

import argparse
import html
import json
import shutil
import sys
import urllib.parse
from pathlib import Path
from string import Template

# Pre-compiled template for individual project cards.
# Uses $-prefixed placeholders to avoid conflicts with CSS braces.
_CARD_TEMPLATE = Template("""\
<article class="card">
$image_html  <h2>$name</h2>
  <p class="desc">$description</p>
  <div class="meta">
    <span>v$version</span>
    <span>by $author</span>
  </div>
  <div class="tags">$tags_html</div>
$downloads_html</article>""")


def load_projects(repo_root: Path) -> list[dict]:
    """Return a sorted list of published project metadata dicts."""
    projects_dir = repo_root / "projects"
    if not projects_dir.is_dir():
        return []

    results: list[dict] = []
    for project_json in projects_dir.glob("*/project.json"):
        try:
            data = json.loads(project_json.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError) as exc:
            print(f"WARNING: skipping {project_json}: {exc}", file=sys.stderr)
            continue

        if not data.get("publish", False):
            continue

        # Store directory name as slug for image lookup.
        data["_slug"] = project_json.parent.name
        results.append(data)

    results.sort(key=lambda p: p.get("name", ""))
    return results


def render_card(
    project: dict,
    images_dir: Path | None = None,
    downloads_dir: Path | None = None,
) -> str:
    """Render a single project card from metadata."""
    tags = project.get("tags", [])
    if not isinstance(tags, list):
        tags = []
    tags_html = "".join(
        f'<span class="tag">{html.escape(str(t))}</span>' for t in tags
    )

    # Build image HTML if a preview image exists.
    image_html = ""
    slug = project.get("_slug", "")
    if images_dir and slug:
        img_path = images_dir / f"{slug}.png"
        if img_path.is_file():
            image_html = (
                f'  <img class="card-preview" src="images/{urllib.parse.quote(slug)}.png"'
                f' alt="{html.escape(project.get("name", slug))}" loading="lazy">\n'
            )

    # Build download links when artifacts are available.
    downloads_html = ""
    if downloads_dir and slug:
        links: list[str] = []
        scad_path = downloads_dir / f"{slug}.scad"
        if scad_path.is_file():
            links.append(
                f'<a class="dl-btn" href="downloads/{urllib.parse.quote(slug)}.scad"'
                f' download>📦 .scad</a>'
            )
        png_path = downloads_dir / f"{slug}.png"
        if png_path.is_file():
            links.append(
                f'<a class="dl-btn" href="downloads/{urllib.parse.quote(slug)}.png"'
                f' download>🖼️ .png</a>'
            )
        if links:
            downloads_html = f'  <div class="downloads">{"".join(links)}</div>\n'

    return _CARD_TEMPLATE.substitute(
        name=html.escape(project.get("name", "unknown")),
        description=html.escape(project.get("description", "")),
        version=html.escape(project.get("version", "0.0.0")),
        author=html.escape(project.get("author", "unknown")),
        tags_html=tags_html,
        image_html=image_html,
        downloads_html=downloads_html,
    )


def build_site(
    repo_root: Path,
    out_dir: Path,
    images_dir: Path | None = None,
    downloads_dir: Path | None = None,
) -> None:
    """Build the catalog site from source templates and project metadata."""
    site_dir = repo_root / "site"

    template_path = site_dir / "index.html"
    if not template_path.is_file():
        print(f"ERROR: template not found: {template_path}", file=sys.stderr)
        sys.exit(1)

    style_path = site_dir / "style.css"
    if not style_path.is_file():
        print(f"ERROR: stylesheet not found: {style_path}", file=sys.stderr)
        sys.exit(1)

    template = template_path.read_text(encoding="utf-8")
    style_css = style_path.read_text(encoding="utf-8")

    projects = load_projects(repo_root)
    print(f"Found {len(projects)} published project(s).", file=sys.stderr)

    if not projects:
        catalog_html = '<p class="empty">公開されているプロジェクトはありません。</p>'
    else:
        cards = "\n".join(
            render_card(p, images_dir, downloads_dir) for p in projects
        )
        catalog_html = f'<div class="grid">\n{cards}\n</div>'

    # Replace template placeholders
    output = template.replace(
        "<!-- {{inline_style}} -->", f"<style>\n{style_css}</style>"
    ).replace(
        "<!-- {{catalog_content}} -->", catalog_html
    )

    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "index.html"
    out_file.write_text(output, encoding="utf-8")
    print(f"Catalog written to {out_file}", file=sys.stderr)

    # Copy preview images to output directory.
    if images_dir and images_dir.is_dir():
        dest_images = out_dir / "images"
        dest_images.mkdir(parents=True, exist_ok=True)
        # Skip copy when source and destination are the same directory.
        if images_dir.resolve() != dest_images.resolve():
            copied = 0
            for img in images_dir.glob("*.png"):
                shutil.copy2(img, dest_images / img.name)
                copied += 1
            print(f"Copied {copied} preview image(s) to {dest_images}", file=sys.stderr)
        else:
            count = sum(1 for _ in dest_images.glob("*.png"))
            print(f"Using {count} preview image(s) in {dest_images}", file=sys.stderr)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Build the catalog site from source templates and project metadata."
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
    parser.add_argument(
        "--images-dir",
        default=None,
        help=(
            "Directory containing rendered preview images (<slug>.png). "
            "Images are copied into the output directory and referenced in cards."
        ),
    )
    parser.add_argument(
        "--downloads-dir",
        default=None,
        help=(
            "Directory containing downloadable build artifacts "
            "(<slug>.scad, <slug>.png). When present, download buttons "
            "are added to the project cards."
        ),
    )

    args = parser.parse_args(argv)

    script_dir = Path(__file__).resolve().parent
    repo_root = Path(args.repo_root).resolve() if args.repo_root else script_dir.parent

    images_dir = Path(args.images_dir).resolve() if args.images_dir else None
    downloads_dir = Path(args.downloads_dir).resolve() if args.downloads_dir else None
    build_site(repo_root, Path(args.output_dir), images_dir, downloads_dir)
    return 0


if __name__ == "__main__":
    sys.exit(main())
