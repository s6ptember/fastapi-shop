<!-- frontend/src/App.vue -->
<!--
  Корневой компонент приложения.
  Содержит общую структуру с Header и RouterView.
-->

<template>
  <div id="app" class="min-h-screen bg-gray-50">
    <!-- Шапка сайта -->
    <Header />

    <!-- Основной контент (роутер) -->
    <RouterView />

    <!-- Футер -->
    <footer class="bg-white border-t-2 border-black mt-16">
      <div class="max-w-7xl mx-auto px-4 py-8">
        <div class="text-center text-gray-600">
          <p class="mb-2">© 2024 FastAPI Shop. All rights reserved.</p>
          <p class="text-sm">Built with FastAPI + Vue.js</p>
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { RouterView } from 'vue-router'
import Header from '@/components/Header.vue'
import { useCartStore } from '@/stores/cart'

const cartStore = useCartStore()

/**
 * Инициализация приложения
 */
onMounted(() => {
  // Загрузить корзину из localStorage при запуске
  cartStore.initCart()
})
</script>

<style scoped>
/* Убираем все переопределения стилей для #app */
/* Tailwind классы полностью контролируют layout */
</style>
