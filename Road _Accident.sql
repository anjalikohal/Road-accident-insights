select *
from accident.dbo.Accident$

---cleaning ----

----check for null values----
select  count(*)
from accident.dbo.Accident$
where speed_zone is null



---standardize date---
 select ACCIDENT_DATE,CONVERT(date,ACCIDENT_DATE) Accident_Date_u
 from accident.dbo.Accident$

 alter table accident.dbo.accident$
 add Accident_date_u date
  
  update accident.dbo.accident$
  set Accident_date_u=CONVERT(date,ACCIDENT_DATE)

  ---standardize time---
 
 select ACCIDENT_TIME,convert(time,accident_time)
 from accident.dbo.Accident$

 alter table accident.dbo.accident$
 add Accident_time_u time

 update accident.dbo.Accident$
 set Accident_time_u=convert(time,accident_time)

 ----standardize light_condition---

 select LIGHT_CONDITION,
 case 
     when LIGHT_CONDITION =1 then 'Day'
	 when LIGHT_CONDITION=2 then 'Dusk'
	 when LIGHT_CONDITION=3 then 'Dark street lights on'
	 when LIGHT_CONDITION=4 then 'Dark streer lights off'
	 when LIGHT_CONDITION=5 then 'Dark on street lights'
	 when LIGHT_CONDITION=6 then 'Dark street lights unkown'
	 when LIGHT_CONDITION=9 then 'Unknown'
	 end
 from accident.dbo.Accident$

 ----speed zone----

 select speed_zone, case when SPEED_ZONE between 0 and 40 then 'Low Speed'
  when SPEED_ZONE between 41 and 80 then 'Moderate Speed'
  when SPEED_ZONE between 81 and 110 then 'High Speed'
else 'Very High Speed'
end speed_zone1
 from accident.dbo.Accident$
   
alter table accident.dbo.accident$
add Speed_zone1 nvarchar(255)

update accident.dbo.Accident$
set speed_zone1=case when SPEED_ZONE between 0 and 40 then 'Low Speed'
  when SPEED_ZONE between 41 and 80 then 'Moderate Speed'
  when SPEED_ZONE between 81 and 110 then 'High Speed'
else 'Very High Speed'
end


 ---severity---

 select SEVERITY, 
 case when SEVERITY=1 then 'Fatal Accident'
 when SEVERITY=2 then 'Serious Injury Accident'
 when SEVERITY=3 then 'Other Injury Accident'
 when SEVERITY=4 then 'Non Injury Accident'
 end as Injury_level
 from accident.dbo.Accident$
alter  table accident.dbo.accident$
add Injury_level nvarchar(255)

update accident.dbo.Accident$
set Injury_level =case when SEVERITY=1 then 'Fatal Accident'
 when SEVERITY=2 then 'Serious Injury Accident'
 when SEVERITY=3 then 'Other Injury Accident'
 when SEVERITY=4 then 'Non Injury Accident'
 end 

---drop columns no use---
  
  alter table accident.dbo.accident$
 drop column accident_date,accident_time,accident_type,dca_desc,dca_code,light_condition,node_id,no_persons_inj_2,no_persons_inj_3,
 police_attend,road_geometry,road_geometry_desc,severity,rma,Age_groups
 
  alter table accident.dbo.accident$
  drop column _id,accident_type_desc
 
 -----cleaning of second table----
 
 select *
  from accident.dbo.person$
  

 select AGE_GROUP,
 case when AGE_GROUP like '0-18' or AGE_GROUP in ('0-4','13-15','16-17') then 'adolescent' 
 when AGE_GROUP like '18-30' or AGE_GROUP in('18-21','22-25','26-29') then 'Adult'
 when AGE_GROUP like '30-50' or AGE_GROUP in('30-39','40-49') then 'Mature Adult'
 when AGE_GROUP like '50+' or AGE_GROUP in('50-59','60-64','65-69','70+') then 'Senior'
 when AGE_GROUP in ('unknown','45996' )then 'Invalid'
  end as Age_groups
 from accident.dbo.person$
 
 
 alter table accident.dbo.person$
 add Age_groups Nvarchar(255)

 update accident.dbo.person$
 set Age_groups=case when AGE_GROUP like '0-18' or AGE_GROUP in ('0-4','13-15','16-17') then 'adolescent' 
 when AGE_GROUP like '18-30' or AGE_GROUP in('18-21','22-25','26-29') then 'Adult'
 when AGE_GROUP like '30-50' or AGE_GROUP in('30-39','40-49') then 'Mature Adult'
 when AGE_GROUP like '50+' or AGE_GROUP in('50-59','60-64','65-69','70+') then 'Senior'
 when AGE_GROUP in ('unknown','45996' )then 'Invalid'
  end 
 
 ---drop columns---
 
 alter table accident.dbo.person$
 drop column _id,person_no,sex,inj_level,seating_position,helmet_belt_worn,road_user_type
 ,licence_state,taken_hospital,ejected_code

 -----check for duplicacy----
 
 with row_number_cte as(
 select ACCIDENT_NO,
 row_number() over(partition by accident_no order by accident_no)row_num
 from accident.dbo.person$
 )
 select *
 from row_number_cte
 where row_num>1
 
 ---I delete duplicates with  delete statements instead of select statement ---
 delete 
 from row_number_cte
 where row_num>1

----EDA (Exploratory Data Analysis)----
 
 select*
 from accident.dbo.Accident$

 ---how many accidents were there in total
  
