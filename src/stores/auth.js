import { defineStore } from 'pinia';
import axios from 'axios';

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: localStorage.getItem('jwt_token') || null,
    user: localStorage.getItem('jwt_user') || null,
  }),
  getters: {
    isAuthenticated: (state) => !!state.token,
  },
  actions: {
    async login(username, password) {
      try {
        const params = new URLSearchParams();
        params.append('grant_type', 'password');
        params.append('client_id', 'fastapi-api');
        params.append('username', username);
        params.append('password', password);
        params.append('scope', 'openid');

        const response = await axios.post(
          'http://localhost:8081/realms/cybersecurity/protocol/openid-connect/token',
          params,
          { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
        );

        this.token = response.data.access_token;
        localStorage.setItem('jwt_token', this.token);

        const payload = JSON.parse(atob(this.token.split('.')[1]));
        this.user = payload.preferred_username;
        localStorage.setItem('jwt_user', this.user);

        return true;
      } catch (error) {
        console.error('Login fallido:', error);
        return false;
      }
    },
    logout() {
      this.token = null;
      this.user = null;
      localStorage.removeItem('jwt_token');
      localStorage.removeItem('jwt_user');
    },
  },
});