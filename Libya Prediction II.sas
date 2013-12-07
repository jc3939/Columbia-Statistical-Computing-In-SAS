libname Africa 'C:\Users\hp\Documents\SAS\project';
*In this final project, we use five data sets, that is: GDP growth rate in Africa, Global Product Price, Protest frequency in each African Country,
Corruption Percentages Index (CPI), which represents corruption degree of each country and last, diversification and competiveness index of each
African Country;

*Our primary goal is to predict the protest frequency of Libya in the future five years based on our prediction of
gold price in the future five years, as we found there is a correlation between GDP growth rate, Protest frequency, global gold price, and CPI
 after we figuring out the correlation matrix of them. We first make correlation matrix of GDP growth rate, gold cocoa and oil price and then we 
found there are positive correlations existing between GDP growth rate and oil price. Then we did a prediction on the oil price over time, 
the gold price has a trend to increase in the future five years. Then we predict that the GDP growth rate might increase in the future. As we did a
regression of GDP over oil price we can predict the specific amount of GDP growth rate in the future five years. As we find before, the GDP growth 
rate has negative correlation with protest frequency and positive with CPI, so there might be less protest frequency and higher 
CPI in the future in Libya.

Then, we did two two sample t-test and find out there are significant difference between GDP growth rate in Libya and Zimbabwe, and there is no 
significant difference between GDP growth rate in Egypt and South Africa. This reveal that there might be some economic linke between Lybia and Zimbabwe
, which is worth of further delve. 

In conclusion, we predict that the political enironment in Libya will be more stable but the corruption degree would be more severe. With this conclusion, I
hope we can offer some helpful information for some international organizations and investors.





*** Data Transformations;
* manipulating character and numeric values;
*We used two string function to find the short name of each country, which will make us more convient in processing data;
data work.data02;
	set Africa.Data02;
	cn1=substr(Country,1,3);
	cn1=upcase(cn1);
	keep Country cn1 gry2001-gry2011;
run;

data work.data02;
	set data02;
	retain Country cn1 gry2001-gry2011;
run;
proc print data=work.data02;
	title 'Country Name';
run;
title;
*** Processing Data Iteratively;
* we are trying to model the growth trend of oil price, and see in which year it will be greater than $113;
* based on the data from last eight years, the annual growth rate of oil is 12.7%;
data work.oilprice;
		oil=61.86;
		max=113;
	array oilprice{6};
	do Year=1 to 30 until (gold>max);
		oil=oil*(1+0.127);
		max=max;
		oilprice{Year}=gold;
	end;
run;
proc print data=work.oilprice;
	format oil dollar14.2 max dollar14.2;
run;
*** Restructuring a Data Set;
* rotation;
* using the TRANSPOSE procedure as a preparation for builing regression model;
* step1: subset and TRANSPOSE data09;
data Africa.subset_data09;
	set Africa.Data09;
	if _ in ('Gold','Oil (crude)');
run;
proc transpose
	data=Africa.subset_data09
	out=Africa.rotate09(rename=(col1=gold col2=oil));
run;
proc print data=Africa.rotate09 noobs;
run;
* step2: subset and TRANSPOSE data02;
data Africa.subset_data02;
	set Africa.Data02;
	if  Country in ('Libya', 'Zimbabwe');
run;
proc transpose
	data=Africa.subset_data02
	out=Africa.rotate02;
run;
proc print data=Africa.rotate02 noobs;
run;
*step3: AGAIN: sunset datasets: "Africa.rotate02" and "Africa.rotate09";
data Africa.model_price;
	set Africa.rotate09;
	if _NAME_ in ('y2001','y2002','y2003','y2004','y2005','y2006','y2007','y2008');
run;
data Africa.model_gdp;
	set Africa.rotate02 (rename=(col1=Libya col2=Zimbabwe));
	if _NAME_ in ('gry2001','gry2002','gry2003','gry2004','gry2005','gry2006','gry2007','gry2008');
run;
* step4: AGAIN.......transpose;
proc transpose
	data=Africa.model_gdp
	out=work.jianjun02;
run;
data Africa.model_gdp;
	set work.jianjun02 (rename=(gry2001=y2001 gry2002=y2002 gry2003=y2003 gry2004=y2004 gry2005=y2005 gry2006=y2006 gry2007=y2007 gry2008=y2008));
