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

// Constants for scene setup and materials
const SCENE_BG_COLOR = 0xf0f0f0
const CAMERA_FOV = 45
const CAMERA_NEAR = 1
const CAMERA_FAR = 1000
const CAMERA_INITIAL_POS = new THREE.Vector3(200, 200, 200)

const CONTROLS_DAMPING_FACTOR = 0.25

const HEMI_LIGHT_SKY_COLOR = 0xffffff
const HEMI_LIGHT_GROUND_COLOR = 0x444444
const HEMI_LIGHT_INTENSITY = 0.6
const HEMI_LIGHT_POS = new THREE.Vector3(0, 200, 0)

const DIR_LIGHT_COLOR = 0xffffff
const DIR_LIGHT_INTENSITY = 0.8
const DIR_LIGHT_POS = new THREE.Vector3(1, 1, 2)

const MATERIAL_DEFAULT_COLOR = 0xffcc00
const MATERIAL_VERTEX_COLOR = 0xffffff
const MATERIAL_ROUGHNESS = 0.5
const MATERIAL_METALNESS = 0.1

const container = ref(null)
let scene, camera, renderer, controls, mesh

function init() {
  if (!container.value) return

  // Basic Three.js setup
  scene = new THREE.Scene()
  scene.background = new THREE.Color(SCENE_BG_COLOR)

  camera = new THREE.PerspectiveCamera(CAMERA_FOV, container.value.clientWidth / container.value.clientHeight, CAMERA_NEAR, CAMERA_FAR)
  camera.position.copy(CAMERA_INITIAL_POS)

  renderer = new THREE.WebGLRenderer({ antialias: true })
  renderer.setSize(container.value.clientWidth, container.value.clientHeight)
  container.value.appendChild(renderer.domElement)

  controls = new OrbitControls(camera, renderer.domElement)
  controls.enableDamping = true
  controls.dampingFactor = CONTROLS_DAMPING_FACTOR

  // Lights
  const hemisphereLight = new THREE.HemisphereLight(HEMI_LIGHT_SKY_COLOR, HEMI_LIGHT_GROUND_COLOR, HEMI_LIGHT_INTENSITY)
  hemisphereLight.position.copy(HEMI_LIGHT_POS)
  scene.add(hemisphereLight)

  const cameraLight = new THREE.DirectionalLight(DIR_LIGHT_COLOR, DIR_LIGHT_INTENSITY)
  cameraLight.position.copy(DIR_LIGHT_POS)
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
      color: hasColors ? MATERIAL_VERTEX_COLOR : MATERIAL_DEFAULT_COLOR, // White if it has vertex colors, otherwise clear yellow/orange default
      roughness: MATERIAL_ROUGHNESS,
      metalness: MATERIAL_METALNESS,
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
