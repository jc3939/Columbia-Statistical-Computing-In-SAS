libname Rawdata 'D:\Documents\My SAS Files\9.2\Project';
*Read raw data set;
data Work.Real_GDP_Growth_Rates;
set Rawdata.data02;
label gry2001='GDP_Growth_Rate_in_2001'
	  gry2002='GDP_Growth_Rate_in_2002'
	  gry2003='GDP_Growth_Rate_in_2003'
	  gry2004='GDP_Growth_Rate_in_2004'
	  gry2005='GDP_Growth_Rate_in_2005'
	  gry2006='GDP_Growth_Rate_in_2006'
	  gry2007='GDP_Growth_Rate_in_2007'
	  gry2008='GDP_Growth_Rate_in_2008'
	  gry2009='GDP_Growth_Rate_in_2009'
      gry2010='GDP_Growth_Rate_in_2010'
      gry2011='GDP_Growth_Rate_in_2011';
run;
data Work.Diversity_and_Competitive;
set Rawdata.data08;
label y2004='Diversification_index_2004'
	  y2005='Diversification_index_2005'
	  y2006='Diversification_index_2006'
	  y2007='Diversification_index_2007'
	  y2008='Diversification_index_2008'
	  y2004to2008='Annual_Export_Growth';
	  informat Report_Date date10.;
	  format y2004to2008 percent.
			Report_Date date10.;
run;

data Work.International_Prices_of_Exports;
		set Rawdata.data09;
		informat Unit $CHAR10.
				y1996 dollar9.2
				y1997 dollar9.2
				y1998 dollar9.2
				y1999 dollar9.2
				y2000 dollar9.2
				y2001 dollar9.2
				y2002 dollar9.2
				y2003 dollar9.2
				y2004 dollar9.2
				y2005 dollar9.2
				y2006 dollar9.2
				y2007 dollar9.2
				y2008 dollar9.2;
		format Unit $CHAR10.
				y1996 dollar9.2
				y1997 dollar9.2
				y1998 dollar9.2
				y1999 dollar9.2
				y2000 dollar9.2
				y2001 dollar9.2
				y2002 dollar9.2
				y2003 dollar9.2
				y2004 dollar9.2
				y2005 dollar9.2
				y2006 dollar9.2
				y2007 dollar9.2
				y2008 dollar9.2;
		label F1='Product_Name'
			  y1996='Price_in_1996'
			  y1997='Price_in_1997'
			  y1998='Price_in_1998'
			  y1999='Price_in_1999'
			  y2000='Price_in_2000'
			  y2001='Price_in_2001'
			  y2002='Price_in_2002'
			  y2003='Price_in_2003'
			  y2004='Price_in_2004'
			  y2005='Price_in_2005'
			  y2006='Price_in_2006'
			  y2007='Price_in_2007'
			  y2008='Price_in_2008';
run;

data Work.Corruption_Perception_Index;
set Rawdata.data21;
run;
data Work.Public_protest;
set Rawdata.data22;
label pty2006='Protests_in_2006'
		pty2007='Protests_in_2007'
		pty2008='Protests_in_2008'
		pty2009='Protests_in_2009'
		pty2010='Protests_in_2010'
		pty2011='Protests_in_2011'
		pty2012='Protests_in_2012';
run;


* creating variables and creating variables conditionally 1;
data Work.GDP_New_Var;
set Work.Real_GDP_Growth_Rates;
* create the new variable which count the average gdp growth rate from year 2001 to 2011;
GDP_mean_rate=(gry2001+gry2002+gry2003+gry2004+gry2005+gry2006+gry2007+gry2008+gry2009+gry2010+gry2011)/11;
* if average growth rate larger than 5%, it means good economic environment, which is represented by 1, otherwise, 0;
* we use 0 and 1 to represent different categories, since we want to build regression model in final report and will use it as dummy variable;
if GDP_mean_rate>=5 then evaluation_GDP = 1;
else if GDP_mean_rate<5 then evaluation_GDP =0;
run;
* creating variables and creating variables conditionally 2;
data Work.Price_of_Export_New_Var;
set Work.International_Prices_of_Exports;
mean_price=(y1996+y1997+y1999+y2000+y2001+y2002+y2003+y2004+y2005+y2006+y2007+y2008+y2009)/13;
* average price larger than 200 means that kind of material belongs to high-price category, represented by 1, otherwise, 0;
* also for dummy;
if mean_price>=200 then evaluation_price=1;
else if mean_price<200 then evaluation_price=0;
run;


* creating variables and creating variables conditionally 3;
data Work.Public_protest_New_Var;
set Work.Public_protest;
mean_protest=(pty2006+pty2007+pty2008+pty2009+pty2010+pty2011+pty2012)/7;
* 1 represent heavy protest situation;
if mean_protest>=1 then evaluation_protest=1;
else if mean_protest<1 then evaluation_protest=0;
run;
* concatenating data sets;
* try to reveal the relationship between growthrate and political protest;
data Work.growthrate_protest;
set Work.GDP_New_Var Work.Public_protest_New_Var;
run;
* merge one-to-one: competitiveness vs. cpi;
data Work.cpicom;
merge Work.Diversity_and_Competitive Work.Corruption_Perception_Index;
by Country;
run;
* enhancing reports;
* creating user-defined formats;
proc format;
value DOC 
low-<2 ='Clean'
2-<4 = 'Bearable'
4-high='Corrupt';
run;


