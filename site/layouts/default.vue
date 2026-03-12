<template>
  <div>
    <header>
      <h1 lang="en">
        <NuxtLink to="/">3D Model Catalog</NuxtLink>
      </h1>
      <p>OpenSCAD プロジェクト一覧</p>
    </header>
    <main>
      <slot />
    </main>
    <footer lang="en">Auto-generated from project metadata.</footer>
  </div>
</template>

<style scoped>
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

header h1 a {
  color: white;
  text-decoration: none;
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

footer {
  text-align: center;
  color: #aaa;
  font-size: 0.8rem;
  padding: 2rem 1rem;
}
</style>
