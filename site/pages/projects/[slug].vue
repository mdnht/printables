<template>
  <div class="project-detail">
    <div v-if="pending" class="loading">
      Loading...
    </div>
    <div v-else-if="!project" class="error">
      プロジェクトが見つかりませんでした。
    </div>
    <div v-else>
      <div class="header">
        <h1>{{ project.name }}</h1>
        <p class="desc">{{ project.description }}</p>
        <div class="meta">
          <span>v{{ project.version || '0.0.0' }}</span>
          <span>by {{ project.author || 'unknown' }}</span>
        </div>
        <div class="tags" v-if="project.tags && project.tags.length">
          <span v-for="tag in project.tags" :key="tag" class="tag">{{ tag }}</span>
        </div>
      </div>

      <div class="content">
        <div class="preview-section">
          <h2>3D Preview</h2>
          <div v-if="isRendering" class="rendering-overlay">
            <div class="spinner"></div>
            <p>Rendering with OpenSCAD...</p>
          </div>
          <StlViewer v-if="stlData" :stlData="stlData" />
          <div v-else-if="!isRendering && !stlData && !renderError" class="no-preview">
            Preview will appear here
          </div>
          <div v-if="renderError" class="render-error">
            {{ renderError }}
          </div>
        </div>

        <div class="code-section">
          <div class="code-header">
            <h2>Source Code</h2>
            <button @click="renderScad" class="render-btn" :disabled="isRendering">
              {{ isRendering ? 'Rendering...' : 'Render' }}
            </button>
          </div>
          <textarea v-model="scadCode" class="scad-editor" spellcheck="false"></textarea>
        </div>
      </div>

      <div class="actions">
        <a v-if="project.hasDownload" class="dl-btn" :href="`${useRuntimeConfig().app.baseURL}downloads/${project._slug}.zip`" download>
          <svg class="dl-icon" aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
            <polyline points="7 10 12 15 17 10"/>
            <line x1="12" y1="15" x2="12" y2="3"/>
          </svg> Download ZIP
        </a>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import MyWorker from '~/utils/openscad.worker?worker'
import StlViewer from '~/components/StlViewer.vue'

const route = useRoute()
const slug = route.params.slug

const { data: project, pending } = await useFetch(`/api/projects/${slug}`)


const scadCode = ref('')
const stlData = ref(null)
const isRendering = ref(false)
const renderError = ref(null)
let worker = null

onMounted(() => {
  if (import.meta.client) {
    worker = new MyWorker()
    worker.onmessage = (e) => {
      const { type, message, error, stlContent } = e.data
      if (type === 'success') {
        stlData.value = stlContent
        isRendering.value = false
      } else if (type === 'fatal') {
        renderError.value = 'Failed to render 3D model: ' + error
        isRendering.value = false
      } else if (type === 'error') {
        console.error('OpenSCAD error:', message)
      } else if (type === 'log') {
        console.log('OpenSCAD log:', message)
      }
    }
  }
})

// Clean up worker when component is unmounted
onUnmounted(() => {
  if (worker) {
    worker.terminate()
  }
})

watch(project, (newProject) => {
  if (newProject && newProject.scadCode) {
    scadCode.value = newProject.scadCode
    // Auto-render on load if code exists
    setTimeout(renderScad, 100)
  }
}, { immediate: true })

async function renderScad() {
  if (!scadCode.value || !import.meta.client) return

  isRendering.value = true
  renderError.value = null

  if (worker) {
    worker.postMessage({ code: scadCode.value, id: Date.now() })
  } else {
    renderError.value = 'Worker not initialized'
    isRendering.value = false
  }
}

useHead({
  title: project.value ? `${project.value.name} - 3D Model Catalog` : 'Loading... - 3D Model Catalog'
})
</script>

<style scoped>
.project-detail {
  background: #fff;
  border-radius: 10px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  padding: 2rem;
}

.header {
  margin-bottom: 2rem;
  border-bottom: 1px solid #eee;
  padding-bottom: 1rem;
}

.header h1 {
  margin: 0 0 0.5rem;
  font-size: 2rem;
  color: #0f3460;
}

.desc {
  font-size: 1.1rem;
  color: #444;
  margin-bottom: 1rem;
}

.meta {
  font-size: 0.9rem;
  color: #666;
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
}

.tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.tag {
  background: #e8eaf6;
  color: #3949ab;
  border-radius: 4px;
  padding: 0.2rem 0.6rem;
  font-size: 0.8rem;
}

.content {
  display: grid;
  grid-template-columns: 1fr;
  gap: 2rem;
  margin-bottom: 2rem;
}

@media (min-width: 768px) {
  .content {
    grid-template-columns: 1fr 1fr;
  }
}

.preview-section, .code-section {
  display: flex;
  flex-direction: column;
}

.preview-section h2, .code-header h2 {
  font-size: 1.2rem;
  margin: 0 0 1rem;
  color: #16213e;
}

.code-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.code-header h2 {
  margin-bottom: 0;
}

.render-btn {
  background: #e91e63;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
  transition: background 0.2s;
}

.render-btn:hover:not(:disabled) {
  background: #c2185b;
}

.render-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.scad-editor {
  flex-grow: 1;
  min-height: 400px;
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 0.9rem;
  padding: 1rem;
  border: 1px solid #ddd;
  border-radius: 8px;
  background: #fafafa;
  resize: vertical;
}

.rendering-overlay {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 400px;
  background: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #eee;
}

.spinner {
  border: 4px solid rgba(0, 0, 0, 0.1);
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border-left-color: #e91e63;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.no-preview {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 400px;
  background: #f8f9fa;
  border-radius: 8px;
  border: 1px dashed #ccc;
  color: #888;
}

.render-error {
  margin-top: 1rem;
  padding: 1rem;
  background: #ffebee;
  color: #c62828;
  border-radius: 4px;
  font-size: 0.9rem;
}

.actions {
  display: flex;
  justify-content: center;
  margin-top: 2rem;
  padding-top: 2rem;
  border-top: 1px solid #eee;
}

.dl-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  background: #3949ab;
  color: #fff;
  border-radius: 6px;
  padding: 0.8rem 1.5rem;
  font-size: 1rem;
  font-weight: bold;
  text-decoration: none;
  transition: background 0.2s;
}

.dl-btn:hover {
  background: #283593;
}

.dl-icon {
  width: 1.2em;
  height: 1.2em;
}
</style>
