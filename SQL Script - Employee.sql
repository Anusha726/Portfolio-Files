use employees;
show tables;

select * from employees;

-- Get the names of employees hired after 2000.
select * from employees where year(hire_date) >= 2000;

-- Find the total number of employees in the company.
select distinct count(emp_no) as Total_Employees from employees;

-- Show the distinct job titles/projects available in the company.
select distinct title from titles;

-- Count the number of employees in each department.
select de.dept_no, d.dept_name, count( distinct de.emp_no) as Total_Employees
from dept_emp de LEFT JOIN departments d ON de.dept_no = d.dept_no
group by de.dept_no;

-- Retrieve employees whose first name starts with 'A'.
select concat(first_name, ' ', last_name) as name from employees
where concat(first_name, ' ', last_name) like 'A%';

-- List the top 5 highest-paid employees.
select s.emp_no, concat(e.first_name, ' ', e.last_name) as emp_name, sum(s.salary) as total_salary
from salaries s JOIN employees e on s.emp_no = e.emp_no
group by s.emp_no, s.salary
order by sum(s.salary) desc
limit 5;

-- Find the average salary per department.
select d.dept_name, ROUND(avg(s.salary), 2) as average_salary
from  employees e
join dept_emp de on e.emp_no = de.emp_no
join departments d on de.dept_no = d.dept_no
join salaries s on e.emp_no = s.emp_no
group by d.dept_name
order by average_salary desc;

-- Get the highest, lowest, and average salary overall.
select max(salary) as highest_salary, min(salary) as lowest_salary, 
ROUND(avg(salary),0) as average_salary
from salaries;

-- Find the total number of employees hired per year.
select year(hire_date) as year, count(distinct emp_no) as total_employees 
from employees
group by year(hire_date)
order by year(hire_date) asc;

-- List each employee’s name along with their department name.
select concat(e.first_name, ' ', e.last_name) as emp_name, d.dept_name from employees e
LEFT JOIN dept_emp de on e.emp_no = de.emp_no
LEFT JOIN departments d on de.dept_no = d.dept_no;

-- Which department has the highest salary expense?
select d.dept_name, SUM(s.salary) as total_salary_expense
from departments d
join dept_emp de on d.dept_no = de.dept_no
join salaries s on de.emp_no = s.emp_no
group by d.dept_name
order by total_salary_expense desc
limit 1;

-- Show employee names along with their manager's name.
select concat(e.first_name, ' ', e.last_name) as employee_name,
       concat(m.first_name, ' ', m.last_name) as manager_name
from employees e
left join dept_emp de on e.emp_no = de.emp_no
left join dept_manager dm on de.dept_no = dm.dept_no
left join employees m on dm.emp_no = m.emp_no;

-- 2. Which manager has the most employees under them?
select concat(m.first_name, ' ', m.last_name) as manager_name,
       d.dept_name,
       count(de.emp_no) as num_employees
from dept_manager dm
join employees m on dm.emp_no = m.emp_no
join departments d on dm.dept_no = d.dept_no
join dept_emp de on dm.dept_no = de.dept_no
group by manager_name, d.dept_name
order by num_employees desc
limit 1;

-- Get the department name, manager name, and number of employees in each department.
select  d.dept_name, concat(m.first_name, ' ', m.last_name) as manager_name,
count( distinct de.emp_no) as num_employees
from departments d
join dept_manager dm on d.dept_no = dm.dept_no
join employees m on dm.emp_no = m.emp_no
join dept_emp de on d.dept_no = de.dept_no
group by d.dept_name, manager_name;

-- Find employees earning more than the average salary.
select emp_no, sum(salary) from salaries 
group by emp_no
having sum(salary) > (select round(avg(salary),0) from salaries);

-- Find departments with more employees than the average department size.
select d.dept_name, count(distinct e.emp_no) as num_employees
from departments d
join dept_emp de on d.dept_no = de.dept_no
join employees e on de.emp_no = e.emp_no
group by d.dept_name
having count(e.emp_no) > (select round(avg(dept_count), 0) from 
	    (select count(distinct e.emp_no) as dept_count
         from departments d
         join dept_emp de on d.dept_no = de.dept_no
         join employees e on de.emp_no = e.emp_no
         group by d.dept_name) as department_sizes
);

-- Rank employees by salary within each department
select d.dept_name, e.emp_no, concat(e.first_name, ' ', e.last_name) as emp_name, s.salary,
       rank() over(partition by d.dept_name order by s.salary desc) as salary_rank
from departments d
join dept_emp de on d.dept_no = de.dept_no
join employees e on de.emp_no = e.emp_no
join salaries s on e.emp_no = s.emp_no;

-- Find the cumulative salary expense by department
select d.dept_name, e.emp_no, concat(e.first_name, ' ', e.last_name) as emp_name, s.salary,
       sum(s.salary) over(partition by d.dept_name order by s.salary desc) as cummulative_salary_expense
from departments d
join dept_emp de on d.dept_no = de.dept_no
join employees e on de.emp_no = e.emp_no
join salaries s on e.emp_no = s.emp_no;

-- Get employees with salaries above the department average
with dept_avg_salary as(
    select d.dept_no, avg(s.salary) as avg_salary
    from departments d
    join dept_emp de on d.dept_no = de.dept_no
    join employees e on de.emp_no = e.emp_no
    join salaries s on e.emp_no = s.emp_no
    group by d.dept_no
)
select d.dept_name, e.emp_no, concat(e.first_name, ' ', e.last_name) as emp_name, s.salary
from departments d
join dept_emp de on d.dept_no = de.dept_no
join employees e on de.emp_no = e.emp_no
join salaries s on e.emp_no = s.emp_no
join dept_avg_salary das on d.dept_no = das.dept_no
where s.salary > das.avg_salary;

-- Find the difference in salary between each employee and the highest-paid employee in their department
select d.dept_name, e.emp_no, concat(e.first_name, ' ', e.last_name) as emp_name, s.salary,
       max(s.salary)  over(partition by d.dept_name) - s.salary as salary_difference
from departments d
join dept_emp de on d.dept_no = de.dept_no
join employees e on de.emp_no = e.emp_no
join salaries s on e.emp_no = s.emp_no;


-- Display a column showing “High”, “Medium”, or “Low” salary categories
select e.emp_no, concat(e.first_name, ' ', e.last_name) as emp_name, s.salary,
	case when s.salary > 80000 then 'High'
		 when s.salary > 50000 then 'Medium'
		 else 'Low'
		 end as salary_category
from employees e
join salaries s on e.emp_no = s.emp_no;

-- Show tenure buckets (e.g., <2 years, 2–5 years, 5+ years)
select e.emp_no, concat(e.first_name, ' ', e.last_name) as emp_name, e.hire_date,
       timestampdiff(year, e.hire_date, curdate()) as tenure_years,
       case 
           when timestampdiff(year, e.hire_date, curdate()) < 2 then '<2 years'
           when timestampdiff(year, e.hire_date, curdate()) between 2 and 5 then '2–5 years'
           else '5+ years'
           end as tenure_bucket
from employees e;