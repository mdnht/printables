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
  const hemisphereLight = new THREE.HemisphereLight(0xffffff, 0x444444, 0.6)
  hemisphereLight.position.set(0, 200, 0)
  scene.add(hemisphereLight)

  const cameraLight = new THREE.DirectionalLight(0xffffff, 0.8)
  cameraLight.position.set(1, 1, 2)
  camera.add(cameraLight)
  scene.add(camera)

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

    // Check if geometry has color data
    const hasColors = geometry.hasAttribute('color')

    // Use MeshStandardMaterial for better lighting interaction
    const material = new THREE.MeshStandardMaterial({
      color: hasColors ? 0xffffff : 0xffcc00, // White if it has vertex colors, otherwise clear yellow/orange default
      roughness: 0.5,
      metalness: 0.1,
      vertexColors: hasColors
    })

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