select count(*) total_accident, datepart(year,Accident_date_u)
 from accident.dbo.Accident$
where datepart(year,Accident_date_u) = 2012
 group by datepart(year,Accident_date_u)
 
 --- what are the most common injury level
 
 select injury_level,count(injury_level) level
 from accident.dbo.Accident$
 group by injury_level
  order by level desc
 
 --- how many people were killed vs injured in accident---
 
 select  sum(no_persons_killed) total_killed, sum (NO_PERSONS_NOT_INJ)total_not_injured
  from accident.dbo.Accident$

 

----what is the distribution of accidents across the week or day of the week?---

select DAY_WEEK_DESC, count(*) total_accidents
 from accident.dbo.Accident$
 group by DAY_WEEK_DESC
  order by total_accidents desc

 ----count accidents on weekends vs weekdays---
 
 select case when DAY_WEEK_DESC in('Saturday','Sunday') then 'Weekend' else 'weekday' end, count(*) total_accident
 from accident.dbo.Accident$
   group by
             case when DAY_WEEK_DESC in('Saturday','Sunday') then 'Weekend' else 'weekday' end

   
 --- monthly accident trend(average over years)

with monthlyaccident as(
 select DATENAME(month,accident_date_u) Month,datepart(year,accident_date_u) year, count(*) total_accident
 from accident.dbo.Accident$
 group by DATENAME(month,accident_date_u),datepart(year,accident_date_u)
 )
select month,avg(acc_monthly) average_monthly
from monthlyaccident
 group by month
  order by average_monthly desc

----average accidents per month in each year--

 select datename(month,accident_date_u) month, datepart(year,accident_date_u) year,count(*) total_acident,
 avg(count(*) )over (partition by datepart(year,accident_date_u))
  from accident.dbo.Accident$
   group by datename(month,accident_date_u) ,datepart(year,accident_date_u)


---how do injury level differ across various age group---

select a.Injury_level,p.Age_groups, count(*) total_accident, 
count(*)*100/sum(count(*)) over(partition by p.age_groups) percentage_accidents
 from accident.dbo.Accident$ a
 join accident.dbo.person$ p
 on a.ACCIDENT_NO =p.ACCIDENT_NO 
 group by a.Injury_level,p.Age_groups

 --Are certain group more likely to be involved in fatal accident

 select p.Age_groups,count(*) total_Accident
 from accident.dbo.Accident$ a
 join accident.dbo.person$ p
 on a.ACCIDENT_NO =p.ACCIDENT_NO 
  where a.Injury_level ='Fatal accident'
   group by p.Age_groups
    order by total_Accident desc

----accident analysis based on time of day and speed zone

select speed_zone1,
   case when datepart(hour,Accident_time_u) between 5 and 12 then 'Morning'
     when DATEPART(hour,Accident_time_u) between 12 and 18 then 'Afternoon'
	 when DAtepart(hour,Accident_time_u)between 18 and 20 then 'Evening'
      else 'Night'
       end time_of_day, count(*) total_accident
from accident.dbo.Accident$
  group by speed_zone1, 
       case when datepart(hour,Accident_time_u) between 5 and 12 then 'Morning'
     when DATEPART(hour,Accident_time_u) between 12 and 18 then 'Afternoon'
	 when DATEPART(hour,Accident_time_u) between 18 and 20 then 'Evening'
      else 'Night' end
  order by total_accident desc 

---most dangerous time of day for accident(the highest ranked hour is the most dangerous time for accident)
 with timeday as(
 select DATEPART(hour,accident_time_u) hours, count(*) total_accident
 from accident.dbo.Accident$
 group by DATEPART(hour,accident_time_u)
 )
 select  *,rank () over (order by  total_accident desc) rank
 from timeday
 
--- yearly trend of accidents with percentage change(accident increaded or decreased over the year)
 
with yeartrend as( 
 select datepart(year,Accident_date_u) year, count(*) total_accident,
 lag(count(*)) over( order by datepart(year,Accident_date_u) ) as previous_year_accident
 from accident.dbo.Accident$
  group by datepart(year,Accident_date_u)
  )
  select* ,abs((total_accident -previous_year_accident))*100/previous_year_Accident as percentage_age
  from yeartrend

---most common accident time by age group(diffrent age group are most at risk)

with timeday as(
select Age_groups,datepart(hour,Accident_time_u) hour,count(*) total_Accident, 
rank() over(partition by age_groups order by count(*)  desc)rank
from accident.dbo.Accident$ a
join accident.dbo.person$ p
on a.ACCIDENT_NO=p.ACCIDENT_NO
 group by  age_groups,datepart(hour,Accident_time_u)
  )
select *
from timeday
where  rank =1
order by total_accident desc

---classifying speed zone into groups(risk assignment&insight)

select case when SPEED_ZONE<=50 then 'Low Risk'
 when speed_zone between 51 and 80 then 'Medium Risk'
 else 'High Risk'
 end risk_category,
 count(*) total_accident
from accident.dbo.Accident$ a
join accident.dbo.person$ p
on a.ACCIDENT_NO=p.ACCIDENT_NO
 group by case when SPEED_ZONE<=50 then 'Low Risk'
 when speed_zone between 51 and 80 then 'Medium Risk'
 else 'High Risk'
 end
  order by total_accident desc

----Accident by gender----
  select count(*) Total_accident,SEX1
   from accident.dbo.person$
   group by SEX1
    order by count(*) desc