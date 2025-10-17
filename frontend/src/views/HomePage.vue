<!-- frontend/src/views/HomePage.vue -->
<!--
  Главная страница с каталогом товаров.
  Отображает список товаров и фильтр по категориям.
-->

<template>
  <div class="min-h-screen bg-white">
    <div class="max-w-7xl mx-auto px-4 py-8">
      <!-- Заголовок -->
      <div class="mb-8">
        <h1 class="text-4xl font-extrabold text-black mb-2">Product Catalog</h1>
        <p class="text-gray-500">Discover our amazing products</p>
      </div>

      <div class="flex gap-8">
        <!-- Боковая панель с фильтром -->
        <aside class="w-64 flex-shrink-0">
          <CategoryFilter />
        </aside>

        <!-- Основное содержимое -->
        <main class="flex-grow">
          <!-- Информация о фильтрации -->
          <div class="mb-6 flex items-center justify-between">
            <p class="text-gray-700">
              <span class="font-bold">{{ productsStore.productsCount }}</span>
              {{ productsStore.productsCount === 1 ? 'product' : 'products' }} found
            </p>

            <!-- Кнопка сброса фильтра -->
            <button
              v-if="productsStore.selectedCategory"
              @click="productsStore.clearCategoryFilter"
              class="text-sm text-gray-500 hover:text-black transition-colors font-medium"
            >
              Clear filter
            </button>
          </div>

          <!-- Состояние загрузки -->
          <div v-if="productsStore.loading" class="text-center py-12">
            <div
              class="inline-block animate-spin rounded-none h-12 w-12 border-b-2 border-black"
            ></div>
            <p class="mt-4 text-gray-500">Loading products...</p>
          </div>

          <!-- Ошибка -->
          <div v-else-if="productsStore.error" class="text-center py-12">
            <p class="text-red-600 font-medium">{{ productsStore.error }}</p>
          </div>

          <!-- Список товаров -->
          <div
            v-else-if="productsStore.filteredProducts.length > 0"
            class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
          >
            <ProductCard
              v-for="product in productsStore.filteredProducts"
              :key="product.id"
              :product="product"
            />
          </div>

          <!-- Пустое состояние -->
          <div v-else class="text-center py-12">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-16 w-16 mx-auto text-gray-400 mb-4"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"
              />
            </svg>
            <p class="text-gray-500 text-lg font-medium">No products found</p>
            <button
              @click="productsStore.clearCategoryFilter"
              class="mt-4 text-black hover:underline font-medium"
            >
              View all products
            </button>
          </div>
        </main>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useProductsStore } from '@/stores/products'
import ProductCard from '@/components/ProductCard.vue'
import CategoryFilter from '@/components/CategoryFilter.vue'

const productsStore = useProductsStore()

/**
 * Загрузить данные при монтировании компонента
 */
onMounted(async () => {
  await Promise.all([productsStore.fetchProducts(), productsStore.fetchCategories()])
})
</script>
