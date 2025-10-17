<!-- frontend/src/components/CategoryFilter.vue -->
<!--
  Компонент фильтрации товаров по категориям.
  Отображает список категорий с возможностью выбора для фильтрации.
-->

<template>
  <div class="bg-white border-2 border-gray-200 rounded-lg p-6">
    <h2 class="text-2xl font-bold text-black mb-6">Categories</h2>

    <!-- Список категорий -->
    <ul class="space-y-2">
      <!-- Все категории -->
      <li>
        <button
          @click="selectCategory(null)"
          :class="[
            'w-full text-left px-4 py-3 rounded-lg transition-all duration-200',
            !productsStore.selectedCategory
              ? 'bg-black text-white font-semibold'
              : 'bg-gray-50 hover:bg-gray-100 text-gray-700',
          ]"
        >
          All Categories
          <span v-if="!productsStore.selectedCategory" class="float-right">
            ({{ totalProductsCount }})
          </span>
        </button>
      </li>

      <!-- Отдельные категории -->
      <li v-for="category in productsStore.categories" :key="category.id">
        <button
          @click="selectCategory(category.id)"
          :class="[
            'w-full text-left px-4 py-3 rounded-lg transition-all duration-200',
            productsStore.selectedCategory === category.id
              ? 'bg-black text-white font-semibold'
              : 'bg-gray-50 hover:bg-gray-100 text-gray-700',
          ]"
        >
          {{ category.name }}
          <span v-if="productsStore.selectedCategory === category.id" class="float-right">
            ({{ productsStore.productsCount }})
          </span>
        </button>
      </li>
    </ul>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useProductsStore } from '@/stores/products'

const productsStore = useProductsStore()

/**
 * Общее количество товаров (без фильтра)
 */
const totalProductsCount = computed(() => {
  return productsStore.products.length
})

/**
 * Выбрать категорию для фильтрации
 */
function selectCategory(categoryId) {
  if (categoryId === null) {
    productsStore.clearCategoryFilter()
  } else {
    productsStore.setCategory(categoryId)
  }
}
</script>
