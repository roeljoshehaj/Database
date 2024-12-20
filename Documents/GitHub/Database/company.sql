CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(25),
    location VARCHAR(25)
);
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(25),
    department INTEGER,
    salary DECIMAL(10, 2),
    hire_date DATE,
    FOREIGN KEY (department) REFERENCES departments(id)
);

INSERT INTO departments (name, location) VALUES
('HR', 'Boston'),
('Shitjet', 'Chicago'),
('IT', 'Turin'),
('Financa', 'Birmungham'),
('Marketingu', 'London');

INSERT INTO employees (name, department, salary, hire_date) VALUES
('Person1', 1, 20000, '2004-07-10'),
('Person2', 2, 60000, '2012-03-15'),
('Person3', 3, 40000, '2016-05-20'),
('Person4', 4, 8000, '2020-08-01'),
('Person5', 5, 5500, '2024-02-10'),
('Person6', 2, 6200, '2020-10-05'),
('Person7', 3, 7500, '2021-07-01'),
('Person8', 4, 7200, '2021-01-15'),
('Person9', 1, 4800, '2023-04-20'),
('Person10', 5, 5800, '2022-09-01');

SELECT * FROM departments;
SELECT * FROM employees;

SELECT name, department FROM employees;

SELECT e.name
FROM employees e 
JOIN departments d ON e.department = d.id
WHERE d.name = 'Financa';


SELECT name, salary 
FROM employees
ORDER BY salary DESC;

SELECT name 
FROM employees
WHERE name LIKE 'R%';

SELECT d.name AS departmentName, COUNT(e.id) AS employees
FROM employees e
JOIN departments d ON e.department = d.id
GROUP BY d.name;

SELECT AVG(salary) AS averageSalary
FROM employees;

SELECT 
MAX(salary) AS highestSalary,
MIN(salary) AS lowestSalary
FROM employees;

SELECT COUNT(id) AS employees_hired_last_year
FROM employees
WHERE hire_date >= CURRENT_DATE - INTERVAL '1 year';

SELECT e.name AS employee_name, 
e.salary, 
d.name AS department_name
FROM employees e
INNER JOIN departments d ON e.department = d.id;

SELECT
e.name AS employee_name, 
d.name AS department_name
FROM employees e
JOIN departments d ON e.department = d.id;

SELECT
d.name AS department_name, 
e.name AS employee_name
FROM departments d
LEFT JOIN employees e ON d.id = e.department;

SELECT d.name AS department_name,
SUM(e.salary) AS total_salary
FROM departments d
JOIN employees e ON d.id = e.department
GROUP BY d.name;

SELECT name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

SELECT *
FROM employees
WHERE salary > (
SELECT PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY salary) 
FROM employees
);

SELECT d.id, d.name, d.location
FROM departments d
JOIN (
SELECT department
FROM employees
GROUP BY department
HAVING COUNT(*) > 3
) e ON d.id = e.department;

SELECT e.id, e.name, e.salary, e.department
FROM employees e
WHERE e.salary > (
SELECT AVG(e2.salary)
FROM employees e2
WHERE e2.department = e.department
);

UPDATE employees
SET salary = salary * 1.10
WHERE department = (
SELECT id
FROM departments
WHERE name = 'Shitjet'
);

DELETE FROM employees
WHERE hire_date < CURRENT_DATE - INTERVAL '10 years';

ALTER TABLE employees
ADD COLUMN bonus DECIMAL(10, 2) DEFAULT 0;

UPDATE employees
SET bonus = salary * 0.5;

