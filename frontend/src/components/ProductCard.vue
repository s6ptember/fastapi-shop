<!-- frontend/src/components/ProductCard.vue -->
<!--
  Компонент карточки товара для отображения в каталоге.
  Показывает основную информацию о товаре и кнопку добавления в корзину.
-->

<template>
  <div
    class="bg-white border-2 border-gray-200 rounded-lg overflow-hidden hover:border-black transition-all duration-300 hover:shadow-lg"
  >
    <!-- Изображение товара -->
    <router-link :to="`/product/${product.id}`">
      <div class="aspect-square overflow-hidden bg-gray-100">
        <img
          :src="product.image_url"
          :alt="product.name"
          class="w-full h-full object-cover hover:scale-105 transition-transform duration-300"
          @error="handleImageError"
        />
      </div>
    </router-link>

    <!-- Информация о товаре -->
    <div class="p-4">
      <!-- Категория -->
      <div class="text-xs text-gray-500 uppercase tracking-wide mb-2">
        {{ product.category.name }}
      </div>

      <!-- Название товара -->
      <router-link :to="`/product/${product.id}`">
        <h3 class="text-lg font-semibold text-black mb-2 hover:text-gray-700 transition-colors">
          {{ product.name }}
        </h3>
      </router-link>

      <!-- Цена -->
      <p class="text-2xl font-bold text-black mb-4">${{ product.price.toFixed(2) }}</p>

      <!-- Кнопка добавления в корзину -->
      <button
        @click="handleAddToCart"
        :disabled="adding"
        class="w-full bg-black text-white py-3 px-4 rounded-lg hover:bg-gray-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium"
      >
        {{ adding ? 'Adding...' : 'Add to Cart' }}
      </button>

      <!-- Уведомление об успешном добавлении -->
      <transition name="fade">
        <div v-if="showNotification" class="mt-2 text-sm text-green-600 text-center font-medium">
          ✓ Added to cart!
        </div>
      </transition>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useCartStore } from '@/stores/cart'

// Props
const props = defineProps({
  product: {
    type: Object,
    required: true,
  },
})

// State
const cartStore = useCartStore()
const adding = ref(false)
const showNotification = ref(false)

/**
 * Добавить товар в корзину
 */
async function handleAddToCart() {
  adding.value = true
  const success = await cartStore.addToCart(props.product.id, 1)

  if (success) {
    showNotification.value = true
    setTimeout(() => {
      showNotification.value = false
    }, 2000)
  }

  adding.value = false
}

/**
 * Обработка ошибки загрузки изображения
 */
function handleImageError(event) {
  event.target.src = 'https://via.placeholder.com/400x400?text=No+Image'
}
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
