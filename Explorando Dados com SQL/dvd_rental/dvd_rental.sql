-- Resumo do Dataset DVD Rental (PostgreSQL)
-- Fonte dos dados: https://www.postgresqltutorial.com/postgresql-getting-started/postgresql-sample-database/
-- Documentação PostreSQL: https://www.postgresql.org/docs/current/

-- Operações básicas
-- Selecionar o nome, sobrenome e e-mail dos clientes
SELECT first_name, last_name, email FROM customer;

-- Selecionar os diferentes tipos de avaliações que os filmes podem apresentar
SELECT DISTINCT rating FROM film;

-- Selecionar o nome, sobrenome e e-mail de Lois Butler
SELECT first_name, last_name, email
FROM customer
WHERE first_name = 'Lois' AND last_name = 'Butler';

-- Selecionar a descrição do filme "Outlaw Hanky"
SELECT description
FROM film
WHERE title = 'Outlaw Hanky';

-- Manipulação de datas
-- Verificar os dias em que houveram pagamento no 1° trimestre
SELECT
  DISTINCT(CAST(EXTRACT(month FROM payment_date) AS INTEGER)) AS payment_month,
  TO_CHAR(payment_date, 'MONTH') AS payment_monthName,
  payment_date::date AS payment_date,
  TO_CHAR(payment_date, 'DD-mon-YYYY') AS formatted_date
FROM payment
WHERE EXTRACT(QUARTER FROM payment_date) = 1
ORDER BY payment_month;

-- Funções de agregação
-- Calcular valores agregados da tabela payment
SELECT
    SUM(amount) AS total_amount,
    AVG(amount) AS average_amount,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount
FROM payment;

-- Calcular custo percentual dos filmes
SELECT
    title,
    ROUND(rental_rate / replacement_cost, 2)*100 AS custo_percent
FROM film;

-- Manipulação de strings
-- Gerar nome completo e e-mail fictício
SELECT
    customer_id,
    first_name || ' ' || last_name as full_name,
    email,
    LOWER(LEFT(first_name, 1)) || '.' || LOWER(last_name) || '@example.com' AS new_email
FROM customer;

-- GROUP BY, HAVING, ORDER BY e LIMIT
-- Selecionar os 10 clientes com maior gasto total
SELECT customer_id, SUM(amount) AS total_spent
FROM payment
GROUP BY customer_id
ORDER BY total_spent DESC
LIMIT 10;

-- Verificar qual funcionário lida com a maioria dos pagamentos
SELECT staff_id, COUNT(*) AS payment_count
FROM payment
GROUP BY staff_id
ORDER BY payment_count DESC
LIMIT 1;

-- Verificar a média do custo de reposição para os filmes com avaliação 'G', 'PG' e 'R'
SELECT rating, ROUND(AVG(replacement_cost), 2) AS avg_replacement_cost
FROM film
WHERE rating IN ('G', 'PG', 'R')
GROUP BY rating;

-- Verificar os clientes que tiveram mais de 39 transações
SELECT customer_id, COUNT(*) AS transaction_count
FROM payment
GROUP BY customer_id
HAVING COUNT(*) > 39
ORDER BY COUNT(*) DESC;

-- Selecionar os clientes que gastaram mais de $100 com o funcionário id 2
SELECT customer_id, SUM(amount) AS total_spent
FROM payment
WHERE staff_id = 2
GROUP BY customer_id
HAVING SUM(amount) > 100
ORDER BY SUM(amount) DESC;

-- JOINs
-- LEFT JOIN: Selecionar os filmes que nunca foram alugados
SELECT distinct(f.title) AS film_title
FROM film AS f
LEFT JOIN inventory AS i ON f.film_id = i.film_id
LEFT JOIN rental AS r ON i.inventory_id = r.inventory_id
WHERE r.rental_date IS NULL
ORDER BY film_title;

-- RIGHT JOIN: Selecionar as 10 categorias que possuem mais filmes
SELECT c.name AS categoria, COUNT(fc.film_id) AS qtd_filmes
FROM category AS c
RIGHT JOIN film_category AS fc ON c.category_id = fc.category_id
GROUP BY categoria
ORDER BY qtd_filmes DESC
LIMIT 10;

-- FULL OUTER JOIN: Identificar atores que não atuaram em nenhum filme OU os filmes que não têm nenhum ator associado
SELECT
    a.first_name || ' ' || a.last_name AS actor_name,
    f.title AS film_title
FROM
    actor AS a
FULL JOIN
    film_actor AS fa ON a.actor_id = fa.actor_id
FULL JOIN
    film AS f ON fa.film_id = f.film_id
WHERE
    a.actor_id IS NULL OR f.film_id IS NULL;

-- INNER JOIN: Selecionar os e-mails dos clientes que moram na Califórnia
SELECT district, email FROM customer
INNER JOIN address ON customer.address_id = address.address_id
WHERE district = 'California';

