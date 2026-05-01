select *
from covid_deaths
order by 3,4
;

select *
from covid_vaccinations
order by 3,4
;

-- 选择我们将要使用的数据
select location,`date`,total_cases,new_cases,total_deaths,population
from covid_deaths
order by 1,2
;

-- 更新date的字符类型，从text变为date
UPDATE covid_deaths 
SET `date` = STR_TO_DATE(`date`, '%Y/%m/%d');
ALTER TABLE covid_deaths 
MODIFY COLUMN `date` DATE; 

-- 比较 总病例 vs 总死亡人数
select location,`date`,total_cases,total_deaths,(total_deaths/total_cases)*100 as death_percentage
from covid_deaths
where location = "china"
;

-- 比较 总病例数 vs 总体人口
select location,`date`,(total_cases/population)*100 as cases_percentage,total_cases,population
from covid_deaths
where location = "china"
;

-- 看各国感染率排名
select location,population,MAX(total_cases) as highest_infection_count,max(total_cases/population)*100 as cases_percentage
from covid_deaths
group by location,population
order by cases_percentage desc
;

-- 看各国感染率排名
select location,population,MAX(total_cases) as highest_infection_count,max(total_deaths/population)*100 as deaths_percentage
from covid_deaths
group by location,population
order by deaths_percentage desc
;

-- 展示各国人均死亡人数最高的国家
select location,max(total_deaths) as total_death_count
from covid_deaths
where continent is not null
group by location
order by total_death_count desc
;

-- 按大洲划分(continent)
select continent,max(total_deaths) as total_death_count
from covid_deaths
where continent is not null
group by continent
order by total_death_count desc
;

-- 按大洲划分(location)
-- 展示各大洲的死亡人数排名
select location,max(total_deaths) as total_death_count
from covid_deaths
where continent is null
group by location
order by total_death_count desc
;

-- 全球计数数字指标
select sum(new_cases),sum(new_deaths),sum(total_deaths)/sum(total_cases)*100 as death_percentage
from covid_deaths
where continent is not null
order by 1,2
;

-- 全球性指标(按日期进行排序)
select `date`,sum(new_cases),sum(new_deaths),sum(total_deaths)/sum(total_cases)*100 as death_percentage
from covid_deaths
where continent is not null
group by `date`
order by 1,2
;

-- 查看已经接种疫苗的人占世界人口的比例

select 
dea.continent,
dea.location,
dea.`date`,
dea.population,
vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location,dea.`date`)	as rolling_people_vaccinated,
(rolling_people_vaccinated/population)*100
from covid_deaths as dea
join covid_vaccinations as vac
	on dea.location = vac.location
    and dea.`date` = vac.`date`
where dea.continent is not null
order by 2,3
;

-- use CTE
-- 计算不等放在临时的cet函数里面进行计算，因为：我还没生成这个列，你不能用！
with pop_vs_vac as
(
select 
    dea.continent,
    dea.location,
    dea.`date`,
    dea.population,
    vac.new_vaccinations,
    sum(vac.new_vaccinations) over (partition by dea.location order by dea.`date`) as rolling_people_vaccinated
from covid_deaths as dea
join covid_vaccinations as vac
    on dea.location = vac.location
    and dea.`date` = vac.`date`
where dea.continent is not null
)
select 
    *,
    (rolling_people_vaccinated / population) * 100 as vaccination_percentage # 在这你进行外表计算
from pop_vs_vac
order by location, `date`;

-- temp table
drop temporary table if exists percent_population_vaccinated;

create temporary table percent_population_vaccinated
(
    continent varchar(255),
    location varchar(255),
    date datetime,
    population numeric,
    new_vaccinations numeric,
    rolling_people_vaccinated numeric
)
;

-- 插入数据
insert into percent_population_vaccinated
select 
    dea.continent,
    dea.location,
    dea.`date`,
    dea.population,
    vac.new_vaccinations,
    sum(vac.new_vaccinations) over (partition by dea.location order by dea.`date`) as rolling_people_vaccinated
from covid_deaths as dea
join covid_vaccinations as vac
    on dea.location = vac.location
    and dea.`date` = vac.`date`
where dea.continent is not null;

-- 最后查询 + 计算百分比
select 
    *,
    (rolling_people_vaccinated / population) * 100 as vaccination_percentage
from percent_population_vaccinated
order by location, date;

-- 创建需要用到的数据集，然后在后续可视化将会用到
create view percent_population_vaccinated as
select percent_population_vaccinated
    dea.continent,
    dea.location,
    dea.`date`,
    dea.population,
    vac.new_vaccinations,
    sum(vac.new_vaccinations) over (partition by dea.location order by dea.`date`) as rolling_people_vaccinated
from covid_deaths as dea
join covid_vaccinations as vac
    on dea.location = vac.location
    and dea.`date` = vac.`date`
where dea.continent is not null;

select *
from percent_population_vaccinated
;