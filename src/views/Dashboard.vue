<template>
  <div class="dashboard">
    <!-- Header con glassmorphism -->
    <header class="topbar">
      <div class="brand">
        <span class="brand-icon">🎬</span>
        <h1>CineLog</h1>
      </div>
      <div class="user-menu">
        <div class="user-badge">
          <div class="avatar">{{ authStore.user?.charAt(0).toUpperCase() }}</div>
          <div class="user-details">
            <span class="user-name">{{ authStore.user }}</span>
            <span class="user-role">Usuario</span>
          </div>
        </div>
        <button @click="goToAdd" class="btn-primary">
          <span>✚</span> Agregar Película
        </button>
        <button @click="logout" class="btn-logout" title="Cerrar sesión">
          <span>⏻</span> Salir
        </button>
      </div>
    </header>

    <!-- Contenido principal -->
    <main class="content">
      <div class="section-header">
        <h2>📽️ Mi Colección</h2>
        <span class="badge">{{ movies.length }} títulos</span>
      </div>

      <!-- Loading skeleton -->
      <div v-if="loading" class="movies-grid">
        <div v-for="n in 6" :key="n" class="movie-card skeleton"></div>
      </div>

      <!-- Lista de películas -->
      <transition-group name="list" tag="div" v-else class="movies-grid">
        <div v-for="movie in movies" :key="movie.id" class="movie-card">
          <div class="movie-poster">
            <span class="poster-emoji">🎬</span>
          </div>
          <div class="movie-info">
            <h3>{{ movie.title }}</h3>
            <div class="movie-meta">
              <span class="meta-item year">📅 {{ movie.year }}</span>
              <span class="meta-item genre">🎭 {{ movie.genre }}</span>
            </div>
          </div>
          <div class="movie-number">#{{ movie.id }}</div>
        </div>
      </transition-group>

      <div v-if="!loading && movies.length === 0" class="empty-state">
        <span class="empty-icon">🎬</span>
        <h3>No hay películas todavía</h3>
        <p>Agrega tu primera película para empezar</p>
        <button @click="goToAdd" class="btn-primary">✚ Agregar Película</button>
      </div>

      <p v-if="error" class="error"> {{ error }}</p>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useAuthStore } from '../stores/auth';
import { useRouter } from 'vue-router';
import axios from 'axios';
import '../styles/dashboard.css';   // ← Importamos el CSS externo

const authStore = useAuthStore();
const router = useRouter();

const movies = ref([]);
const loading = ref(true);
const error = ref('');

const fetchMovies = async () => {
  try {
    console.log('📤 GET /api/movies con JWT:', authStore.token.substring(0, 50) + '...');
    const response = await axios.get('http://localhost:8001/api/movies', {
      headers: { Authorization: `Bearer ${authStore.token}` },
    });
    movies.value = response.data;
  } catch (err) {
    console.error('Error al obtener películas:', err);
    if (err.response?.status === 401) {
      authStore.logout();
      router.push('/login');
    } else {
      error.value = 'No se pudieron cargar las películas.';
    }
  } finally {
    loading.value = false;
  }
};

const goToAdd = () => router.push('/add');
const logout = () => {
  authStore.logout();
  router.push('/login');
};

onMounted(fetchMovies);
</script>