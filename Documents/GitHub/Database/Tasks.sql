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

WITH task_stats AS (
    SELECT 
        t.employee_id,
        COUNT(*) AS total_tasks,
        COUNT(CASE 
                  WHEN t.completed_at IS NOT NULL 
                  AND t.completed_at <= t.deadline
                  THEN 1
                  END) AS completed_on_time
    FROM 
        tasks t
    WHERE 
        t.created_at >= date_trunc('quarter', CURRENT_DATE) -- Filtron për tremujorin aktual
    GROUP BY 
        t.employee_id
)
SELECT 
    e.name,
    ts.total_tasks,
    ts.completed_on_time,
    ROUND((ts.completed_on_time::FLOAT / ts.total_tasks) * 100, 2) AS completion_percentage
FROM 
    task_stats ts
JOIN 
    employees e ON ts.employee_id = e.id
WHERE 
    (ts.completed_on_time::FLOAT / ts.total_tasks) >= 0.90
ORDER BY 
    completion_percentage DESC;

WITH task_counts AS (
    SELECT 
        e.department_id,
        t.priority,
        COUNT(*) AS task_count
    FROM 
        tasks t
    JOIN 
        employees e ON t.employee_id = e.id
    GROUP BY 
        e.department_id, t.priority
),
department_task_totals AS (
    SELECT 
        e.department_id,
        COUNT(*) AS total_tasks
    FROM 
        tasks t
    JOIN 
        employees e ON t.employee_id = e.id
    GROUP BY 
        e.department_id
)
SELECT 
    d.name AS department_name,
    tc.priority,
    ROUND((tc.task_count::FLOAT / dt.total_tasks) * 100, 2) AS percentage
FROM 
    task_counts tc
JOIN 
    department_task_totals dt ON tc.department_id = dt.department_id
JOIN 
    departments d ON dt.department_id = d.id
ORDER BY 
    department_name, 
    CASE tc.priority 
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
        ELSE 4
    END;

WITH pending_tasks AS (
    SELECT 
        t.employee_id,
        COUNT(*) AS pending_task_count
    FROM 
        tasks t
    WHERE 
        t.status = 'Pending'
        AND t.deadline >= CURRENT_DATE
        AND t.deadline < CURRENT_DATE + INTERVAL '1 month'
    GROUP BY 
        t.employee_id
),
total_employees AS (
    SELECT 
        COUNT(DISTINCT e.id) AS employee_count
    FROM 
        employees e
)
SELECT 
    pt.employee_id,
    pt.pending_task_count,
    ROUND(pt.pending_task_count::FLOAT / te.employee_count, 2) AS avg_tasks_per_employee
FROM 
    pending_tasks pt
JOIN 
    total_employees te ON true
ORDER BY 
    pt.pending_task_count DESC;


