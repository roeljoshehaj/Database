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

DO $$ 
BEGIN 
    FOR i IN 1..200 LOOP
        INSERT INTO employees (name, department_id) 
        VALUES (
            'Employee ' || i, 
            FLOOR(RANDOM() * 5) + 1
        );
    END LOOP; 
END $$;

DO $$ 
BEGIN 
    FOR i IN 1..200 LOOP
        INSERT INTO tasks (employee_id, priority, deadline, status, created_at, completed_at) 
        VALUES (
            FLOOR(RANDOM() * 200) + 1,
            CASE 
                WHEN RANDOM() < 0.33 THEN 'High'
                WHEN RANDOM() < 0.66 THEN 'Medium'
                ELSE 'Low'
            END,
            CURRENT_DATE + (FLOOR(RANDOM() * 30) - 15),
            CASE 
                WHEN RANDOM() < 0.5 THEN 'Completed'
                ELSE 'In Progress'
            END,
            CURRENT_TIMESTAMP, 
            CASE 
                WHEN RANDOM() < 0.5 THEN CURRENT_TIMESTAMP + (FLOOR(RANDOM() * 100) + 1) * INTERVAL '1 hour' 
                ELSE NULL
            END
        );
    END LOOP; 
END $$;


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

ALTER TABLE tasks ADD COLUMN created_at TIMESTAMP;
ALTER TABLE tasks ADD COLUMN completed_at TIMESTAMP;
SELECT 
e.department_id,
AVG(EXTRACT(EPOCH FROM (t.completed_at - t.created_at)) / 3600) AS avg_completion_time_hours,
RANK() OVER (ORDER BY AVG(EXTRACT(EPOCH FROM (t.completed_at - t.created_at)) / 3600) ASC) AS department_rank
FROM 
tasks t
JOIN 
employees e ON t.employee_id = e.id
WHERE 
t.status = 'Completed'
GROUP BY 
e.department_id
ORDER BY 
avg_completion_time_hours ASC;

