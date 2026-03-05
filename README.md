# printables

OpenSCAD で記述された 3D モデルを統合管理するモノレポ。  
Monorepo for managing OpenSCAD 3D models with shared libraries and a unified build workflow.

---

## Repository structure

```
printables/
├── .github/
│   └── workflows/
│       └── build.yml          # CI/CD: detect changes → bundle → upload artifact
├── libs/
│   └── common.scad            # Shared OpenSCAD utility modules (rounded_box, etc.)
├── projects/
│   └── example-box/           # Example project (parametric storage box)
│       ├── project.json       # Project metadata (name, version, author, …)
│       └── main.scad          # Top-level OpenSCAD source
├── scripts/
│   ├── build.sh               # Local build helper
│   └── bundle.py              # Bundler: inlines use/include → single .scad file
├── dist/                      # Build output (git-ignored)
└── .gitignore
```

---

## Adding a new project

1. Create a directory under `projects/`:

   ```
   projects/my-model/
   ├── project.json
   └── main.scad
   ```

2. Write your `main.scad`, referencing shared libs with:

   ```openscad
   use <../../libs/common.scad>
   ```

3. Fill in `project.json`:

   ```json
   {
       "name": "my-model",
       "description": "Short description",
       "version": "1.0.0",
       "author": "your-name",
       "tags": ["tag1", "tag2"],
       "publish": true
   }
   ```

Push the changes – the CI workflow automatically detects the new/modified project  
and builds a bundled, self-contained `.scad` file as a downloadable artifact.

---

## Shared libraries (`libs/`)

Place reusable OpenSCAD modules and functions in `libs/`.  
They are automatically on the search path during bundling, so you can reference them as:

```openscad
use <../../libs/common.scad>   // relative path (works in OpenSCAD GUI too)
```

`libs/common.scad` currently provides:

| Module | Description |
|---|---|
| `rounded_box(size, r, fn)` | Rectangular box with rounded vertical corners |
| `cylinder_with_hole(h, r_outer, r_inner, fn)` | Hollow cylinder (tube) |
| `chamfer_box(size, chamfer)` | Box with chamfered top edges |
| `screw_hole(d, h, countersink, fn)` | Vertical screw/bolt hole |

---

## Local build

### Build all projects

```bash
bash scripts/build.sh
```

### Build a single project

```bash
bash scripts/build.sh example-box
```

Bundled files are written to `dist/<project-name>.scad`.

---

## CI/CD workflow

`.github/workflows/build.yml` runs on every push / pull request that touches  
`projects/`, `libs/`, or `scripts/`.

| Step | What it does |
|---|---|
| **detect-changes** | Determines which projects need rebuilding.<br>Changes to `libs/` or `scripts/` trigger a rebuild of **all** projects. |
| **build** | Runs `scripts/bundle.py` in a matrix over the affected projects, producing a single self-contained `.scad` per project. |
| **summary** | Writes a Markdown build summary to the workflow run page. |

Bundled `.scad` files are uploaded as GitHub Actions artifacts and can be  
downloaded and published directly to MakerWorld, Printables, Thingiverse, etc.

You can also trigger a manual build for a specific project from the  
**Actions → Build 3D Models → Run workflow** UI.
