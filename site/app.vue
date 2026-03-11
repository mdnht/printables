<template>
  <div>
    <header>
      <h1 lang="en">3D Model Catalog</h1>
      <p>OpenSCAD プロジェクト一覧</p>
    </header>
    <main>
      <div v-if="pending" class="empty">
        Loading...
      </div>
      <div v-else-if="!projects || projects.length === 0" class="empty">
        <p>公開されているプロジェクトはありません。</p>
      </div>
      <div v-else class="grid">
        <article v-for="project in projects" :key="project._slug" class="card">
          <img
            class="card-preview"
            :src="`${useRuntimeConfig().app.baseURL}images/${project._slug}.png`"
            :alt="project.name || project._slug"
            loading="lazy"
            @error="handleImageError"
          >

          <h2>{{ project.name }}</h2>
          <p class="desc">{{ project.description }}</p>

          <div class="meta">
            <span>v{{ project.version || '0.0.0' }}</span>
            <span v-if="isDraftVersion(project.version)" class="badge badge-draft">ドラフト</span>
            <span>by {{ project.author || 'unknown' }}</span>
          </div>

          <div class="tags" v-if="project.tags && project.tags.length">
            <span v-for="tag in project.tags" :key="tag" class="tag">{{ tag }}</span>
          </div>

          <div class="downloads" v-if="project.hasDownload">
            <a class="dl-btn" :href="`${useRuntimeConfig().app.baseURL}downloads/${project._slug}.zip`" download>
              <svg class="dl-icon" aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                <polyline points="7 10 12 15 17 10"/>
                <line x1="12" y1="15" x2="12" y2="3"/>
              </svg> Download
            </a>
          </div>
        </article>
      </div>
    </main>
    <footer lang="en">Auto-generated from project metadata.</footer>
  </div>
</template>

<script setup>
// Use Nuxt useAsyncData/useFetch to fetch data from our API route during SSR/Generation
const { data: projects, pending } = await useFetch('/api/projects')

// Fallback logic for images if they fail to load (e.g., artifact not available)
function handleImageError(event) {
  event.target.style.display = 'none';
}

function isDraftVersion(version) {
  if (!version) return true;
  try {
    const parts = version.trim().split('.').map(Number);
    if (parts.some(p => isNaN(p) || p < 0)) return false;
    while (parts.length < 3) parts.push(0);
    return parts[0] < 1 || (parts[0] === 1 && parts[1] === 0 && parts[2] === 0);
  } catch (e) {
    return false;
  }
}

useHead({
  title: '3D Model Catalog',
  htmlAttrs: {
    lang: 'ja'
  },
  meta: [
    { charset: 'utf-8' },
    { name: 'viewport', content: 'width=device-width, initial-scale=1' }
  ]
})
</script>

<style>
*,
*::before,
*::after {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
    Helvetica, Arial, sans-serif;
  color: #1a1a2e;
  background: #f5f6fa;
  line-height: 1.6;
}

header {
  background: linear-gradient(135deg, #0f3460, #16213e);
  color: #fff;
  padding: 2rem 1rem;
  text-align: center;
}

header h1 {
  margin: 0 0 0.25rem;
  font-size: 1.75rem;
}

header p {
  margin: 0;
  opacity: 0.85;
  font-size: 0.95rem;
}

main {
  max-width: 960px;
  margin: 2rem auto;
  padding: 0 1rem;
}

.empty {
  text-align: center;
  color: #888;
  margin-top: 3rem;
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.25rem;
}

.card {
  background: #fff;
  border-radius: 10px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  transition: box-shadow 0.2s;
}

.card:hover {
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.13);
}

.card h2 {
  margin: 0 0 0.5rem;
  font-size: 1.2rem;
}

.card-preview {
  width: 100%;
  aspect-ratio: 4 / 3;
  object-fit: cover;
  border-radius: 6px;
  margin-bottom: 0.75rem;
  background: #e8eaf6;
}

.card .desc {
  flex: 1;
  color: #444;
  font-size: 0.9rem;
  margin-bottom: 0.75rem;
}

.meta {
  font-size: 0.8rem;
  color: #666;
  display: flex;
  flex-wrap: wrap;
  gap: 0.35rem 0.75rem;
  margin-bottom: 0.5rem;
}

.tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.35rem;
}

.tag {
  background: #e8eaf6;
  color: #3949ab;
  border-radius: 4px;
  padding: 0.15rem 0.5rem;
  font-size: 0.75rem;
}

.badge {
  font-size: 0.7rem;
  border-radius: 4px;
  padding: 0.1rem 0.45rem;
  font-weight: bold;
  letter-spacing: 0.04em;
}

.badge-draft {
  background: #fff3cd;
  color: #856404;
}

.downloads {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-top: 0.75rem;
}

.dl-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  background: #3949ab;
  color: #fff;
  border-radius: 6px;
  padding: 0.4rem 0.85rem;
  font-size: 0.85rem;
  text-decoration: none;
  transition: background 0.2s;
}

.dl-btn:hover {
  background: #283593;
}

.dl-icon {
  width: 1em;
  height: 1em;
}

footer {
  text-align: center;
  color: #aaa;
  font-size: 0.8rem;
  padding: 2rem 1rem;
}
</style>
