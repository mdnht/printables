// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  app: {
    // Determine baseURL from the repository name if available.
    // GitHub Pages deploys to /<repo-name>/, so we can use process.env.GITHUB_REPOSITORY
    // If running locally, we fallback to '/'
    baseURL: process.env.GITHUB_REPOSITORY ? `/${process.env.GITHUB_REPOSITORY.split('/')[1]}/` : '/'
  }
})
