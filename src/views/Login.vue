<template>
  <div class="login-container">
    <div class="bg-animation">
      <div v-for="n in 20" :key="n" class="star" :style="starStyle(n)"></div>
    </div>

    <div class="login-box">
      <div class="logo">
        <span class="film-icon">🎬</span>
      </div>
      <h1>Movies Dashboard</h1>
      <p class="subtitle">Inicia sesión con tu usuario</p>

      <div class="input-group">
        <label>Usuario</label>
        <input
          v-model="username"
          type="text"
          placeholder="usuario"
          @keyup.enter="handleLogin"
        />
      </div>

      <div class="input-group">
        <label>Contraseña</label>
        <input
          v-model="password"
          type="password"
          placeholder="••••••••"
          @keyup.enter="handleLogin"
        />
      </div>

      <button @click="handleLogin" :disabled="loading" class="btn-login">
        <span v-if="!loading">Iniciar Sesión</span>
        <span v-else class="loading-spinner">Ingresando...</span>
      </button>

      <transition name="fade">
        <p v-if="error" class="error">
          <span></span> {{ error }}
        </p>
      </transition>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useAuthStore } from '../stores/auth';
import { useRouter } from 'vue-router';
import '../styles/login.css';   // ← Importamos el CSS externo

const username = ref('');
const password = ref('');
const error = ref('');
const loading = ref(false);

const authStore = useAuthStore();
const router = useRouter();

const starStyle = (n) => ({
  left: `${(n * 37) % 100}%`,
  top: `${(n * 53) % 100}%`,
  animationDelay: `${n * 0.2}s`,
  animationDuration: `${3 + (n % 4)}s`,
});

const handleLogin = async () => {
  error.value = '';
  loading.value = true;

  const success = await authStore.login(username.value, password.value);

  loading.value = false;

  if (success) {
    console.log('✅ Login exitoso. JWT:', authStore.token.substring(0, 50) + '...');
    router.push('/dashboard');
  } else {
    error.value = 'Credenciales inválidas. Verifica tu usuario y contraseña.';
  }
};
</script>