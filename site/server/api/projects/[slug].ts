import { promises as fs } from 'fs'
import path from 'path'
import { execFile } from 'child_process'
import util from 'util'

const execFilePromise = util.promisify(execFile)

export default defineEventHandler(async (event) => {
  const slug = getRouterParam(event, 'slug')

  // Security: strictly validate the slug to prevent path traversal and command injection
  if (!slug || !/^[a-zA-Z0-9_-]+$/.test(slug)) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid project slug',
    })
  }

  const projectsDir = path.resolve(process.cwd(), '../projects')
  const projectDir = path.join(projectsDir, slug)

  try {
    const projectJsonPath = path.join(projectDir, 'project.json')
    const fileContent = await fs.readFile(projectJsonPath, 'utf-8')
    const data = JSON.parse(fileContent)

    if (data.publish) {
      data._slug = slug

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
            const { stdout } = await execFilePromise('python3', [bundleScript, mainScad])
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
})
