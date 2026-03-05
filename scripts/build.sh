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

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${REPO_ROOT}/dist"
SCRIPTS_DIR="${REPO_ROOT}/scripts"
PROJECTS_DIR="${REPO_ROOT}/projects"

mkdir -p "${DIST_DIR}"

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
        --exclude BOSL2 \
        -o "${out_file}"
    log "  → ${out_file}"
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
