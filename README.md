# Project 4 Engeto Python and Data Analysis

# Research Questions:
1. **Do wages in all sectors increase over the years, or do they decrease in some?**
2. **How ​​many liters of milk and kilograms of bread can be purchased for the first and last comparable period in the available price and wage data?**
3. **Which food category is increasing in price the slowest (has the lowest percentage year-on-year increase)?**
4. **Is there a year in which the year-on-year increase in food prices was significantly higher than the increase in wages (greater than 10%)?**
5. **Does the level of GDP affect changes in wages and food prices? Or, if GDP increases more significantly in one year, will this be reflected in a more significant increase in food prices or wages in the same or the following year?**

## Data sources

### Primary sources
- **czechia_payroll** - Information on wages in various industries for the period 2006-2018
- **czechia_payroll_industry_branch** - Industry code list
- **czechia_price** - Information on prices of selected foods for the period 2006-2018
- **czechia_price_category** - Food category code list

### Secondary sources
- **economies** - GDP, GINI, tax burden for European countries
- **countries** - Geographic and demographic information about countries

## Output tables

### `t_adam_krejci_project_SQL_primary_final`
Primary table containing data on wages and food prices for the Czech Republic.

**Structure:**
- `year` - Year (2006-2018)
- `industry_branch_code` - Industry code
- `industry_branch_name` - Industry name
- `avg_wage` - Average wage in the industry (CZK)
- `category_code` - Food category code
- `category_name` - Food name
- `price_unit` - Unit (kg, l, pcs)
- `avg_price` - Average price of food (CZK)

### `t_adam_krejci_project_SQL_secondary_final`
Secondary table containing macroeconomic data for European countries.

**Structure:**
- `country` - Country name
- `year` - Year (2006-2018)
- `gdp` - GDP
- `gini` - GINI coefficient
- `population` - Population

## Summary of results

### Question 1: Wage development by sector
- **All sectors have a predominantly increasing trend**
- Only Těžba a dobývání has seen a decrease in wages for more than 2 years

### Question 2: Purchasing power - milk and bread
- **Purchasing power has increased in 12 years**
- Average wage grew faster than basic food prices
- In 2018, the average person could afford more milk and bread than in 2006

### Question 3: Slowest price increases
- **Categories with the lowest price growth identified**
- Some food prices are rising significantly slower than average
- Categories with decreasing prices are Rajská jablka červená kulatá and Cukr krystalový

### Question 4: Significant difference in prices vs. wages (>10%)
- **There are no years with a significant difference**
- The highest difference was the price growth outpacing the wage growth by 6.66 %

### Question 5: The impact of GDP
- **GDP has a moderate impact on wages and prices**
- **Correlation of GDP vs. Wages:** 0.429 (moderate positive correlation)
- **Correlation of GDP vs. Prices:** 0.487 (moderate positive correlation)
