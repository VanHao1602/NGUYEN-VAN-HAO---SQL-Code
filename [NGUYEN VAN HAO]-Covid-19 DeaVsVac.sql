Create database Porfolio_Projects

select top 5 *
from dbo.CovidDeaths

-- Check datatype của 1 column
SELECT DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dbo.CovidDeaths' AND COLUMN_NAME = 'total_deaths'

-- Thay đổi lại định dạng dữ liệu của cột

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths FLOAT;

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases FLOAT;

ALTER TABLE CovidDeaths
ALTER COLUMN new_cases FLOAT;

ALTER TABLE CovidDeaths
ALTER COLUMN new_deaths FLOAT;


-- Chọn ra các cột sử dụng để EDA --

Select location, date, total_cases, new_cases, total_deaths, population
from dbo.CovidDeaths
order by 1,2 -- (by location, date)

-- Truy vấn tổng số ca mắc (Total cases) và tổng số ca tử vong (Total Deaths)

Select location, date, total_cases, total_deaths, (total_deaths/ total_cases) * 100 as DeathPercentage
from dbo.CovidDeaths
where location like '%state%' -- Thay đổi location -- 
order by 1,2

-- Truy vấn tổng số ca mắc_total cases so với dân số (population)
-- Phần trăm dân số mắc Covid-19 --

Select location, date, population, total_cases, (total_cases/ population) * 100 as PopulationPercentage
from dbo.CovidDeaths
where location like '%state%' -- Thay đổi location -- 
order by 1,2

--  Looking at countries with highest infection rate compared to population --

Select location, population, Max(total_cases) as HighestInfection, Max((total_cases/ population)) * 100 as PopulationPercentageInfected
from dbo.CovidDeaths
-- where location like '%state%' -- Thay đổi location -- 
group by location, population
order by PopulationPercentageInfected desc

-- Showign countries with highest death count per population

Select location,  Max(total_deaths) as MaxTotalDeath
from dbo.CovidDeaths
-- where location like '%state%' -- Thay đổi location -- 
group by location
order by MaxTotalDeath desc

-- Break things down by continent
-- Showing continents with the highest death count per country --

Select continent,  Max(total_deaths) as MaxTotalDeath
from dbo.CovidDeaths
group by continent
order by MaxTotalDeath desc

-- Gloabal number --
Select date,
       sum(new_cases) as total_cases,
       sum(new_deaths) as total_deaths,
       CASE WHEN sum(new_cases) = 0 THEN 0
            ELSE (sum(new_deaths) * 1.0 / sum(new_cases)) * 100
       END as death_percentage
from dbo.CovidDeaths
group by date
order by date desc;



-------------------------------------
select top 5 *
from dbo.CovidVaccinations

select *
from dbo.CovidDeaths a
join dbo.CovidVaccinations b
on a.[location] = b.location
and a.date = b.date

-- looking at total population vs vaccinations
-- Subquery

select a.continent, a.location, a.date, a.population, b.new_vaccinations
        ,sum(b.new_vaccinations) over (partition by a.location order by a.date) as RollingPeopleVaccinated
--       , (RollingPeopleVaccinated/a.population) * 100
from dbo.CovidDeaths a
join dbo.CovidVaccinations b
on a.[location] = b.location
and a.date = b.date
order by 2,3

-- CTE

with PopVsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select a.continent, a.location, a.date, a.population, b.new_vaccinations
        ,sum(b.new_vaccinations) over (partition by a.location order by a.date) as RollingPeopleVaccinated
from dbo.CovidDeaths a
join dbo.CovidVaccinations b
on a.[location] = b.location
and a.date = b.date
-- order by 2,3 
)
select *   ,(RollingPeopleVaccinated/population) * 100
from PopVsVac

-- Temp Table
create table PercentPopulationVaccinated
(
    continent nvarchar(50),
    loacation nvarchar(50),
    date datetime,
    population bigint,
    new_vaccinations float,
    RollingPeopleVaccinated float
)

Insert into PercentPopulationVaccinated
select a.continent, a.location, a.date, a.population, b.new_vaccinations
        ,sum(b.new_vaccinations) over (partition by a.location order by a.date) as RollingPeopleVaccinated
from dbo.CovidDeaths a
join dbo.CovidVaccinations b
on a.[location] = b.location
and a.date = b.date
-- order by 2,3 

select *, (RollingPeopleVaccinated/population) * 100
from PercentPopulationVaccinated;

-- Creating View to store data for later visualizations

Create View VacVsPop_Percentage as
select * 
from dbo.PercentPopulationVaccinated