run;
proc transpose
	data=Africa.model_price
	out=Africa.model_price;
run;
*Append these two data set together;
proc append base=Africa.model_gdp force
   data=Africa.model_price;
run;
proc transpose
	data=Africa.model_gdp
	out=Africa.model_gdp;
run;

***Working with dates and longitudinal Longitudinal data;
data data09;
	*Change the order of the variables permanently;
	retain _ y1996-y2008;
	set Africa.data09;
run;

data rotate (keep=Product_Name Year Annual_Price);
	set Africa.data09
			(rename=(_=Product_Name));
	array Price{13} y1996-y2008;
	do i=1 to 13;
		Year=cats('Year',i+1995);
		Annual_Price=Price{i};
		output;
	end;
run;

proc sort data=rotate;
	by Product_Name;
run;

data sum_rotate (keep=Product_Name Amount);
	set rotate;
	by Product_Name;
	if first.Product_Name then Amount=0;
	Amount+Annual_Price;
	if last.Product_Name;
run;

data average_rotate (keep=Product_Name Average_Price);
	set sum_rotate;
	Average_Price=Amount/13;
run;

***Correlation;
*In this step, we calculate the correlation matrix of Egypt GDP, oil price, gold price and Cocoa price from 2001 to 2008 in order to figure out their correlations.
By doing so, we conclude that GDP growth rate in Egypt has strong correlation with oil price and gold price;
data corr_gdp (keep=Country gry2001 gry2002 gry2003 gry2004 gry2005 gry2006 gry2007 gry2008 
	rename=(Country=Name_Variable gry2001=y2001 gry2002=y2002 gry2003=y2003 gry2004=y2004 gry2005=y2005 gry2006=y2006 gry2006=y2006 gry2007=y2007 gry2008=y2008));
	length Country $ 18;
	set Africa.data02;
	if Country in ('Libya');
run;

*Subset the data set so only obs of oil, gold and Cocoa are included;
data corr_price (keep=_ y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 rename=(_=Name_Variable));
	set Africa.data09;
	if _ in ('Oil (crude)','Gold','Cocoa');
run;

*Concate the two data sets;
data corr_final;
	set Corr_gdp Corr_price;
run;

proc transpose
	data=corr_final
	out=Africa.corr_final;
run;

data Africa.corr_final (rename=(col1=Libya_GDP col2=Cocoa_Price col3=Gold_Price col4=Oil_Price));
	set Africa.corr_final;
run;
*make the correlation matrix of four variables;
proc corr data=Africa.corr_final out=Africa.Out_Corr;
	var  Libya_GDP Cocoa_Price Gold_Price Oil_Price;
run;

*In this step, we want to make the correlation matrix to investigate the correlation matrix of gdp growth rate, cpi and number of protests;
data corr2_gdp (keep=Country gry2006 gry2007 gry2008 gry2009 gry2010 gry2011
	rename=(Country=Name_Variable gry2007=y2007 gry2008=y2008 gry2009=y2009 gry2010=y2010 gry2011=y2011));
	length Country $ 18;
	set Africa.data02;
	if Country in ('Libya');
run;

data corr2_cpi (keep=Country y2006_index y2007_index y2008_index y2009_index y2010_index y2011_index
	rename=(Country=Name_Variable y2006_index=y2006 y2007_index=y2007 y2008_index=y2008 y2009_index=y2009 y2010_index=y2010 y2011_index=y2011));
	length Country $ 18;
	set Africa.data21;
	if Country in ('Libya');
run;

data corr2_pt (keep=Country pty2006 pty2007 pty2008 pty2009 pty2010 pty2011
	rename=(Country=Name_Variable pty2006=y2006 pty2007=y2007 pty2008=y2008 pty2009=y2009 pty2010=y2010 pty2011=y2011));
	length Country $ 18;
	set Africa.data22;
	if Country in ('Libya');
run;

*concate the three data sets;
data corr2_final;
	set Corr2_gdp Corr2_cpi Corr2_pt;
run;

proc transpose
	data=corr2_final
	out=Africa.corr2_final;
run;

