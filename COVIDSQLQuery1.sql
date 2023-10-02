
--  View all the data from the COVID19 database
SELECT TOP (10) *
  FROM PortfolioProjectCOVID19_V1.dbo.worldcovid;


--  View the data from the COVID19 database where continent is mentioned (i.e data for countries)
Select TOP (10) * 
From PortfolioProjectCOVID19_V1.dbo.worldcovid
Where continent is not null 
order by location,date;


--  View the data from the COVID19 database where continent and pupulation are mentioned (to help for calculation)
Select * 
From PortfolioProjectCOVID19_V1.dbo.world_demo as demo
Where population is not null AND continent is not null
order by location


--  View the total population by conutry ordered  for most pupulated to least populated
SELECT iso_code, location, MAX(population) AS total_population
FROM PortfolioProjectCOVID19_V1.dbo.world_demo AS demo
WHERE population IS NOT NULL AND continent IS NOT NULL
GROUP BY location, iso_code
--ORDER BY location,
ORDER BY total_population DESC;




-- Add the total_population column to your COVID-19 data table if it doesn't exist
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'PortfolioProjectCOVID19_V1.dbo.worldcovid' AND COLUMN_NAME = 'total_population')
BEGIN
    ALTER TABLE PortfolioProjectCOVID19_V1.dbo.worldcovid
    ADD total_population INT;
END



-- Start of the MERGE statement
-- Create a CTE to get the iso_code and total_population from the dbo.world_demo table
WITH CountryPopulations AS (
    SELECT iso_code, MAX(population) AS total_population
    FROM PortfolioProjectCOVID19_V1.dbo.world_demo
    WHERE population IS NOT NULL AND continent IS NOT NULL
    GROUP BY iso_code
)

-- Merge the total_population into the COVID-19 data table
MERGE INTO PortfolioProjectCOVID19_V1.dbo.worldcovid AS target
USING CountryPopulations AS source
ON target.iso_code = source.iso_code

-- When matched, update the total_population column
WHEN MATCHED THEN
    UPDATE SET target.total_population = source.total_population

-- End of the MERGE statement
;

-- Rename the total_population column to population
EXEC sp_rename 'dbo.worldcovid.total_population', 'population', 'COLUMN';




-------------------------------------------------------------------------
-------------------------------------------------------------------------

-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProjectCOVID19_V1.dbo.worldcovid
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid for a given country
Select Location, date, CONVERT(INT,total_cases) as total_cases ,CONVERT(INT,total_deaths) as total_deaths, 
(CONVERT(float,total_deaths)/CONVERT(float,total_cases))*100 as DeathPercentage
From PortfolioProjectCOVID19_V1.dbo.worldcovid
Where location like '%camer%' --'%united states%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid for a given country
Select Location, date, Population, CONVERT(float,total_cases) as total_cases,  
(CONVERT(float,total_cases)/population)*100 as PercentPopulationInfected
From PortfolioProjectCOVID19_V1.dbo.worldcovid
Where location like '%camer%' --'%united states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(CONVERT(float,total_cases)) as HighestInfectionCount,  
Max((CONVERT(float,total_cases)/population))*100 as PercentPopulationInfected
From PortfolioProjectCOVID19_V1.dbo.worldcovid
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProjectCOVID19_V1.dbo.worldcovid
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc




----------------------------------------------------------------------------
----------------------------------------------------------------------------

Select TOP (10) * 
From PortfolioProjectCOVID19_V1.dbo.worldcovid
Where continent is not null 
order by location,date

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProjectCOVID19_V1.dbo.worldcovid
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProjectCOVID19_V1.dbo.worldcovid
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2


----------------------------------------------------------------------------
----------------------------------------------------------------------------

Select *--TOP (10) * 
From PortfolioProjectCOVID19_V1.dbo.worldcovid
Where continent is not null 
order by location,date;



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

--Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
----, (RollingPeopleVaccinated/population)*100
--From PortfolioProjectCOVID19_V1.dbo.worldcovid dea
--Join dbo.worldcovid_vac vac
--	On dea.location = vac.location
--	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3


SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) 
	OVER (PARTITION BY dea.Location ORDER BY dea.Date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RollingPeopleVaccinated
    --, (RollingPeopleVaccinated / population) * 100
FROM
    PortfolioProjectCOVID19_V1.dbo.worldcovid dea
JOIN PortfolioProjectCOVID19_V1.dbo.worldcovid_vac vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
ORDER BY
    dea.location,
    dea.date;




-- Using CTE to perform Calculation on Partition By in previous query
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT,vac.new_vaccinations)) 
OVER (Partition by dea.Location Order by dea.Date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProjectCOVID19_V1.dbo.worldcovid dea
Join PortfolioProjectCOVID19_V1.dbo.worldcovid_vac vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT,vac.new_vaccinations)) 
OVER (Partition by dea.Location Order by dea.Date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProjectCOVID19_V1.dbo.worldcovid dea
Join PortfolioProjectCOVID19_V1.dbo.worldcovid_vac vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT,vac.new_vaccinations)) 
OVER (Partition by dea.Location Order by dea.Date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProjectCOVID19_V1.dbo.worldcovid dea
Join PortfolioProjectCOVID19_V1.dbo.worldcovid_vac vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 