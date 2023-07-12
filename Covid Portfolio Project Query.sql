Select *
From PortfolioProject..CovidDeath
Where continent is not null
order by 3, 4

--Select *
--From PortfolioProject..CovidVaccination
--order by 3, 4

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeath
Where Location Like '%India%'
and continent is not null
order by 1, 2

-- Looking at Total Cases and Total Deaths

Select location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
From PortfolioProject..CovidDeath
order by 1, 2

-- Looking at Total Cases and Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT
    location,
    date,
    total_cases,
    total_deaths,
    CASE
        WHEN TRY_CONVERT(decimal(18, 6), NULLIF(total_deaths, '')) IS NULL OR TRY_CONVERT(decimal(18, 6), NULLIF(total_cases, '')) IS NULL
            THEN NULL -- or a default value
        ELSE CONVERT(decimal(18, 6), NULLIF(total_deaths, '')) / CONVERT(decimal(18, 6), NULLIF(total_cases, ''))
    END AS DeathPercentage
FROM PortfolioProject..CovidDeath
WHERE location LIKE '%India%'
and continent is not null
ORDER BY 1, 2;

-- Looking at Total Cases vs Population, shows percentage of population got Covid

SELECT location, date, Population, total_cases, (total_cases/Population)*100 AS InfectedPopulationPercentage
FROM PortfolioProject..CovidDeath
--WHERE location LIKE '%India%'
ORDER BY 1, 2;


-- Looking at Countries with highest Infection Rate compared to Population

SELECT location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/Population))*100 AS InfectedPopulationPercentage
FROM PortfolioProject..CovidDeath
--WHERE location LIKE '%India%'
GROUP BY location, Population
ORDER BY InfectedPopulationPercentage DESC;



-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeath
--WHERE location LIKE '%India%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing Continents with the Highest death count per Population

SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeath
--WHERE location LIKE '%India%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- GLOBAL NUMBERS

SELECT
    --date,
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    CASE WHEN SUM(new_cases) = 0 THEN NULL
         ELSE SUM(CAST(new_deaths AS INT)) * 100.0 / NULLIF(SUM(new_cases), 0)
    END AS DeathPercentage
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2;


-- Now we are going to join Both CovidDeaths and CovidVaccination tables
-- Looking at Total Population vs Vaccinations

SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM
    PortfolioProject..CovidDeath dea
JOIN
    PortfolioProject..CovidVaccination vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
ORDER BY
    2, 3;


-- USE CTE

With PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM
    PortfolioProject..CovidDeath dea
JOIN
    PortfolioProject..CovidVaccination vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
--ORDER BY
--    2, 3
	)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopVsVac


-- TEMP TABLE

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM
    PortfolioProject..CovidDeath dea
JOIN
    PortfolioProject..CovidVaccination vac ON dea.location = vac.location AND dea.date = vac.date
--WHERE
--    dea.continent IS NOT NULL
--ORDER BY
--    2, 3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


-- Creating view to store data for later visualizations


Create View PercentPopulationVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM
    PortfolioProject..CovidDeath dea
JOIN
    PortfolioProject..CovidVaccination vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
--ORDER BY
--    2, 3

Select *
From PercentPopulationVaccinated