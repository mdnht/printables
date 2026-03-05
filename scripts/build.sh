#!/usr/bin/env bash
# build.sh – Build one or all OpenSCAD projects into bundled .scad files.
#
# Usage
# -----
#   ./scripts/build.sh                   # build all projects
#   ./scripts/build.sh example-box       # build a single project
#   ./scripts/build.sh example-box other # build multiple specific projects
#
# Output
# ------
#   dist/<project-name>.scad  – bundled, self-contained OpenSCAD file
#   dist/<project-name>.png   – rendered preview image (requires openscad)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${REPO_ROOT}/dist"
SCRIPTS_DIR="${REPO_ROOT}/scripts"
PROJECTS_DIR="${REPO_ROOT}/projects"

mkdir -p "${DIST_DIR}"

# Default preview image size (width,height)
PREVIEW_IMGSIZE="${PREVIEW_IMGSIZE:-640,480}"

# ── helpers ─────────────────────────────────────────────────────────────────

log()  { echo "[build] $*"; }
warn() { echo "[build] WARNING: $*" >&2; }
die()  { echo "[build] ERROR: $*" >&2; exit 1; }

build_project() {
    local project="$1"
    local project_dir="${PROJECTS_DIR}/${project}"
    local main_scad="${project_dir}/main.scad"
    local out_file="${DIST_DIR}/${project}.scad"

    [[ -d "${project_dir}" ]] || die "Project directory not found: ${project_dir}"
    [[ -f "${main_scad}" ]]   || die "main.scad not found in: ${project_dir}"

    log "Building project: ${project}"
    python3 "${SCRIPTS_DIR}/bundle.py" \
        "${main_scad}" \
        --repo-root "${REPO_ROOT}" \
        --tree-shake \
        -o "${out_file}"
    log "  → ${out_file}"

    render_preview "${project}"
}

render_preview() {
    local project="$1"
    local main_scad="${PROJECTS_DIR}/${project}/main.scad"
    local out_png="${DIST_DIR}/${project}.png"

    if ! command -v openscad &>/dev/null; then
        warn "openscad not found – skipping preview render for ${project}"
        return 0
    fi

    log "Rendering preview: ${project}"
    openscad -o "${out_png}" --imgsize="${PREVIEW_IMGSIZE}" "${main_scad}" 2>/dev/null \
        && log "  → ${out_png}" \
        || warn "Preview render failed for ${project} (non-fatal)"
}

# ── entry point ─────────────────────────────────────────────────────────────

if [[ $# -eq 0 ]]; then
    # Build every project that has a main.scad
    found=0
    for project_dir in "${PROJECTS_DIR}"/*/; do
        project="$(basename "${project_dir}")"
        if [[ -f "${project_dir}/main.scad" ]]; then
            build_project "${project}"
            found=$((found + 1))
        fi
    done
    [[ ${found} -gt 0 ]] || warn "No projects found in ${PROJECTS_DIR}"
else
    for project in "$@"; do
        build_project "${project}"
    done
fi
