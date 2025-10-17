// frontend/src/router/index.js
/**
 * Конфигурация Vue Router.
 * Определяет маршруты приложения и связывает их с компонентами.
 */

import { createRouter, createWebHistory } from 'vue-router'
import HomePage from '@/views/HomePage.vue'
import ProductDetailPage from '@/views/ProductDetailPage.vue'
import CartPage from '@/views/CartPage.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomePage,
      meta: {
        title: 'Shop - Home',
      },
    },
    {
      path: '/product/:id',
      name: 'product-detail',
      component: ProductDetailPage,
      meta: {
        title: 'Product Details',
      },
    },
    {
      path: '/cart',
      name: 'cart',
      component: CartPage,
      meta: {
        title: 'Shopping Cart',
      },
    },
  ],
  // Прокрутка страницы вверх при переходе между роутами
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    } else {
      return { top: 0 }
    }
  },
})

// Обновление заголовка страницы при навигации
router.beforeEach((to, from, next) => {
  document.title = to.meta.title || 'FastAPI Shop'
  next()
})

export default router
