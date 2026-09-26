<template>
  <div class="add-page">
    <!-- Header -->
    <header class="topbar">
      <button @click="$router.push('/dashboard')" class="btn-back">
        Volver
      </button>
      <div class="brand">
        <span class="brand-icon">🎬</span>
        <span>CineLog</span>
      </div>
      <div class="spacer"></div>
    </header>

    <div class="container">
      <div class="form-card">
        <div class="form-header">
          <h1>Agregar Nueva Película</h1>
          <p>Completa los datos para añadir a tu colección</p>
        </div>

        <form @submit.prevent="saveMovie" class="form">
          <div class="field">
            <label>🎬 Título</label>
            <input
              v-model="title"
              type="text"
              placeholder="Ej. Pulp Fiction"
              autofocus
            />
          </div>

          <div class="field-row">
            <div class="field">
              <label>📅 Año</label>
              <input
                v-model.number="year"
                type="number"
                placeholder="1994"
                min="1900"
                max="2100"
              />
            </div>

            <div class="field">
              <label>🎭 Género</label>
              <input
                v-model="genre"
                type="text"
                placeholder="Drama"
                list="genres"
              />
              <datalist id="genres">
                <option value="Acción" />
                <option value="Aventura" />
                <option value="Comedia" />
                <option value="Drama" />
                <option value="Sci-Fi" />
                <option value="Terror" />
                <option value="Romance" />
                <option value="Suspenso" />
                <option value="Animación" />
              </datalist>
            </div>
          </div>

          <div class="buttons">
            <button type="submit" :disabled="loading" class="btn-save">
              <span v-if="!loading">Guardar Película</span>
              <span v-else> Guardando...</span>
            </button>
            <button type="button" @click="$router.push('/dashboard')" class="btn-cancel">
            Cancelar
            </button>
          </div>

          <transition name="fade">
            <p v-if="error" class="error"> {{ error }}</p>
          </transition>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useAuthStore } from '../stores/auth';
import { useRouter } from 'vue-router';
import axios from 'axios';
import '../styles/addMovie.css';   // ← Importamos el CSS externo

const title = ref('');
const year = ref('');
const genre = ref('');
const error = ref('');
const loading = ref(false);

const authStore = useAuthStore();
const router = useRouter();

const saveMovie = async () => {
  error.value = '';

  if (!title.value || !year.value || !genre.value) {
    error.value = 'Todos los campos son obligatorios.';
    return;
  }

  loading.value = true;

  try {
    const newMovie = {
      title: title.value,
      year: year.value,
      genre: genre.value,
    };

    console.log('📤 POST /api/movies con JWT:', authStore.token.substring(0, 50) + '...');

    await axios.post('http://localhost:8001/api/movies', newMovie, {
      headers: { Authorization: `Bearer ${authStore.token}` },
    });

    router.push('/dashboard');
  } catch (err) {
    console.error('Error al guardar:', err);
    if (err.response?.status === 401) {
      authStore.logout();
      router.push('/login');
    } else {
      error.value = 'Error al guardar la película.';
    }
  } finally {
    loading.value = false;
  }
};
</script>