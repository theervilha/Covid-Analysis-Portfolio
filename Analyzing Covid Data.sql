-- Visualize raw data
SELECT  
	location, date, total_vaccinations, people_vaccinated, new_vaccinations
FROM 
	PortfolioProject..Worksheet$



-- Select the data we are going to use
-- Deaths
DROP TABLE IF EXISTS PortfolioProject..CovidDeaths$

SELECT 
	continent, location, date, total_cases, new_cases, total_deaths, population 
INTO
	PortfolioProject..CovidDeaths$
FROM 
	PortfolioProject..Worksheet$

ALTER TABLE PortfolioProject..CovidDeaths$ ALTER COLUMN total_deaths float NULL

SELECT TOP 100 * FROM PortfolioProject..CovidDeaths$ ORDER BY date DESC


-- Vaccinations
DROP TABLE IF EXISTS PortfolioProject..CovidVaccinations$ 

SELECT 
	continent, location, date, total_vaccinations, people_vaccinated, new_vaccinations, population
INTO
	PortfolioProject..CovidVaccinations$
FROM 
	PortfolioProject..Worksheet$
	
ALTER TABLE PortfolioProject..CovidVaccinations$ ALTER COLUMN total_vaccinations float NULL
ALTER TABLE PortfolioProject..CovidVaccinations$ ALTER COLUMN people_vaccinated float NULL
ALTER TABLE PortfolioProject..CovidVaccinations$ ALTER COLUMN new_vaccinations float NULL

SELECT TOP 100 * FROM PortfolioProject..CovidVaccinations$ ORDER BY date DESC



-- Looking at Percentage Deaths by Population for each COUNTRY
-- Which countries have the highest percentage of deaths in relation to the total population?
SELECT TOP 10
	location, population, max(total_deaths) as total_deaths, max(total_deaths)/max(population)*100 AS pct_deaths_by_population
FROM
	PortfolioProject..CovidDeaths$
WHERE
	continent IS NOT NULL -- get only countries
GROUP BY
	location, population
ORDER BY
	pct_deaths_by_population DESC



-- Percentage Deaths by Infecteds (total_deaths vs total_cases)
-- Of those who caught covid, how many died?
SELECT
	location, date, total_cases, new_cases, total_deaths, population, (total_deaths/total_cases)*100 AS pct_deaths_by_infected
FROM
	PortfolioProject..CovidDeaths$
ORDER BY
	location, date

-- grouped by COUNTRY
SELECT
	location, max(total_cases) as total_cases, max(total_deaths) as total_deaths, max(total_deaths)/max(total_cases)*100 AS pct_deaths_by_infected
FROM
	PortfolioProject..CovidDeaths$
WHERE
	continent IS NOT NULL -- get only countries
GROUP BY
	location
ORDER BY
	pct_deaths_by_infected DESC



-- Percentage Infected by Population
-- What percentage of population got covid?
SELECT
	location, date, total_cases, population, (total_cases/population)*100 AS pct_infected_by_population
FROM
	PortfolioProject..CovidDeaths$
ORDER BY
	location, date

-- Since the first case, which country had the highest percentage of infected population?
SELECT
	location, MAX(total_cases) as total_cases, MAX(population) as population, (MAX(total_cases)/MAX(population))*100 AS pct_population_infected
FROM
	PortfolioProject..CovidDeaths$
WHERE
	continent IS NOT NULL
GROUP BY
	location
ORDER BY
	pct_population_infected DESC

-- Percentage Infected by Population for each COUNTRY for each MONTH
SELECT
	location, YEAR(date) as year, MONTH(date) as month, MAX(total_cases) as total_cases, MAX(population) as population, (MAX(total_cases)/MAX(population))*100 AS pct_infected_by_population
FROM
	PortfolioProject..CovidDeaths$
WHERE
	continent IS NOT NULL
GROUP BY
	location, YEAR(date), MONTH(date)
ORDER BY
	location, YEAR(date), MONTH(date)



/* Table containing: 
- Number of Infected People
- % Pct Infected by Population
- Number of Deaths
- % Pct Deaths by Infected
- % Deaths by Population
*/
SELECT
	SUM(population) as total_population,
	SUM(total_infected) as total_infected,
	SUM(total_infected)/SUM(population)*100 as pct_infected_by_population,
	SUM(total_deaths) as total_deaths,
	SUM(total_deaths)/SUM(total_infected)*100 as pct_deaths_by_infected,
	SUM(total_deaths)/SUM(population)*100 as pct_deaths_by_population
FROM 
	(SELECT
		location, 
		MAX(total_cases) as total_infected,
		MAX(total_deaths) as total_deaths, 
		MAX(population) as population
	FROM
		PortfolioProject..CovidDeaths$
	WHERE
		continent IS NOT NULL -- get only countries
	GROUP BY
		location
	) AS max_numbers 



-- Creating Temp Table
DROP TABLE if exists #rolling_people_vaccinated
CREATE TABLE #rolling_people_vaccinated
(
	location nvarchar(255), 
	date datetime, 
	new_vaccinations numeric, 
	rolling_people_vaccinated numeric, 
	population numeric
)

INSERT INTO #rolling_people_vaccinated
	SELECT 
		location, date, new_vaccinations, 
		SUM(CONVERT(bigint, new_vaccinations)) OVER (Partition by location ORDER BY date) AS rolling_people_vaccinated, 
		population
	FROM 
		PortfolioProject..CovidVaccinations$
	WHERE
		continent IS NOT NULL

SELECT TOP 1000 * FROM #rolling_people_vaccinated



-- Creating View of percentage of people who received at least 1 dose
Drop view  if exists PercentPopulationVaccinated
GO
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	location, population, max(people_vaccinated) AS people_vaccinated, max(people_vaccinated)/max(population)*100 AS pct_vaccinated_people
FROM 
	PortfolioProject..CovidVaccinations$
WHERE
	continent IS NOT NULL
GROUP BY	
	location, population