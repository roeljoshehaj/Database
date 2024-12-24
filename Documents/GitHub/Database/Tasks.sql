CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    department_id INT
);

CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(id),
    priority VARCHAR(50),
    deadline DATE,
    status VARCHAR(50)
);

SELECT 
    t.id AS task_id,
    t.priority,
    t.deadline,
    t.status,
    e.name AS employee_name
FROM 
tasks t
JOIN 
employees e ON t.employee_id = e.id
WHERE 
t.deadline < CURRENT_DATE
AND t.status != 'Completed';
