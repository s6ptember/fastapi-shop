// frontend/src/services/api.js
/**
 * API сервис для взаимодействия с backend.
 * Централизует все HTTP запросы к FastAPI серверу.
 * Использует axios для выполнения запросов.
 */

import axios from 'axios'

// Базовый URL API из переменных окружения или значение по умолчанию
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api'

// Создаем экземпляр axios с настройками по умолчанию
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

/**
 * API методы для работы с товарами
 */
export const productsAPI = {
  /**
   * Получить все товары
   */
  getAll() {
    return apiClient.get('/products')
  },

  /**
   * Получить товар по ID
   */
  getById(id) {
    return apiClient.get(`/products/${id}`)
  },

  /**
   * Получить товары по категории
   */
  getByCategory(categoryId) {
    return apiClient.get(`/products/category/${categoryId}`)
  },
}

/**
 * API методы для работы с категориями
 */
export const categoriesAPI = {
  /**
   * Получить все категории
   */
  getAll() {
    return apiClient.get('/categories')
  },

  /**
   * Получить категорию по ID
   */
  getById(id) {
    return apiClient.get(`/categories/${id}`)
  },
}

/**
 * API методы для работы с корзиной
 */
export const cartAPI = {
  /**
   * Добавить товар в корзину
   */
  addItem(item, cartData) {
    return apiClient.post('/cart/add', {
      product_id: item.product_id,
      quantity: item.quantity,
      cart: cartData,
    })
  },

  /**
   * Получить содержимое корзины
   */
  getCart(cartData) {
    return apiClient.post('/cart', cartData)
  },

  /**
   * Обновить количество товара
   */
  updateItem(item, cartData) {
    return apiClient.put('/cart/update', {
      product_id: item.product_id,
      quantity: item.quantity,
      cart: cartData,
    })
  },

  /**
   * Удалить товар из корзины
   */
  removeItem(productId, cartData) {
    return apiClient.delete(`/cart/remove/${productId}`, {
      data: {
        cart: cartData,
      },
    })
  },
}

export default apiClient