option center;
ods html file='D:\Documents\My SAS Files\9.2\Project\competitiveness_cpi.html' style=sasweb;
proc print data=Work.cpicom label;
title1 'corruption perception index (cpi) vs competitiveness and diversification';
footnote 'Classified';
label y2004to2008='Annual export growth (%)';
format y2004to2008 percent. y2012_index DOC.;
where y2012_index>=4;
run;
title;
footnote;



ods html;
* Producing Summary Reports;
* We first merge Data02_new and Data22_new, and then produce summary reports;
* merge one-to-one;
data Work.growth_protest;
merge Work.GDP_New_Var Work.Public_protest_New_Var;
by Country;
run;

* one way and chisq test;
proc freq data=Work.growth_protest;
tables evaluation_GDP evaluation_protest/chisq;
output out= Work.Growth_Protest_Chisq1w chisq;
run;
* two way ;
proc freq data=Work.growth_protest;
tables evaluation_GDP*evaluation_protest/chisq;
output out=Work.Growth_Protest_Chisq2w chisq;
run;
* proc means;
proc means clm data=Work.growth_protest sum mean std var median;
run;
* proc print;
proc print data=Work.growth_protest label width = full heading=H;
format pty2012 percent.;
label pty2012='GDP growth rate of 2012(%)';
run;
* producing the same summary reports on the second dataset;
data Work.cpicom_new_var;
set Work.cpicom;
format y2012_index DOC.;
if Global>0 then competitive_index='Competitive';
else if Global<0 then competitive_index='Weak';
run;
* proc freq, one-way;
proc freq data=Work.cpicom_new_var;
tables y2012_index /chisq;
output out= Work.cpicom_newvar_chisq1w chisq;
run;
* proc freq, two-way;
proc freq data=Work.cpicom_new_var;
tables y2012_index*competitive_index/chisq;
output out=cpicom_newvar_chisq2w chisq;
run;
*proc print;
proc print data=Work.cpicom_new_var label width = full heading=H;
format y2012_index DOC. Report_Date date10.;
label y2004to2008='Annual export growth (%)';
run;
*Describing Data - Producing Bar Charts;
*In the first data set, we plot the verticle bar chart to see the frequency distribution of degree of corruption in 2012, there are three degrees of
corruption, as we previously defined, Clean, Bearable andd Corrupt. In the horizontal bar chart, we plot the frequency distribution of Highly competitive
country, which is defined as '1' and low competitive country, which is defined as '0';
proc gchart data=Work.cpicom_new_var;
vbar y2012_index/discrete;
hbar competitive_index/discrete;
run;
*Here we plot the subgrouped horizontal bar chart to compare the degree of corruption with the competitiveness of those countries,
from the graph we can conclude that those corrupt countries are more likely to lose their competitiveness in the world.;
proc gchart data=Work.cpicom_new_var;
		hbar y2012_index/discrete
		subgroup = competitive_index;
		vbar y2012_index/discrete
		group=competitive_index;
run;
*In the second data set we plot the distrubution of frequency of those countries which have high GDP growth rate, which are denoted as 1,
and which have low GDP growth rate, denoted as 0. Then we plot the horizontal bar to illustrate the frequency distribution of 
political protest number from 2006 to 2012. Frequent protest is denoted as 1 and rare protest is denoted as 0.;
proc gchart data=Work.growth_protest;
vbar evaluation_GDP/discrete;
hbar evaluation_protest/discrete;
run;
*We plot the grouped and subgrouped bar chart to see the relationship between GDP growth rate and frequency of protest. 
From the chart, we can conclude that low GDP growth rate corresponds to the high frequency of political protest.;
proc gchart data=Work.growth_protest;
hbar evaluation_GDP/discrete
subgroup = evaluation_protest;
vbar evaluation_protest/discrete
group = evaluation_GDP;
run;
* Describing Data - Producing Scatter and Line Plots;
* In the GDP_Protest data set, we plot the linear regression line between GDP Growth rate and number of political protest. The less GDP Growth 
Rate corresponds to a frequent protest.;
proc gplot data=Work.Growth_protest;
symbol cv=black i=rlclm  v=dot;
plot GDP_mean_rate*mean_protest;
run;

*We now plot the box plot of GDP Growth rate vs. GDP growth evaluation in 2012;
proc gplot data=Work.Growth_protest;
symbol co=red ci=blue i=boxfjt10 bwidth=1;
plot GDP_mean_rate*evaluation_GDP;
run;


*Second example, we compare the GDP growth rate in 2011 with the Protest number in 2011.;
proc gplot data=Work.Growth_protest;
symbol cv=black i=rlclm  v=dot;
plot gry2011*pty2012;
run;
*Here we plot the box plot of mean protest number from 2006 to 2012 vs. protest evaluation(1 or 0); 
proc gplot data=Work.Growth_protest;
symbol co=red ci=blue i=boxfjt10 bwidth=1;
plot mean_protest*evaluation_protest;
run;
