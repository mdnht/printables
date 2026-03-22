// https://nuxt.com/docs/api/configuration/nuxt-config
import fs from 'fs'
import path from 'path'

// Function to get all project slugs
function getProjectSlugs() {
  try {
    const projectsDir = path.resolve(process.cwd(), '../projects')
    if (!fs.existsSync(projectsDir)) return []

    const entries = fs.readdirSync(projectsDir, { withFileTypes: true })
    const slugs = []

    for (const entry of entries) {
      if (entry.isDirectory()) {
        const projectJsonPath = path.join(projectsDir, entry.name, 'project.json')
        if (fs.existsSync(projectJsonPath)) {
          const content = fs.readFileSync(projectJsonPath, 'utf-8')
          const data = JSON.parse(content)
          if (data.publish) {
            slugs.push(entry.name)
          }
        }
      }
    }
    return slugs
  } catch (e) {
    console.error('Error reading projects for prerender:', e)
    return []
  }
}

const slugs = getProjectSlugs()
const apiRoutes = slugs.map(slug => `/api/projects/${slug}`)
apiRoutes.push('/api/project-list')

export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  app: {
    // Determine baseURL from the repository name if available.
    // GitHub Pages deploys to /<repo-name>/, so we can use process.env.GITHUB_REPOSITORY
    // If running locally, we fallback to '/'
    baseURL: process.env.GITHUB_REPOSITORY ? `/${process.env.GITHUB_REPOSITORY.split('/')[1]}/` : '/'
  },
  nitro: {
    prerender: {
      crawlLinks: true,
      routes: ['/', ...apiRoutes]
    }
  },
  vite: {
    worker: {
      format: 'es'
    }
  }
})
