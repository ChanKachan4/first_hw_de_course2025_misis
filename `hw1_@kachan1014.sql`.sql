/*### Задача 1. Средняя стоимость заказа по категориям товаров
Вывести среднюю cуммарную стоимость товаров в заказе для каждой категории товаров, учитывая только заказы, созданные в марте 2023 года. */

select categories.name as category_name, sum(price) / count(distinct orders.id)  as avg_order_amount  from categories
inner join products
on products.category_id = categories.id
inner join orders_items
on orders_items.product_id = products.id
inner join orders
on orders.id = orders_items.order_id
inner join payments p 
on p.order_id = orders.id
where '2023-04' > to_char(orders.created_at, 'YYYY-MM') and to_char(orders.created_at, 'YYYY-MM') > '2023-02'
group by category_name;

/*### Задача 2. Рейтинг пользователей по сумме оплаченных заказов {10 баллов}
Вывести топ-3 пользователей, которые потратили больше всего денег на оплаченные заказы. Учитывать только заказы со статусом "Оплачен".
В отдельном столбце указать, какое место пользователь занимает*/

select distinct users.name as user_name, SUM(amount) as total_spent, RANK() over(order by sum(amount) desc) as user_rank
from users
inner join orders
on orders.user_id = users.id
inner join payments
on payments.order_id = orders.id
where orders.status = 'Оплачен'
group by users.id
order by total_spent desc
limit 3 offset 0

/*### Задача 3. Количество заказов и сумма платежей по месяцам {10 баллов}
Вывести количество заказов и общую сумму платежей по каждому месяцу в 2023 году.*/

select distinct to_char(orders.created_at, 'YYYY-MM') as month,
COUNT(*) over(partition by date_trunc('month', orders.created_at )) as total_orders,
SUM(amount) over(partition by date_trunc('month', orders.created_at )) as total_payments
from orders
inner join payments
on payments.order_id = orders.id
order by to_char(orders.created_at, 'YYYY-MM')

/*### Задача 4. Рейтинг товаров по количеству продаж {10 баллов}
Вывести топ-5 товаров по количеству продаж, а также их долю в общем количестве продаж. 
Долю округлить до двух знаков после запятой*/

select products.name as product_name,
sum(orders_items.quantity ) as total_orders,
ROUND((SUM(orders_items.quantity) * 100.0 / SUM(SUM(orders_items.quantity)) OVER ()), 2) AS sales_percentage
from products
inner join orders_items
on products.id = orders_items.product_id
group by products.name
order by total_orders desc
limit 5 offset 0


/*### Задача 5. Пользователи, которые сделали заказы на сумму выше среднего {10 баллов}
Вывести пользователей, общая сумма оплаченных заказов которых превышает 
среднюю сумму оплаченных заказов по всем пользователям.*/
select users.name as user_name, sum(p.amount) as total_spent from users
inner join orders o
on o.user_id = users.id
inner join payments p 
on p.order_id = o.id
where o.status = 'Оплачен'
group by users.name
having (sum(p.amount) > ((select sum(amount) from payments inner join orders on orders.id = payments.order_id where orders.status = 'Оплачен') / (select count(distinct orders.user_id) from orders where orders.status = 'Оплачен' )))
order by total_spent desc


/*### Задача 6. Рейтинг товаров по количеству продаж в каждой категории
Для каждой категории товаров вывести топ-3 товара по количеству проданных единиц. 
Используйте оконную функцию для ранжирования товаров внутри каждой категории.*/

with ranked_products as (
    select 
        c.name as category_name,
        p.name as product_name,
        SUM(oi.quantity) as total_quantity,
        RANK() over (partition by c.name order by SUM(oi.quantity) desc) as rank
    from categories c
    inner join products p on p.category_id = c.id
    inner join orders_items oi on oi.product_id = p.id
    group by c.name, p.name
)
select category_name, product_name, total_quantity
from ranked_products
where rank <= 3
order by category_name, rank;


/*### Задача 7. Категории товаров с максимальной выручкой в каждом месяце
Вывести категории товаров, которые принесли максимальную выручку 
в каждом месяце первого полугодия 2023 года.*/

select distinct on (month) to_char(orders.created_at, 'YYYY-MM') as month,
c.name as category_name,
sum(p.price * quantity) as total_revenue from orders
inner join orders_items oi on oi.order_id = orders.id
inner join products p on oi.product_id = p.id
inner join categories c on p.category_id = c.id
inner join payments p2 on p2.order_id = orders.id
WHERE DATE_PART('year', orders.created_at) = 2023 and  DATE_PART('month', orders.created_at) <= 06
group by category_name, month
order by month, total_revenue desc


/*### Задача 8. Накопительная сумма платежей по месяцам
Вывести накопительную сумму платежей по каждому месяцу в 2023 году. 
Накопительная сумма должна рассчитываться нарастающим итогом. Подсказка: нужно понять, как работает ROWS BETWEEN,
и какое ограничение используется по умолчанию для SUM BY*/

select to_char(p.payment_date, 'YYYY-MM') as month,
sum(p.amount) as monthly_payments,
sum(sum(p.amount)) over ( order by to_char(p.payment_date, 'YYYY-MM') rows between unbounded preceding and current row
) as cumulative_payments
from payments p
inner join orders o on p.order_id = o.id
where p.payment_date is not null
group by to_char(p.payment_date, 'YYYY-MM')
order by month;




