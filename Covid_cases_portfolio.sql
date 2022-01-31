
--Importing data

Select *
From Portfolio_project..covid_deaths$
Where continent is not null
Order by 3,4 /*ordering by column name*/

Select 
From Portfolio_project..covid_vaccinations$
Order by 3,4 -- ordering by column name

--Getting started with covid death data

/*Selecting the data to use*/


Select location, date, total_cases, new_cases, total_deaths, population
From Portfolio_project..covid_deaths$
Where continent is not null
Order by 1,2


-- Looking at the total cases vs total deaths, by country 
-- estimating the  likelihood of dying

Select location, date, total_cases, total_deaths, (total_deaths / total_cases ) * 100 as death_percentage
From Portfolio_project..covid_deaths$
Where (continent is not null AND location like '%states%')
Order by 1,2


-- Looking at total cases vs popultion

Select location, date, total_cases, population, ( total_cases / population ) * 100 as incidence_rate
From Portfolio_project..covid_deaths$
Where (continent is not null AND location like '%states%')
Order by 1,2


-- Looking at countries with highest infection rate compared to population

Select location, max(total_cases) as highest_case_count , population, round((max(total_cases) / population ) * 100,2) as incidence_rate
From Portfolio_project..covid_deaths$
Where continent is not null 
-- Where location like '%states%'
Group by location, population
Order by incidence_rate desc


-- Looking at countries with the highest death count per population

Select location, max(Cast(total_deaths as int)) as total_death_count
From Portfolio_project..covid_deaths$
Where continent is not null 
Group by location, population
Order by total_death_count desc


-- BREAKING THINGS BY CONTINENT

--showing the continent with highest death count

Select continent, max(Cast(total_deaths as int)) as total_death_count
From Portfolio_project..covid_deaths$
Where continent is not null
Group by continent
order by total_death_count desc


-- CURRENT OVERALL GLOBAL NUMBERS 
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,SUM(cast(new_deaths as int)) / SUM (new_cases) * 100 as death_percentage
From Portfolio_project..covid_deaths$
Where continent is not null
Order by 1,2

--GLOBAL NUMBERS BY DATE

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,SUM(cast(new_deaths as int)) / SUM (new_cases) * 100 as death_percentage
From Portfolio_project..covid_deaths$
Where continent is not null
Group by date 
Order by 1,2


--- Looking at the vaccination data

Select *
From Portfolio_project..covid_vaccinations$


-- Joining both tables

Select*
From Portfolio_project..covid_deaths$ as  dea
Join Portfolio_project..covid_vaccinations$ as vac
	On dea.location = vac.location
	AND dea.date = vac.date
	

-- Looking at Total population vs  new vaccinations/day

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From Portfolio_project..covid_deaths$ as  dea
Join Portfolio_project..covid_vaccinations$ as vac
	On dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
order by 2,3
	

-- Looking at Total population vs everyday vaccinations on a roll out basis

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as rolling_people_vaccinated -- using bigint instead of int with convert() to bypass arithmetic overflow error 
From Portfolio_project..covid_deaths$ as  dea
Join Portfolio_project..covid_vaccinations$ as vac
	On dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
order by 2,3


--Calculating vaccination rate by using the new column rolling_people_vaccinated

-- Two methods

--CTE

With PopvsVac (continent,location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as rolling_people_vaccinated -- using bigint instead of int with convert() to bypass arithmetic overflow error 
From Portfolio_project..covid_deaths$ as  dea
Join Portfolio_project..covid_vaccinations$ as vac
	On dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
--order by 2,3
)
Select *, (rolling_people_vaccinated/ population) * 100
From PopvsVac



--Using Temp Table

Create Table #Percent_pop_vaccinated
(
continent nvarchar (255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)
Insert into #Percent_pop_vaccinated
Select  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as rolling_people_vaccinated -- using bigint instead of int with convert() to bypass arithmetic overflow error 
From Portfolio_project..covid_deaths$ as  dea
Join Portfolio_project..covid_vaccinations$ as vac
	On dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
--order by 2,3

Select *, (rolling_people_vaccinated/ population) * 100
From #Percent_pop_vaccinated

DROP Table if exists #Percent_pop_vaccinated


--- Temp table without where clause

Create Table #Percent_pop_vaccinated
( 
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)
Insert into #Percent_pop_vaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as rolling_people_vaccinated -- using bigint instead of int with convert() to bypass arithmetic overflow error 
From Portfolio_project..covid_deaths$ as  dea
Join Portfolio_project..covid_vaccinations$ as vac
	On dea.location = vac.location
	AND dea.date = vac.date
--order by 2,3

Select *, (rolling_people_vaccinated/ population) * 100
From #Percent_pop_vaccinated



--Creating View to store data for later visualizations

Create View Percent_pop_vaccinated as 
Select  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as rolling_people_vaccinated -- using bigint instead of int with convert() to bypass arithmetic overflow error 
From Portfolio_project..covid_deaths$ as  dea
Join Portfolio_project..covid_vaccinations$ as vac
	On dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
--order by 2,3