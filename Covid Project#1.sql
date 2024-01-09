SELECT *
FROM 
	PortfolioProject..CovidDeaths
ORDER BY 
	3,4

SELECT *
FROM 
	PortfolioProject..CovidVaccinations
--WHERE location LIKE '%...%'
ORDER BY 
	3,4

-- select data that we are going to be using
SELECT
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM
	PortfolioProject..CovidDeaths
--WHERE location LIKE '%...%'
ORDER BY
	1,2

-- looking at total cases vs total deaths

-- Alter the data types of the columns
ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN total_cases bigint

ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN total_deaths bigint

-- Select specific columns and calculate the death rate percentage
SELECT
    location,
    date,
    total_cases,
    total_deaths,
    (total_deaths * 100.0 / total_cases) AS death_rate_percentage
FROM
    PortfolioProject..CovidDeaths
--WHERE location LIKE '%...%'
ORDER BY
    1,2

-- Looking at total cases vs population

-- Alter the data types of the columns
ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN population bigint

-- Select specific columns and calculate the death rate percentage
SELECT
    location,
    date,
    population,
    total_cases,
    (total_cases * 100.0 / population) AS Percentage_Population_Infected
FROM
    PortfolioProject..CovidDeaths
--WHERE location LIKE '%...%'
ORDER BY
    1,2

-- Looking at countries with highest infection rate compared to population
SELECT
    location,
    population,
    MAX(total_cases) AS Highest_Infection_Count,
    MAX((total_cases * 100.0 / population)) AS Percentage_Population_Infected
FROM
    PortfolioProject..CovidDeaths
--WHERE location LIKE '%...%'
GROUP BY
    location,
    population
ORDER BY
	Percentage_Population_Infected DESC

--showing countries with highest death count per population
SELECT
    location,
    MAX(total_deaths) AS Total_deaths_Count
FROM
    PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY
    location
ORDER BY
	Total_deaths_Count DESC

-- Looking at countries with highest death rate compared to population
SELECT
    location,
    population,
    MAX(total_deaths) AS Total_deaths_Count,
    MAX((total_deaths * 100.0 / population)) AS Percentage_Of_Deaths
FROM
    PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY
    location,
    population
ORDER BY
	Total_deaths_Count DESC,
	Percentage_Of_Deaths DESC

--Another way
SELECT
    location,
    MAX(total_deaths) AS Total_deaths_Count,
    MAX((total_deaths * 100.0 / population)) AS Percentage_Of_Deaths
FROM
    PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY
    location
ORDER BY
	Total_deaths_Count DESC,
	Percentage_Of_Deaths DESC

-- Let's break things down by continents Showing contintnents with the highest death count per population
SELECT
    continent,
    MAX(total_deaths) AS Total_deaths_Count,
    MAX((total_deaths * 100.0 / population)) AS Percentage_Of_Deaths
FROM
    PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY
    continent
ORDER BY
	Total_deaths_Count DESC,
	Percentage_Of_Deaths DESC

-- Global Numbers
SELECT
    total_cases,
    total_deaths,
    (total_deaths * 100.0 / total_cases) AS death_rate_percentage
FROM
    PortfolioProject..CovidDeaths
WHERE total_cases IS NOT NULL
ORDER BY
    1 DESC

--And
SELECT
    SUM(total_cases) AS total_cases,
    SUM(total_deaths) AS total_deaths,
    (SUM(total_deaths) * 100.0 / SUM(total_cases)) AS global_death_rate_percentage
FROM
    PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY
    1,2

-- Global Numbers for new cases
SELECT
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS int)) AS total_deaths,
    (SUM(CAST(new_deaths AS int)) * 100.0 / SUM(new_cases)) AS new_global_death_rate_percentage
FROM
    PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY
    1,2

SELECT
    SUM(total_cases),
    SUM(total_deaths),
    (SUM(total_deaths) * 100.0 / SUM(total_cases)) AS global_death_rate_percentage
FROM
    PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY
    1,2


-- looking at total population vs vaccinations with CTS called(popVSvac)
SELECT *
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations))
	OVER (PARTITION BY dea.location
	ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

WITH popVSvac
(
continent,
location,
date,
population,
new_vaccinations,
RollingPeopleVaccinated)
AS
(
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations))
	OVER (PARTITION BY dea.location
	ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated * 100.0 / population)
FROM popVSvac

--TEMP TABLE
--DROP TABLE IF EXISTS #PopulationVaccinatedPercent
CREATE TABLE #PopulationVaccinatedPercent
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PopulationVaccinatedPercent
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations))
	OVER (PARTITION BY dea.location
	ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated * 100.0 / population)
FROM #PopulationVaccinatedPercent

--Creating view to store data for later visualizations
CREATE VIEW PopulationVaccinatedPercent AS
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations))
	OVER (PARTITION BY dea.location
	ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PopulationVaccinatedPercent
--DROP VIEW PercentPopulationVaccinated