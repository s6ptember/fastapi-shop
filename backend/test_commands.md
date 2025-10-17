# Руководство по тестированию API в Postman

## Содержание
1. [Подготовка](#подготовка)
2. [Настройка окружения](#настройка-окружения)
3. [Тестирование эндпоинтов](#тестирование-эндпоинтов)
4. [Автоматизированные тесты](#автоматизированные-тесты)

---

## Подготовка

### Запуск бэкенда

```bash
# Установка зависимостей
cd backend
pip install -r requirements.txt

# Заполнение базы данных тестовыми данными
python seed_data.py

# Запуск сервера
python run.py
```

Сервер будет доступен по адресу: `http://localhost:8000`

### Импорт коллекции в Postman

1. Откройте Postman
2. Нажмите **Import** → **Raw text**
3. Скопируйте JSON коллекцию из раздела ниже

---

## Настройка окружения

Создайте новое окружение (Environment) в Postman:

**Имя:** `FastAPI Shop Local`

**Переменные:**

| Variable | Initial Value | Current Value |
|----------|--------------|---------------|
| `base_url` | `http://localhost:8000` | `http://localhost:8000` |
| `product_id` | `1` | `1` |
| `category_id` | `1` | `1` |

---

## Тестирование эндпоинтов

### 1. Health Check

**Проверка работоспособности сервера**

```
GET {{base_url}}/health
```

**Ожидаемый ответ (200 OK):**
```json
{
  "status": "healthy"
}

```

**Tests для добавления:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Status is healthy", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.status).to.eql("healthy");
});
```

---

### 2. Категории (Categories)

#### 2.1. Получить все категории

```
GET {{base_url}}/api/categories
```

**Ожидаемый ответ (200 OK):**
```json
[
  {
    "name": "Electronics",
    "slug": "electronics",
    "id": 1
  },
  {
    "name": "Clothing",
    "slug": "clothing",
    "id": 2
  }
]
```

**Tests:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response is array", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.be.an('array');
});

pm.test("Categories have required fields", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData[0]).to.have.property('id');
    pm.expect(jsonData[0]).to.have.property('name');
    pm.expect(jsonData[0]).to.have.property('slug');
});

// Сохраняем ID первой категории для других запросов
if (pm.response.json().length > 0) {
    pm.environment.set("category_id", pm.response.json()[0].id);
}
```

#### 2.2. Получить категорию по ID

```
GET {{base_url}}/api/categories/{{category_id}}
```

**Ожидаемый ответ (200 OK):**
```json
{
  "name": "Electronics",
  "slug": "electronics",
  "id": 1
}
```

**Tests:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Category has correct structure", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('id');
    pm.expect(jsonData).to.have.property('name');
    pm.expect(jsonData).to.have.property('slug');
});
```

#### 2.3. Получить несуществующую категорию

```
GET {{base_url}}/api/categories/9999
```

**Ожидаемый ответ (404 Not Found):**
```json
{
  "detail": "Category with id 9999 not found"
}
```

**Tests:**
```javascript
pm.test("Status code is 404", function () {
    pm.response.to.have.status(404);
});

pm.test("Error message is correct", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.detail).to.include("not found");
});
```

---

### 3. Товары (Products)

#### 3.1. Получить все товары

```
GET {{base_url}}/api/products
```

**Ожидаемый ответ (200 OK):**
```json
{
  "products": [
    {
      "id": 1,
      "name": "Wireless Headphones",
      "description": "High-quality wireless headphones...",
      "price": 299.99,
      "category_id": 1,
      "image_url": "https://images.unsplash.com/...",
      "created_at": "2025-01-15T10:30:00",
      "category": {
        "name": "Electronics",
        "slug": "electronics",
        "id": 1
      }
    }
  ],
  "total": 13
}
```

**Tests:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has products and total", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('products');
    pm.expect(jsonData).to.have.property('total');
});

pm.test("Products is an array", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.products).to.be.an('array');
});

pm.test("Product has complete structure", function () {
    var jsonData = pm.response.json();
    if (jsonData.products.length > 0) {
        var product = jsonData.products[0];
        pm.expect(product).to.have.property('id');
        pm.expect(product).to.have.property('name');
        pm.expect(product).to.have.property('price');
        pm.expect(product).to.have.property('category');
        pm.expect(product.category).to.have.property('id');
        pm.expect(product.category).to.have.property('name');
    }
});

// Сохраняем ID первого товара
if (pm.response.json().products.length > 0) {
    pm.environment.set("product_id", pm.response.json().products[0].id);
}
```

#### 3.2. Получить товар по ID

```
GET {{base_url}}/api/products/{{product_id}}
```

