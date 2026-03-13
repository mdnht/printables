<template>
  <div>
    <div class="controls" v-if="projects && projects.length > 0">
      <label for="sort-select">並べ替え:</label>
      <select id="sort-select" v-model="sortOption" class="sort-select">
        <option value="updatedAtDesc">更新日 (新しい順)</option>
        <option value="updatedAtAsc">更新日 (古い順)</option>
        <option value="nameAsc">プロジェクト名 (A-Z)</option>
        <option value="nameDesc">プロジェクト名 (Z-A)</option>
      </select>
    </div>
    <div v-if="pending" class="empty">
      Loading...
    </div>
    <div v-else-if="!projects || projects.length === 0" class="empty">
      <p>公開されているプロジェクトはありません。</p>
    </div>
    <div v-else class="grid">
      <div v-for="project in sortedProjects" :key="project._slug" class="card">
        <img
          class="card-preview"
          :src="`${useRuntimeConfig().app.baseURL}images/${project._slug}.png`"
          :alt="project.name || project._slug"
          loading="lazy"
          @error="handleImageError"
        >

        <h2>
          <NuxtLink :to="`/projects/${project._slug}`" class="card-link">
            {{ project.name }}
          </NuxtLink>
        </h2>
        <p class="desc">{{ project.description }}</p>

        <div class="meta">
          <span v-if="project.updatedAt" class="date" :title="formatDate(project.updatedAt)">
            <svg class="icon" aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
              <line x1="16" y1="2" x2="16" y2="6"></line>
              <line x1="8" y1="2" x2="8" y2="6"></line>
              <line x1="3" y1="10" x2="21" y2="10"></line>
            </svg>
            {{ formatDate(project.updatedAt) }}
          </span>
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
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const { data: projects, pending } = await useFetch('/api/project-list')

const sortOption = ref('updatedAtDesc')

const sortedProjects = computed(() => {
  if (!projects.value) return []

  // Create a shallow copy to sort
  const list = [...projects.value]

  return list.sort((a, b) => {
    const dateA = new Date(a.updatedAt || 0).getTime()
    const dateB = new Date(b.updatedAt || 0).getTime()
    const nameA = a.name || ''
    const nameB = b.name || ''

    if (sortOption.value === 'updatedAtDesc') return dateB - dateA
    if (sortOption.value === 'updatedAtAsc') return dateA - dateB
    if (sortOption.value === 'nameAsc') return nameA.localeCompare(nameB)
    if (sortOption.value === 'nameDesc') return nameB.localeCompare(nameA)
    return 0
  })
})

function formatDate(isoString) {
  if (!isoString) return ''
  const date = new Date(isoString)
  return date.toLocaleDateString('ja-JP', { year: 'numeric', month: 'short', day: 'numeric' })
}

function handleImageError(event) {
  event.target.style.display = 'none';
}

function isDraftVersion(version) {
  if (!version) return true;
  try {
    const parts = version.trim().split('.').map(Number);
    if (parts.some(p => isNaN(p) || p < 0)) return false;
    return parts[0] < 1;
  } catch (e) {
    return false;
  }
}


</script>

<style scoped>
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
  position: relative;
  text-decoration: none;
  color: inherit;
  background: #fff;
  border-radius: 10px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  transition: box-shadow 0.2s, transform 0.2s;
  cursor: pointer;
}

.card-link {
  text-decoration: none;
  color: inherit;
}

.card-link::after {
  content: '';
  position: absolute;
  inset: 0;
  z-index: 1;
}

.card:hover {
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.13);
  transform: translateY(-2px);
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
  position: relative;
  z-index: 2;
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
.controls {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  margin-bottom: 1.5rem;
  gap: 0.5rem;
}

.controls label {
  font-size: 0.9rem;
  color: #555;
  font-weight: 500;
}

.sort-select {
  padding: 0.5rem 2rem 0.5rem 1rem;
  font-size: 0.95rem;
  color: #333;
  background-color: #fff;
  border: 1px solid #ccc;
  border-radius: 6px;
  appearance: none;
  background-image: url("data:image/svg+xml;charset=UTF-8,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23333' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='6 9 12 15 18 9'%3E%3C/polyline%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 0.7rem center;
  background-size: 1em;
  cursor: pointer;
  transition: border-color 0.2s, box-shadow 0.2s;
}

.sort-select:focus {
  outline: none;
  border-color: #3949ab;
  box-shadow: 0 0 0 3px rgba(57, 73, 171, 0.2);
}

.icon {
  width: 1em;
  height: 1em;
  vertical-align: -0.15em;
  margin-right: 0.2em;
}

.date {
  color: #777;
}

</style>
