// frontend/src/stores/cart.js
/**
 * Pinia store для управления корзиной покупок.
 * Хранит состояние корзины в localStorage и синхронизирует с backend.
 * Следует принципу Single Responsibility - отвечает только за логику корзины.
 */

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { cartAPI } from '@/services/api'

const CART_STORAGE_KEY = 'shopping_cart'

export const useCartStore = defineStore('cart', () => {
  // State - храним корзину как объект {product_id: quantity}
  const cartItems = ref({})
  const cartDetails = ref(null)
  const loading = ref(false)

  // Getters
  const itemsCount = computed(() => {
    return Object.values(cartItems.value).reduce((sum, qty) => sum + qty, 0)
  })

  const totalPrice = computed(() => {
    return cartDetails.value?.total || 0
  })

  const hasItems = computed(() => {
    return Object.keys(cartItems.value).length > 0
  })

  // Actions
  /**
   * Инициализировать корзину из localStorage
   */
  function initCart() {
    const savedCart = localStorage.getItem(CART_STORAGE_KEY)
    if (savedCart) {
      try {
        cartItems.value = JSON.parse(savedCart)
      } catch (e) {
        console.error('Error parsing cart from localStorage:', e)
        cartItems.value = {}
      }
    }
  }

  /**
   * Сохранить корзину в localStorage
   */
  function saveCart() {
    localStorage.setItem(CART_STORAGE_KEY, JSON.stringify(cartItems.value))
  }

  /**
   * Добавить товар в корзину
   */
  async function addToCart(productId, quantity = 1) {
    try {
      const item = {
        product_id: productId,
        quantity: quantity,
      }
      const response = await cartAPI.addItem(item, cartItems.value)
      cartItems.value = response.data.cart
      saveCart()
      await fetchCartDetails()
      return true
    } catch (err) {
      console.error('Error adding to cart:', err)
      return false
    }
  }

  /**
   * Получить детальную информацию о корзине
   */
  async function fetchCartDetails() {
    if (!hasItems.value) {
      cartDetails.value = { items: [], total: 0, items_count: 0 }
      return
    }

    loading.value = true
    try {
      const response = await cartAPI.getCart(cartItems.value)
      cartDetails.value = response.data
    } catch (err) {
      console.error('Error fetching cart details:', err)
    } finally {
      loading.value = false
    }
  }

  /**
   * Обновить количество товара
   */
  async function updateQuantity(productId, quantity) {
    if (quantity <= 0) {
      return removeFromCart(productId)
    }

    try {
      const item = {
        product_id: productId,
        quantity: quantity,
      }
      const response = await cartAPI.updateItem(item, cartItems.value)
      cartItems.value = response.data.cart
      saveCart()
      await fetchCartDetails()
      return true
    } catch (err) {
      console.error('Error updating cart:', err)
      return false
    }
  }

  /**
   * Удалить товар из корзины
   */
  async function removeFromCart(productId) {
    try {
      const response = await cartAPI.removeItem(productId, cartItems.value)
      cartItems.value = response.data.cart
      saveCart()
      await fetchCartDetails()
      return true
    } catch (err) {
      console.error('Error removing from cart:', err)
      return false
    }
  }

  /**
   * Очистить корзину
   */
  function clearCart() {
    cartItems.value = {}
    cartDetails.value = null
    localStorage.removeItem(CART_STORAGE_KEY)
  }

  return {
    // State
    cartItems,
    cartDetails,
    loading,
    // Getters
    itemsCount,
    totalPrice,
    hasItems,
    // Actions
    initCart,
    addToCart,
    fetchCartDetails,
    updateQuantity,
    removeFromCart,
    clearCart,
  }
})