**Tests:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Product has all required fields", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('id');
    pm.expect(jsonData).to.have.property('name');
    pm.expect(jsonData).to.have.property('price');
    pm.expect(jsonData).to.have.property('category_id');
    pm.expect(jsonData).to.have.property('category');
});

pm.test("Price is positive number", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.price).to.be.above(0);
});
```

#### 3.3. Получить товары по категории

```
GET {{base_url}}/api/products/category/{{category_id}}
```

**Tests:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("All products belong to specified category", function () {
    var jsonData = pm.response.json();
    var categoryId = parseInt(pm.environment.get("category_id"));

    jsonData.products.forEach(function(product) {
        pm.expect(product.category_id).to.eql(categoryId);
    });
});
```

#### 3.4. Получить товары несуществующей категории

```
GET {{base_url}}/api/products/category/9999
```

**Ожидаемый ответ (404 Not Found):**
```json
{
  "detail": "Category with id 9999 not found"
}
```

---

### 4. Корзина (Cart)

#### 4.1. Добавить товар в корзину

```
POST {{base_url}}/api/cart/add
Content-Type: application/json

{
  "product_id": 1,
  "quantity": 2,
  "cart": {}
}
```

**Ожидаемый ответ (200 OK):**
```json
{
  "cart": {
    "1": 2
  }
}
```

**Tests:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Cart contains added product", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.cart).to.have.property('1');
    pm.expect(jsonData.cart['1']).to.eql(2);
});

// Сохраняем корзину для следующих запросов
pm.environment.set("cart", JSON.stringify(pm.response.json().cart));
```

#### 4.2. Добавить ещё один товар

```
POST {{base_url}}/api/cart/add
Content-Type: application/json

{
  "product_id": 2,
  "quantity": 1,
  "cart": {{cart}}
}
```

**Pre-request Script:**
```javascript
// Загружаем корзину из переменной окружения
var cart = pm.environment.get("cart");
if (cart) {
    pm.variables.set("cart", cart);
} else {
    pm.variables.set("cart", "{}");
}
```

#### 4.3. Получить детали корзины

```
POST {{base_url}}/api/cart
Content-Type: application/json

{
  "1": 2,
  "2": 1
}
```

**Ожидаемый ответ (200 OK):**
```json
{
  "items": [
    {
      "product_id": 1,
      "name": "Wireless Headphones",
      "price": 299.99,
      "quantity": 2,
      "subtotal": 600.0,
      "image_url": "https://images.unsplash.com/..."
    },
    {
      "product_id": 2,
      "name": "Smart Watch Pro",
      "price": 399.99,
      "quantity": 1,
      "subtotal": 400.0,
      "image_url": "https://images.unsplash.com/..."
    }
  ],
  "total": 1000.0,
  "items_count": 3
}
```

**Tests:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Cart has all required fields", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('items');
    pm.expect(jsonData).to.have.property('total');
    pm.expect(jsonData).to.have.property('items_count');
});

pm.test("Items have correct structure", function () {
    var jsonData = pm.response.json();
    if (jsonData.items.length > 0) {
        var item = jsonData.items[0];
        pm.expect(item).to.have.property('product_id');
        pm.expect(item).to.have.property('name');
        pm.expect(item).to.have.property('price');
        pm.expect(item).to.have.property('quantity');
        pm.expect(item).to.have.property('subtotal');
    }
});

pm.test("Total is calculated correctly", function () {
    var jsonData = pm.response.json();
    var calculatedTotal = 0;

    jsonData.items.forEach(function(item) {
        calculatedTotal += item.subtotal;
    });

    pm.expect(jsonData.total).to.eql(calculatedTotal);
});

pm.test("Items count is correct", function () {
    var jsonData = pm.response.json();
    var totalQuantity = 0;

    jsonData.items.forEach(function(item) {
        totalQuantity += item.quantity;
    });

    pm.expect(jsonData.items_count).to.eql(totalQuantity);
});
```

#### 4.4. Обновить количество товара

```
PUT {{base_url}}/api/cart/update
Content-Type: application/json

{
  "product_id": 1,
  "quantity": 5,
  "cart": {
    "1": 2,
    "2": 1
  }
}
```

**Ожидаемый ответ (200 OK):**
```json
{
  "cart": {
    "1": 5,
    "2": 1
  }
}
```

**Tests:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Quantity was updated", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.cart['1']).to.eql(5);
});
```

#### 4.5. Удалить товар из корзины

```
DELETE {{base_url}}/api/cart/remove/1
Content-Type: application/json

