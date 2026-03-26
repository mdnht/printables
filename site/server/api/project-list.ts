import { execFile } from 'child_process'
import util from 'util'
const execFileAsync = util.promisify(execFile)
import { promises as fs } from 'fs'
import path from 'path'

const handler = async (event: any) => {
  // Define path to the projects directory.
  // When running with `nuxt generate`, the root might differ, so we use process.cwd() as the base.
  // Depending on where `npm run generate` is run, process.cwd() could be `site` or project root.
  // Actually, standard is to run inside `site`.
  // The directory structure is: repo-root/projects and repo-root/site.
  // If we're inside site/, repo-root is `..`
  const projectsDir = path.resolve(process.cwd(), '../projects')

  try {
    const entries = await fs.readdir(projectsDir, { withFileTypes: true })
    const projects = []

    for (const entry of entries) {
      if (entry.isDirectory()) {
        const projectJsonPath = path.join(projectsDir, entry.name, 'project.json')
        try {
          const fileContent = await fs.readFile(projectJsonPath, 'utf-8')
          const data = JSON.parse(fileContent)

          if (data.publish) {
            data._slug = entry.name

            // Set project_type, defaulting to 'model'
            data.project_type = data.project_type || 'model'

            // Add last modified date from git log if available
            let updatedAt: string | undefined;
            try {
              const projectPath = path.join(projectsDir, entry.name)
              const { stdout } = await execFileAsync('git', ['log', '-1', '--format=%cI', '--', projectPath])
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
              const zipPath = path.resolve(process.cwd(), 'public/downloads', `${entry.name}.zip`)
              const stat = await fs.stat(zipPath)
              hasDownload = stat.isFile()
            } catch (e) {
              // file doesn't exist
            }
            data.hasDownload = hasDownload

            projects.push(data)
          }
        } catch (err) {
          // If project.json doesn't exist or is invalid JSON, just skip this directory
          console.warn(`Could not read/parse project.json for ${entry.name}:`, err.message)
        }
      }
    }

    // Sort projects by updatedAt (descending by default)
    projects.sort((a, b) => {
      const dateA = new Date(a.updatedAt || 0)
      const dateB = new Date(b.updatedAt || 0)
      return dateB.getTime() - dateA.getTime()
    })

    return projects
  } catch (err) {
    console.error('Error reading projects directory:', err)
    return []
  }
}

export default typeof defineEventHandler === 'function' ? defineEventHandler(handler) : handler
