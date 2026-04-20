# 🧹 SQL Data Cleaning Project

![MySQL](https://img.shields.io/badge/MySQL-Database-blue?logo=mysql)
![Data Cleaning](https://img.shields.io/badge/Task-Data%20Cleaning-success)
![Status](https://img.shields.io/badge/Status-Live-brightgreen)
![GitHub Repo Size](https://img.shields.io/github/repo-size/khushbirkaur/SQL-Data-Cleaning-Project)


## 📌 Project Overview

This project focuses on cleaning and transforming raw data using SQL. The dataset contains layoffs-related information, and the goal is to make it accurate, consistent, and ready for analysis.

---

## 🎯 Objectives

* Remove duplicate records
* Handle missing/null values
* Standardize inconsistent data formats
* Convert data types properly
* Prepare dataset for further analysis

---

## 🛠️ Tools & Technologies

* SQL (MySQL)
* Database Management System (DBMS)

---

## 📂 Dataset Description

The dataset includes information such as:

* Company name
* Industry
* Total layoffs
* Date
* Country
* Stage

📌 Note:  
- The original raw dataset (uncleaned) is also included in this repository.  
- It contains inconsistencies, null values, and duplicates.  
- The SQL script demonstrates how this raw data is cleaned step-by-step.

---

## ⚙️ Data Cleaning Steps

### 1. Removing Duplicates

* Identified duplicate rows using window functions
* Deleted redundant records

### 2. Standardizing Data

* Fixed inconsistent company names
* Cleaned industry and country fields
* Trimmed unwanted spaces

### 3. Handling Null Values

* Replaced or removed null values where necessary
* Ensured meaningful data consistency

### 4. Date Formatting

* Converted date column into proper SQL DATE format using `STR_TO_DATE()`

### 5. Data Transformation

* Structured dataset for better querying and analysis

---

## 📊 Key SQL Concepts Used

* `ROW_NUMBER()`
* `PARTITION BY`
* `CTE (Common Table Expressions)`
* `UPDATE` statements
* `CASE WHEN`
* `STR_TO_DATE()`
* Data filtering and transformation

---

## 📈 Outcome

* Clean and structured dataset
* Improved data quality
* Ready for analysis and visualization

---

## 👩‍💻 Author

**Khushbir Kaur Bamrah**
Artificial Intelligence & Data Science Student