{
  "cart": {
    "1": 5,
    "2": 1
  }
}
```

**Ожидаемый ответ (200 OK):**
```json
{
  "cart": {
    "2": 1
  }
}
```

**Tests:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Product was removed from cart", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.cart).to.not.have.property('1');
});
```

#### 4.6. Получить пустую корзину

```
POST {{base_url}}/api/cart
Content-Type: application/json

{}
```

**Ожидаемый ответ (200 OK):**
```json
{
  "items": [],
  "total": 0.0,
  "items_count": 0
}
```

#### 4.7. Добавить несуществующий товар

```
POST {{base_url}}/api/cart/add
Content-Type: application/json

{
  "product_id": 9999,
  "quantity": 1,
  "cart": {}
}
```

**Ожидаемый ответ (404 Not Found):**
```json
{
  "detail": "Product with id 9999 not found"
}
```

---

## Автоматизированные тесты

### Создание Test Suite

Вы можете создать последовательность тестов в Postman Collection Runner:

1. **Setup Tests** → Health Check
2. **Categories Tests** → Get All, Get by ID, Get Invalid
3. **Products Tests** → Get All, Get by ID, Get by Category
4. **Cart Tests** → Add, Update, Remove, Get Details

### Pre-request Script для всей коллекции

```javascript
// Устанавливаем базовые переменные, если их нет
if (!pm.environment.get("base_url")) {
    pm.environment.set("base_url", "http://localhost:8000");
}

// Добавляем timestamp для уникальных запросов
pm.variables.set("timestamp", Date.now());
```

### Tests для всей коллекции

```javascript
// Проверка времени ответа
pm.test("Response time is less than 500ms", function () {
    pm.expect(pm.response.responseTime).to.be.below(500);
});

// Проверка наличия Content-Type
pm.test("Content-Type is present", function () {
    pm.response.to.have.header("Content-Type");
});
```

---

## Коллекция Postman (JSON)

Сохраните этот JSON и импортируйте в Postman:

```json
{
  "info": {
    "name": "FastAPI Shop API",
    "description": "Коллекция для тестирования API интернет-магазина",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Health",
      "item": [
        {
          "name": "Health Check",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{base_url}}/health",
              "host": ["{{base_url}}"],
              "path": ["health"]
            }
          },
          "event": [
            {
              "listen": "test",
              "script": {
                "exec": [
                  "pm.test(\"Status code is 200\", function () {",
                  "    pm.response.to.have.status(200);",
                  "});",
                  "",
                  "pm.test(\"Status is healthy\", function () {",
                  "    var jsonData = pm.response.json();",
                  "    pm.expect(jsonData.status).to.eql(\"healthy\");",
                  "});"
                ]
              }
            }
          ]
        }
      ]
    },
    {
      "name": "Categories",
      "item": [
        {
          "name": "Get All Categories",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{base_url}}/api/categories",
              "host": ["{{base_url}}"],
              "path": ["api", "categories"]
            }
          },
          "event": [
            {
              "listen": "test",
              "script": {
                "exec": [
                  "pm.test(\"Status code is 200\", function () {",
                  "    pm.response.to.have.status(200);",
                  "});",
                  "",
                  "pm.test(\"Response is array\", function () {",
                  "    var jsonData = pm.response.json();",
                  "    pm.expect(jsonData).to.be.an('array');",
                  "});",
                  "",
                  "if (pm.response.json().length > 0) {",
                  "    pm.environment.set(\"category_id\", pm.response.json()[0].id);",
                  "}"
                ]
              }
            }
          ]
        },
        {
          "name": "Get Category by ID",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{base_url}}/api/categories/{{category_id}}",
              "host": ["{{base_url}}"],
              "path": ["api", "categories", "{{category_id}}"]
            }
          }
        },
        {
          "name": "Get Invalid Category",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{base_url}}/api/categories/9999",
              "host": ["{{base_url}}"],
              "path": ["api", "categories", "9999"]
            }
          },
          "event": [
            {
              "listen": "test",
              "script": {
                "exec": [
                  "pm.test(\"Status code is 404\", function () {",
                  "    pm.response.to.have.status(404);",
                  "});"
                ]
              }
            }
          ]
        }
      ]
    },
    {
      "name": "Products",
      "item": [
        {
          "name": "Get All Products",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{base_url}}/api/products",
              "host": ["{{base_url}}"],
              "path": ["api", "products"]
            }
          },
          "event": [
            {
              "listen": "test",
              "script": {
                "exec": [
                  "pm.test(\"Status code is 200\", function () {",
                  "    pm.response.to.have.status(200);",
                  "});",
                  "",
                  "if (pm.response.json().products.length > 0) {",
                  "    pm.environment.set(\"product_id\", pm.response.json().products[0].id);",
                  "}"
                ]
              }
            }
          ]
        },
        {
          "name": "Get Product by ID",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{base_url}}/api/products/{{product_id}}",
              "host": ["{{base_url}}"],
              "path": ["api", "products", "{{product_id}}"]
            }
          }
        },
        {
          "name": "Get Products by Category",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{base_url}}/api/products/category/{{category_id}}",
              "host": ["{{base_url}}"],
              "path": ["api", "products", "category", "{{category_id}}"]
            }
          }
        }
      ]
    },
    {
      "name": "Cart",
      "item": [
        {
          "name": "Add to Cart",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"product_id\": 1,\n  \"quantity\": 2,\n  \"cart\": {}\n}"
            },
            "url": {
              "raw": "{{base_url}}/api/cart/add",
              "host": ["{{base_url}}"],
              "path": ["api", "cart", "add"]
            }
          },
          "event": [
            {
              "listen": "test",
              "script": {
                "exec": [
                  "pm.test(\"Status code is 200\", function () {",
                  "    pm.response.to.have.status(200);",
                  "});",
                  "",
                  "pm.environment.set(\"cart\", JSON.stringify(pm.response.json().cart));"
                ]
              }
            }
          ]
        },
        {
          "name": "Get Cart Details",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"1\": 2,\n  \"2\": 1\n}"
            },
            "url": {
              "raw": "{{base_url}}/api/cart",
              "host": ["{{base_url}}"],
              "path": ["api", "cart"]
            }
          }
        },
        {
          "name": "Update Cart Item",
          "request": {
            "method": "PUT",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"product_id\": 1,\n  \"quantity\": 5,\n  \"cart\": {\n    \"1\": 2,\n    \"2\": 1\n  }\n}"
            },
            "url": {
              "raw": "{{base_url}}/api/cart/update",
              "host": ["{{base_url}}"],
              "path": ["api", "cart", "update"]
            }
          }
        },
        {
          "name": "Remove from Cart",
          "request": {
            "method": "DELETE",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"cart\": {\n    \"1\": 5,\n    \"2\": 1\n  }\n}"
            },
            "url": {
              "raw": "{{base_url}}/api/cart/remove/1",
              "host": ["{{base_url}}"],
              "path": ["api", "cart", "remove", "1"]
            }
          }
        },
        {
          "name": "Get Empty Cart",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{}"
            },
            "url": {
              "raw": "{{base_url}}/api/cart",
              "host": ["{{base_url}}"],
              "path": ["api", "cart"]
            }
          }
        }
      ]
    }
  ]
}
```