data Africa.corr2_final (rename=(col1=Libya_GDP col2=Protest_Rate col3=CPI));
	set Africa.corr2_final;
run;
*make the correlation matrix;
proc corr data=Africa.corr2_final out=Africa.Out_Corr;
	var  Libya_GDP Protest_Rate CPI;
run;


*** Simple Regression1: 
dependent: GDP Growth Rate in Libya, regressor: International Oil Price ;
proc reg data=Africa.model_gdp;
	model Libya=oil;
run;
quit;
*** Simple Regression2:
dependent: GDP Growth Rate in Zimbabwe, regressor: International Oil Price ;
proc reg data=Africa.model_gdp;
	model Zimbabwe=Oil;
run;
quit;
*** Multiple-Regression
dependent: GDP Growth Rate in Libya, regressors: International Oil Price + International Gold Price;
proc reg data=Africa.model_gdp;
	model Libya=Oil Gold;
run;
quit;
*** T-tests Comparison 1
Egypt_GDP v.s. South Africa_GDP;
* data transformation and subset;
proc transpose
	data=Africa.model_gdp
	out=Africa.ttest;
run;
data Africa.ttestnew;
	set Africa.ttest;
	if _NAME_ in ('Eygpt');
run;
data Africa.ttestnew2;
	set Africa.ttest;
	if _NAME_ in ('South_Africa');
run;
* rotate dataset "ttestnew" and "ttestnew2" to fit the code of t-test;
data rotate;
	set Africa.ttestnew;
	array contrib{8} y2001-y2008;
	do i=1 to 8;
	Period=cats("y200",i);
	Amount=contrib{i};
	output;
	end;
run;
data rotate2;
	set Africa.ttestnew2;
	array contrib{8} y2001-y2008;
	do i=1 to 8;
	Period=cats("y200",i);
	Amount=contrib{i};
	output;
	end;
run;
* subset dataset 'rorate' & 'rotate2';
data Africa.rotate1;
	set work.rotate;
	keep _name_ Period Amount;
run;
data Africa.rotate2;
	set work.rotate2;
	keep _name_ Period Amount;
run;
* merge 'rotate1' and 'rotate2';
data Africa.final_ttest;
	set Africa.rotate1 Africa.rotate2;
run;
*** two “two-sample t-tests”;
proc ttest data=Africa.final_ttest;
	class _name_;
	var Amount;
run;
* t-test 2: GDP_Libya GDP_Zimbabwe;
* transpose;
proc transpose
	data=Africa.data02
	out=Africa.data02_rotate;
run;
* subset;
data work.data02_lib_zim;
	set Africa.data02_rotate;
	keep col22 col45;
run;
* rename;
data work.data02_lib_zim;
	set work.data02_lib_zim (rename=(col22=libya col45=zimbabuwe));
run;
* transpose;
proc transpose
	data=work.data02_lib_zim
	out=work.data02_lib_zim;
run;
* subset;
data work.data02_lib;
	set work.data02_lib_zim;
	if _NAME_ in ('libya');
run;
data work.data02_zim;
	set work.data02_lib_zim;
	if _NAME_ in ('zimbabuwe');
run;
* rotate dataset "work.data02_lib" and "work.data02_zim" to fit the code of t-test;
data rotate_lib;
	set work.data02_lib;
	array contrib{11} col1-col11;
	do i=1 to 11;
	Period=cats("y200",i);
	Amount=contrib{i};
	output;
	end;
run;
data rotate_zim;
	set work.data02_zim;
	array contrib{11} col1-col11;
	do i=1 to 11;
	Period=cats("y200",i);
	Amount=contrib{i};
	output;
	end;
run;
* subset 'rotate_lib' and 'rotate_zim';
data work.rotate_lib;
	set work.rotate_lib;
	keep _name_ Period Amount;
run;
data work.rotate_zim;
	set work.rotate_zim;
	keep _name_ Period Amount;
run;
* merge 'rotate_zim' and 'rotate_lib';
data Africa.final_ttest_libzim;
	set work.rotate_lib work.rotate_zim;
run;
*** “two-sample t-tests”;
proc ttest data=Africa.final_ttest_libzim;
	class _name_;
	var Amount;
run;
