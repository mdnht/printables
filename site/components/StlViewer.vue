<template>
  <div ref="container" class="stl-viewer"></div>
</template>

<script setup>
import { onMounted, onUnmounted, ref, watch } from 'vue'
import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import { STLLoader } from 'three/examples/jsm/loaders/STLLoader.js'

const props = defineProps({
  stlData: {
    type: String, // String content of the STL file
    required: true
  }
})

const container = ref(null)
let scene, camera, renderer, controls, mesh

function init() {
  if (!container.value) return

  // Basic Three.js setup
  scene = new THREE.Scene()
  scene.background = new THREE.Color(0xf0f0f0)

  camera = new THREE.PerspectiveCamera(45, container.value.clientWidth / container.value.clientHeight, 1, 1000)
  camera.position.set(200, 200, 200)

  renderer = new THREE.WebGLRenderer({ antialias: true })
  renderer.setSize(container.value.clientWidth, container.value.clientHeight)
  container.value.appendChild(renderer.domElement)

  controls = new OrbitControls(camera, renderer.domElement)
  controls.enableDamping = true
  controls.dampingFactor = 0.25

  // Lights
  const ambientLight = new THREE.AmbientLight(0x404040)
  scene.add(ambientLight)

  const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8)
  directionalLight.position.set(1, 1, 1).normalize()
  scene.add(directionalLight)

  const directionalLight2 = new THREE.DirectionalLight(0xffffff, 0.5)
  directionalLight2.position.set(-1, -1, -1).normalize()
  scene.add(directionalLight2)

  window.addEventListener('resize', onWindowResize)

  loadStl()
  animate()
}

function loadStl() {
  if (!props.stlData) return
  if (mesh) {
    scene.remove(mesh)
    mesh.geometry.dispose()
    mesh.material.dispose()
  }

  const loader = new STLLoader()
  try {
    const geometry = loader.parse(props.stlData)
    const material = new THREE.MeshPhongMaterial({ color: 0x0f3460, specular: 0x111111, shininess: 200 })
    mesh = new THREE.Mesh(geometry, material)

    // Center geometry
    geometry.computeBoundingBox()
    const center = new THREE.Vector3()
    geometry.boundingBox.getCenter(center)
    mesh.position.sub(center) // Center the mesh

    // Create a group to handle centering properly with rotation
    const group = new THREE.Group()
    group.add(mesh)
    // Three.js Z-up to Y-up rotation
    group.rotation.x = -Math.PI / 2
    scene.add(group)

    // Adjust camera to fit object
    const box = new THREE.Box3().setFromObject(group)
    const size = box.getSize(new THREE.Vector3()).length()
    camera.position.set(size, size, size)
    controls.target.set(0, 0, 0)
    controls.update()
  } catch (err) {
    console.error('Error parsing STL data:', err)
  }
}

function onWindowResize() {
  if (!container.value || !camera || !renderer) return
  camera.aspect = container.value.clientWidth / container.value.clientHeight
  camera.updateProjectionMatrix()
  renderer.setSize(container.value.clientWidth, container.value.clientHeight)
}

function animate() {
  if (!renderer) return
  requestAnimationFrame(animate)
  if (controls) controls.update()
  renderer.render(scene, camera)
}

watch(() => props.stlData, () => {
  loadStl()
})

onMounted(() => {
  init()
})

onUnmounted(() => {
  if (renderer) {
    renderer.dispose()
  }
  window.removeEventListener('resize', onWindowResize)
})
</script>

<style scoped>
.stl-viewer {
  width: 100%;
  height: 400px;
  background-color: #f0f0f0;
  border-radius: 8px;
  overflow: hidden;
}
</style>
