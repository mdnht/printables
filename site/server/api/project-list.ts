import { promises as fs } from 'fs'
import path from 'path'

export default defineEventHandler(async (event) => {
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

            // Add last modified date
            try {
              const stat = await fs.stat(projectJsonPath)
              data.updatedAt = stat.mtime.toISOString()
            } catch (e) {
              data.updatedAt = new Date(0).toISOString()
            }

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
})