-- Encontrar os filmes em que Lisa Monroe participou
SELECT first_name || ' ' || last_name AS name, title FROM actor
INNER JOIN film_actor ON actor.actor_id = film_actor.actor_id
INNER JOIN film ON film_actor.film_id = film.film_id
WHERE(first_name || ' ' || last_name) = 'Lisa Monroe';

-- Selecionar os consumidores que alugaram o mesmo filme mais de uma vez
-- Tabelas: customer, rental, inventory, film
SELECT c.first_name, c.last_name, f.title, COUNT(r.rental_id) AS num_alugueis
FROM customer AS c
INNER JOIN rental AS r ON c.customer_id = r.customer_id
INNER JOIN inventory AS i ON r.inventory_id = i.inventory_id
INNER JOIN film AS f ON i.film_id = f.film_id
GROUP BY c.customer_id, f.film_id
HAVING COUNT(r.rental_id) > 1
ORDER BY num_alugueis DESC;

-- Self-Join: Listar todos os pares de atores que atuaram juntos em pelo menos dois filmes diferentes
SELECT
    a1.first_name || ' ' || a1.last_name AS actor1_full_name,
    a2.first_name || ' ' || a2.last_name AS actor2_full_name,
    COUNT(DISTINCT fa1.film_id) AS filmes_em_comum
FROM
    film_actor AS fa1
INNER JOIN
    film_actor AS fa2 ON fa1.film_id = fa2.film_id
INNER JOIN
    actor AS a1 ON fa1.actor_id = a1.actor_id
INNER JOIN
    actor AS a2 ON fa2.actor_id = a2.actor_id
WHERE
    fa1.actor_id < fa2.actor_id
GROUP BY
    a1.actor_id, a2.actor_id, a1.first_name, a1.last_name, a2.first_name, a2.last_name
HAVING
    COUNT(DISTINCT fa1.film_id) > 1;

-- Condicionais
-- CASE: Categorização de Duração de Filmes
SELECT title, length,
CASE
        WHEN length <= 60 THEN 'curta'
ELSE 'longa'
END AS categoria
FROM film;

-- Adicionar bônus por Classificação de Filme
SELECT title, rating, rental_rate,
CASE
    WHEN rating IN ('G', 'PG') THEN ROUND(rental_rate * 0.10, 2)
    WHEN rating = 'PG-13' THEN ROUND(rental_rate * 0.15, 2)
    WHEN rating IN ('R', 'NC-17') THEN ROUND(rental_rate * 0.20, 2)
ELSE  0.00
END AS bonus
FROM film;

-- COALESCE: Selecionar consumidores e seus respectivos e-mails e substituir os e-mails nulls por 'indisponivel'
SELECT
    first_name || ' ' || last_name AS full_name,
    COALESCE(email, 'indisponivel') AS email_contato
FROM
    customer;

-- NULLIF: Substituir observações que possuem como valor espaço(s) em branco por null
SELECT
    first_name || ' ' || last_name AS full_name,
    NULLIF(TRIM(email), '') AS email_limpo
FROM
    customer;

-- SubQuery
-- Selecionar os consumidores que gastaram mais de $100 na loja
SELECT customer_id, first_name || ' ' || last_name AS full_name, email
FROM customer
WHERE customer_id IN (
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    HAVING SUM(amount) > 100
);

-- Selecionar o nome completo e e-mail dos consumidores que gastaram acima da média da loja,
-- utilizando tabela temporária para mostrar também o valor gasto por cada consumidor
WITH CustomerSpending AS (
        SELECT customer_id, SUM(amount) as total_spent
        FROM payment
        GROUP BY customer_id
        HAVING SUM(amount) > (SELECT AVG(amount) FROM payment)
)
SELECT first_name || ' ' || last_name AS full_name, email, total_spent
FROM customer
INNER JOIN CustomerSpending on customer.customer_id = CustomerSpending.customer_id
ORDER BY total_spent DESC;

-- VIEW
-- View que foi criada no Supabase (banco de dados Postgre)
CREATE OR REPLACE VIEW filmes_detalhes_view AS
SELECT
    f.film_id,
    f.title AS film_title,
    f.description AS film_description,
    f.release_year,
    l.name AS film_language,
    f.length AS film_length_minutes,
    f.replacement_cost AS film_replacement_cost_usd,
    f.rating AS film_rating_mpaa,
    ca.name AS film_category_name
FROM
    film AS f
INNER JOIN
    language AS l ON f.language_id = l.language_id
INNER JOIN
    film_category AS fc ON f.film_id = fc.film_id
INNER JOIN
    category AS ca ON fc.category_id = ca.category_id;

-- Consultar view
SELECT * FROM filmes_detalhes_view LIMIT 5; 