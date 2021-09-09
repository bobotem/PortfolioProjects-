-- select everything from covidDeaths table 
select * 
from dbo.CovidDeaths
where continent is not null -- removes columns where continent is null
order by 3,4

--select * 
--from dbo.CovidVaccinations
--order by 3,4

select location, date, total_cases, new_cases, total_deaths, population
from dbo.CovidDeaths
where continent is not null
order by 1,2 --(1&2 here is location and date)

-- Looking at the Total Cases vs Total Deaths
-- Likelihood of dying if one contract covid in their country
select location, date, total_cases,total_deaths, (total_deaths/ total_cases)*100 as DeathPercentage
from dbo.CovidDeaths
where location like '%States%' -- meaning where location is USA
where continent is not null
order by 1,2

-- Looking at the Total cases vs Population 
-- Shows what percentage of population got covid
select location, date, total_cases, population, (total_cases / population) * 100 as GotCovid
from dbo.CovidDeaths
--where location like '%States%'
where continent is not null
order by 1,2

-- Looking at countries with highest infection rate compared to Population
select location,MAX(total_cases) as HighestInfectionCount, population, MAX((total_cases / population)) * 100 as PercentPopulationInfected
from dbo.CovidDeaths
--where location like '%States%'
where continent is not null
group by location, population
order by PercentPopulationInfected desc 


-- Showing countries with highest death count per population
select location,MAX(cast(total_deaths as int)) as TotalDeathCount -- cast total_deaths as int so its read as numeric
from dbo.CovidDeaths
--where location like '%States%'
where continent is not null
group by location
order by TotalDeathCount desc 

-- BREAKING THINGS DOWN BY CONTINENT 
-- This query shows the continents with the highest total death counts
select continent,MAX(cast(total_deaths as int)) as TotalDeathCount -- cast total_deaths as int so its read as numeric
from dbo.CovidDeaths
--where location like '%States%'
where continent is not null
group by continent
order by TotalDeathCount desc


--CGLOBAL NUMBERS
-- getting the death percentage per day across the globe
select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int)) / SUM(new_cases) * 100 as DeathPercentage
from dbo.CovidDeaths
where continent is not null
--Group by date 
order by 1,2 


-- joining the covid deaths and covid vaccination tables
-- Total Population vs Vaccinations (we lookx at total amt of ppl in the world who got vaccinated)

-- USE CTE. The number of columns in the CTE needs to mathc the columns in the subquery. 
With PopvsVac (Continent, Location, Date, Population,New_Vaccinations, RollingPoepleVaccinated) 
as
(
select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, 
dea.date) as RollingPeopleVaccinated -- partition by means breaking it up by location. 
--Because we want the count to start over every time it reaches a new location
--, (RollingPeopleVaccinated/population)*100 
from dbo.CovidDeaths dea
join  dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPoepleVaccinated/Population)*100
from PopvsVac


-- TEMP TABLE
-- Specify the data type when using temp table

Drop Table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, 
dea.date) as RollingPeopleVaccinated -- partition by means breaking it up by location. 
--Because we want the count to start over every time it reaches a new location
--, (RollingPeopleVaccinated/population)*100 
from dbo.CovidDeaths dea
join  dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated


-- Creating view to store data for later visualization 

Create view PercentPopulationVaccinated as 
select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, 
dea.date) as RollingPeopleVaccinated -- partition by means breaking it up by location. 
--Because we want the count to start over every time it reaches a new location
--, (RollingPeopleVaccinated/population)*100 
from dbo.CovidDeaths dea
join  dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

--Creating a view for the top locations with the hightest death count per pop
Create view TotalDeathCount as 
select location,MAX(cast(total_deaths as int)) as TotalDeathCount -- cast total_deaths as int so its read as numeric
from dbo.CovidDeaths
--where location like '%States%'
where continent is not null
group by location
--order by TotalDeathCount desc 