---

## Чек-лист тестирования

### ✅ Базовые проверки
- [ ] Сервер запускается без ошибок
- [ ] Health check возвращает статус "healthy"
- [ ] API доступен по адресу `http://localhost:8000`
- [ ] Документация доступна по `/api/docs`

### ✅ Категории
- [ ] Получение списка всех категорий
- [ ] Получение категории по существующему ID
- [ ] Ошибка 404 для несуществующего ID
- [ ] Все поля присутствуют в ответе

### ✅ Товары
- [ ] Получение списка всех товаров
- [ ] Получение товара по ID
- [ ] Фильтрация по категории
- [ ] Товар содержит информацию о категории
- [ ] Цены являются положительными числами
- [ ] Ошибка 404 для несуществующего товара

### ✅ Корзина
- [ ] Добавление товара в пустую корзину
- [ ] Добавление нескольких товаров
- [ ] Увеличение количества существующего товара
- [ ] Обновление количества товара
- [ ] Удаление товара из корзины
- [ ] Получение детальной информации о корзине
- [ ] Правильный расчет subtotal и total
- [ ] Правильный подсчет items_count
- [ ] Ошибка при добавлении несуществующего товара
- [ ] Ошибка при обновлении несуществующего товара в корзине

---

## Советы по тестированию

1. **Запускайте тесты последовательно** - используйте Collection Runner для автоматического выполнения всех тестов

2. **Используйте переменные окружения** - для переключения между dev/staging/production окружениями

3. **Сохраняйте результаты тестов** - Postman позволяет экспортировать результаты в JSON

4. **Проверяйте время ответа** - добавьте тесты на производительность

5. **Тестируйте граничные случаи**:
   - Пустые запросы
   - Отрицательные числа
   - Очень большие значения
   - Некорректные типы данных

6. **Используйте Pre-request Scripts** - для подготовки тестовых данных

7. **Автоматизируйте** - интегрируйте Postman тесты в CI/CD pipeline с помощью Newman

---

Готово! Теперь у вас есть полное руководство по тестированию вашего API в Postman. 🚀
