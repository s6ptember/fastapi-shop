<!-- frontend/src/views/ProductDetailPage.vue -->
<!--
  Детальная страница товара.
  Отображает полную информацию о товаре с возможностью добавления в корзину.
-->

<template>
  <div class="min-h-screen bg-white">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <!-- Кнопка "Назад" -->
      <button
        @click="router.push('/')"
        class="flex items-center text-gray-600 hover:text-black transition-colors mb-8 font-medium text-lg"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-6 w-6 mr-2"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M15 19l-7-7 7-7"
          />
        </svg>
        Back to catalog
      </button>

      <!-- Состояние загрузки -->
      <div v-if="loading" class="text-center py-16">
        <div class="inline-block animate-spin rounded-full h-14 w-14 border-b-4 border-black"></div>
        <p class="mt-4 text-lg text-gray-500">Loading product...</p>
      </div>

      <!-- Ошибка -->
      <div v-else-if="error" class="text-center py-16">
        <p class="text-red-600 text-lg font-medium">{{ error }}</p>
        <button
          @click="router.push('/')"
          class="mt-6 bg-black text-white py-3 px-8 text-lg font-semibold rounded-none hover:bg-gray-900 transition-colors"
        >
          Return to catalog
        </button>
      </div>

      <!-- Детальная информация о товаре -->
      <div
        v-else-if="product"
        class="bg-white border-2 border-gray-100 rounded-none shadow-sm overflow-hidden"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8 p-8">
          <!-- Изображение -->
          <div class="aspect-square overflow-hidden rounded-none bg-gray-50">
            <img
              :src="product.image_url"
              :alt="product.name"
              class="w-full h-full object-cover"
              @error="handleImageError"
            />
          </div>

          <!-- Информация -->
          <div class="flex flex-col">
            <!-- Категория -->
            <div class="text-sm text-gray-500 uppercase tracking-wider mb-3 font-medium">
              {{ product.category.name }}
            </div>

            <!-- Название -->
            <h1 class="text-3xl sm:text-4xl font-extrabold text-black mb-4">
              {{ product.name }}
            </h1>

            <!-- Цена -->
            <div class="text-2xl sm:text-3xl font-bold text-black mb-6">
              ${{ product.price.toFixed(2) }}
            </div>

            <!-- Описание -->
            <div class="mb-8">
              <h2 class="text-xl font-bold text-black mb-3">Description</h2>
              <p class="text-gray-600 leading-relaxed">
                {{ product.description || 'No description available.' }}
              </p>
            </div>

            <!-- Кнопка добавления в корзину -->
            <div class="mt-auto">
              <button
                @click="handleAddToCart"
                :disabled="adding"
                class="w-full bg-black text-white py-4 px-6 text-lg font-semibold rounded-none hover:bg-gray-900 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {{ adding ? 'Adding to cart...' : 'Add to Cart' }}
              </button>

              <!-- Уведомление об успешном добавлении -->
              <transition name="fade">
                <div
                  v-if="showNotification"
                  class="mt-4 bg-black text-white px-4 py-3 rounded-none text-center font-medium"
                >
                  ✓ Product added to cart!
                </div>
              </transition>
            </div>

            <!-- Дополнительная информация -->
            <div class="mt-8 pt-6 border-t-2 border-gray-100">
              <p class="text-sm text-gray-500">Product ID: {{ product.id }}</p>
              <p class="text-sm text-gray-500">Added: {{ formatDate(product.created_at) }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useProductsStore } from '@/stores/products'
import { useCartStore } from '@/stores/cart'

const route = useRoute()
const router = useRouter()
const productsStore = useProductsStore()
const cartStore = useCartStore()

// State
const product = ref(null)
const loading = ref(false)
const error = ref(null)
const adding = ref(false)
const showNotification = ref(false)

/**
 * Загрузить данные товара
 */
async function loadProduct() {
  loading.value = true
  error.value = null

  try {
    const productId = parseInt(route.params.id)
    product.value = await productsStore.fetchProductById(productId)
  } catch (err) {
    error.value = 'Product not found'
    console.error('Error loading product:', err)
  } finally {
    loading.value = false
  }
}

/**
 * Добавить товар в корзину
 */
async function handleAddToCart() {
  adding.value = true
  const success = await cartStore.addToCart(product.value.id, 1)

  if (success) {
    showNotification.value = true
    setTimeout(() => {
      showNotification.value = false
    }, 3000)
  }

  adding.value = false
}

/**
 * Форматировать дату
 */
function formatDate(dateString) {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}

/**
 * Обработка ошибки загрузки изображения
 */
function handleImageError(event) {
  event.target.src = 'https://via.placeholder.com/600x600?text=No+Image'
}

// Загрузить товар при монтировании
onMounted(() => {
  loadProduct()
})
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
