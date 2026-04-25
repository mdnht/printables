import { execFile } from 'child_process'
import { promises as fs } from 'fs'
import path from 'path'
import util from 'util'

const execFileAsync = util.promisify(execFile)

const handler = async (event: any) => {
  const slug = getRouterParam(event, 'slug')

  // Validate slug to prevent command injection and path traversal
  if (typeof slug !== 'string' || !/^[a-zA-Z0-9_-]+$/.test(slug)) {
    return null
  }

  const projectsDir = path.resolve(process.cwd(), '../projects')
  const projectDir = path.resolve(projectsDir, slug)

  // Extra path traversal check
  const relative = path.relative(projectsDir, projectDir)
  if (relative.startsWith('..') || path.isAbsolute(relative)) {
    return null
  }

  try {
    const projectJsonPath = path.join(projectDir, 'project.json')
    const fileContent = await fs.readFile(projectJsonPath, 'utf-8')
    const data = JSON.parse(fileContent)

    if (data.publish) {
      data._slug = slug

      // Add last modified date from git log if available
      let updatedAt: string | undefined;
      try {
        const { stdout } = await execFileAsync('git', ['log', '-1', '--format=%cI', '--', projectDir])
        const gitDate = stdout.trim()
        if (gitDate) {
          updatedAt = new Date(gitDate).toISOString()
        }
      } catch (e) {
        // Git log failed, proceed to fallback
      }

      if (!updatedAt) {
        // Fallback to mtime if git log failed or returned no date
        try {
          const stat = await fs.stat(projectJsonPath)
          updatedAt = stat.mtime.toISOString()
        } catch (e) {
          // If fs.stat also fails, set a default date.
          updatedAt = new Date(0).toISOString()
        }
      }
      data.updatedAt = updatedAt

      // Check if the download artifact exists during generation
      let hasDownload = false
      try {
        const zipPath = path.resolve(process.cwd(), 'public/downloads', `${slug}.zip`)
        const stat = await fs.stat(zipPath)
        hasDownload = stat.isFile()
      } catch (e) {
        // file doesn't exist
      }
      data.hasDownload = hasDownload

      let bundledCode = ''

      // Try to read from bundled artifact first (if available from CI)
      try {
          const scadArtifactPath = path.resolve(process.cwd(), 'public/downloads', `${slug}.scad`)
          bundledCode = await fs.readFile(scadArtifactPath, 'utf-8')
      } catch (e) {
          // Bundled artifact not found, let's try to generate it dynamically!
          try {
            const bundleScript = path.resolve(process.cwd(), '../scripts/bundle.py')
            const mainScad = path.join(projectDir, 'main.scad')
            const { stdout } = await execFileAsync('python3', [bundleScript, mainScad])
            bundledCode = stdout
          } catch (execErr) {
            console.warn(`Failed to dynamically bundle ${slug}:`, execErr.message)
            // Fallback to raw code
            try {
              const scadPath = path.join(projectDir, 'main.scad')
              bundledCode = await fs.readFile(scadPath, 'utf-8')
            } catch (err) {
              console.warn(`Could not read main.scad for ${slug}:`, err.message)
            }
          }
      }

      data.scadCode = bundledCode

      return data
    }
    return null
  } catch (err) {
    console.error(`Error reading project ${slug}:`, err)
    return null
  }
}

export default typeof defineEventHandler === 'function' ? defineEventHandler(handler) : handler
