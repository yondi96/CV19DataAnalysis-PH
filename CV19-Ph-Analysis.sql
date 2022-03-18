-- PHILIPPINES vaccination & deaths data
-- VACCINATION DATA
SELECT * FROM [CV19-Ph-Analysis]..['CVvaccinations$']
WHERE continent is not null AND location like '%lippin%'
ORDER BY 3, 4

-- EXPLORE TOTAL CASES, NEW CASES, AND TOTAL DEATHS
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE location like '%lippin%'
ORDER BY 1, 2

-- DEATH PERCENTAGE
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathPercentage
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE location like '%lippin%'
ORDER BY 1,2

-- INFECTED PERCENTAGE
SELECT location, date, total_cases, population, (total_cases/population)*100 AS infectedPercentage
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE location like '%lippin%'
ORDER BY 1, 2

-- WORLD: MOST INFECTED COUNTRIES - by percentage population
SELECT location, MAX(total_cases) as highestInfection, population, MAX((total_cases/population))*100 AS infectedPercentage
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE continent is not null
GROUP BY location, population
ORDER BY infectedPercentage DESC

-- WORLD: countries with most deaths
SELECT location, population, MAX(cast(total_deaths as int)) as maximumDeath, MAX((total_deaths/population))*100 as deathPercentage
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE continent is not null
GROUP BY location, population
ORDER BY maximumDeath DESC

-- PER CONTINENT: most deaths
SELECT continent, MAX(cast(total_deaths as int)) as maximumDeath, MAX((total_deaths/population))*100 as deathPercentage
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE continent is not null
GROUP BY continent
ORDER BY maximumDeath DESC


-- GLOBAL NUMBERS
SELECT date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathPercentage
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE continent is not null
--GROUP BY date
ORDER BY 1, 2


-- WORLD COUNT: Death & Death Percentage
SELECT SUM(new_cases) as globalCaseCount, SUM(cast(new_deaths as int)) as globalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as deathPercentage
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE continent is not null
ORDER BY 3 DESC


-- looking at existing vaccinations & percentage of vaccinated population
-- CTE
WITH PopVsVac (continent,location, date, population, new_vaccinations, rollingVaccinatedCount)
AS (

SELECT vac.continent, vac.location, vac.date, vac.population, dea.new_vaccinations
, SUM(CONVERT(bigint,dea.new_vaccinations)) OVER (PARTITION BY vac.location ORDER BY vac.location, vac.date) AS rollingVaccinatedCount
--, (rollingVaccinatedCount/dea.population)*100

FROM [CV19-Ph-Analysis]..['CVvaccinations$'] dea
JOIN [CV19-Ph-Analysis]..['CVdeaths$'] vac
	ON vac.location = dea.location
	AND vac.date = dea.date
WHERE dea.continent is not null --AND vac.new_vaccinations is not null
--ORDER BY 1, 2, 3
)
SELECT *, (rollingVaccinatedCount/population)*100 AS percentageVaccinated
FROM PopVsVac


-- CREATING TEMP TABLE
-- condition to prevent multiple tables
DROP TABLE IF EXISTS #VaccinatedPopulationPercent
CREATE TABLE #VaccinatedPopulationPercent
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rollingVaccinatedCount numeric
)

-- USING THE TEMP TABLE
INSERT INTO #VaccinatedPopulationPercent
SELECT vac.continent, vac.location, vac.date, vac.population, dea.new_vaccinations
, SUM(CONVERT(bigint,dea.new_vaccinations)) OVER (PARTITION BY vac.location ORDER BY vac.location, vac.date) AS rollingVaccinatedCount
--, (rollingVaccinatedCount/dea.population)*100

FROM [CV19-Ph-Analysis]..['CVdeaths$'] vac
JOIN [CV19-Ph-Analysis]..['CVvaccinations$'] dea
	ON vac.location = dea.location
	AND vac.date = dea.date
WHERE dea.continent is not null --AND vac.new_vaccinations is not null
--ORDER BY 1, 2, 3
SELECT *, (rollingVaccinatedCount/population)*100
FROM #VaccinatedPopulationPercent


-- CREATE VIEW: For visualization later
CREATE VIEW VaccinatedPopulationPercent AS 
SELECT vac.continent, vac.location, vac.date, vac.population, dea.new_vaccinations
, SUM(CONVERT(bigint,dea.new_vaccinations)) OVER (PARTITION BY vac.location ORDER BY vac.location, vac.date) AS rollingVaccinatedCount
--, (rollingVaccinatedCount/dea.population)*100

FROM [CV19-Ph-Analysis]..['CVdeaths$'] vac
JOIN [CV19-Ph-Analysis]..['CVvaccinations$'] dea
	ON vac.location = dea.location
	AND vac.date = dea.date
WHERE dea.continent is not null --AND vac.new_vaccinations is not null
--ORDER BY 1, 2, 3

SELECT *
FROM VaccinatedPopulationPercent