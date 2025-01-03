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

WITH pending_tasks AS (
    SELECT 
        t.employee_id,
        COUNT(*) AS pending_task_count,
        COUNT(CASE 
                  WHEN t.priority = 'High' THEN 1
                  END) AS high_priority_count
    FROM 
        tasks t
    WHERE 
        t.status = 'Pending'
    GROUP BY 
        t.employee_id
),
employee_info AS (
    SELECT 
        e.id AS employee_id,
        e.name AS employee_name,
        d.name AS department_name
    FROM 
        employees e
    JOIN 
        departments d ON e.department_id = d.id
)
SELECT 
    ei.employee_name,
    ei.department_name,
    pt.pending_task_count,
    ROUND((pt.high_priority_count::FLOAT / pt.pending_task_count) * 100, 2) AS high_priority_percentage
FROM 
    pending_tasks pt
JOIN 
    employee_info ei ON pt.employee_id = ei.employee_id
ORDER BY 
    pt.pending_task_count DESC
LIMIT 3;

WITH employee_task_count AS (
    SELECT 
        t.employee_id,
        COUNT(*) AS task_count
    FROM 
        tasks t
    WHERE 
        t.status = 'Pending'
    GROUP BY 
        t.employee_id
),
eligible_employees AS (
    SELECT 
        e.id AS employee_id,
        e.name AS employee_name,
        e.department_id,
        et.task_count
    FROM 
        employees e
    LEFT JOIN 
        employee_task_count et ON e.id = et.employee_id
    WHERE 
        (et.task_count IS NULL OR et.task_count < 3)
),
available_tasks AS (
    SELECT 
        t.id AS task_id,
        t.description AS task_description,
        t.department_id AS task_department
    FROM 
        tasks t
    WHERE 
        t.status = 'Pending'
)
SELECT 
    ee.employee_name,
    at.task_description,
    d.name AS department_name
FROM 
    eligible_employees ee
JOIN 
    available_tasks at ON ee.department_id = at.task_department
JOIN 
    departments d ON at.task_department = d.id
ORDER BY 
    ee.employee_name;
    
    SELECT 
    d.name AS department_name,
    MAX(monthly_completion_rate) AS highest_completion_rate,
    MIN(monthly_completion_rate) AS lowest_completion_rate,
    (MAX(monthly_completion_rate) - MIN(monthly_completion_rate)) AS improvement_rate
FROM (
    SELECT 
        t.department_id,
        DATE_TRUNC('month', t.completion_date) AS month,
        COUNT(CASE WHEN t.status = 'Completed' THEN 1 END)::FLOAT / COUNT(*) AS monthly_completion_rate
    FROM 
        tasks t
    WHERE 
        t.completion_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        t.department_id, DATE_TRUNC('month', t.completion_date)
) AS department_monthly_rates
JOIN 
    departments d ON department_monthly_rates.department_id = d.id
GROUP BY 
    d.id, d.name
ORDER BY 
    improvement_rate DESC
LIMIT 1;

SELECT 
    d.name AS department_name,
    COUNT(t.id) AS total_tasks,
    COUNT(CASE WHEN t.status = 'Completed' THEN 1 END) AS completed_tasks,
    COUNT(CASE WHEN t.status = 'Pending' THEN 1 END) AS pending_tasks,
    COUNT(CASE WHEN t.status = 'Pending' AND t.deadline < CURRENT_DATE THEN 1 END) AS overdue_tasks
FROM 
    tasks t
JOIN 
    departments d ON t.department_id = d.id
GROUP BY 
    d.name
ORDER BY 
    d.name;

SELECT 
    e.name AS employee_name,
    d.name AS department_name,
    COUNT(t.id) AS employee_task_count
FROM 
    employees e
JOIN 
    tasks t ON e.id = t.employee_id
JOIN 
    departments d ON e.department_id = d.id
GROUP BY 
    e.id, e.name, d.name
HAVING 
  COUNT(t.id) < (SELECT AVG(task_count) 
  FROM (SELECT COUNT(*) AS task_count 
  FROM tasks 
GROUP BY employee_id) AS subquery)
ORDER BY 
    department_name, employee_name;
