cd "/Users/shuhuisun/Downloads/Bike-Sharing-Dataset"
capture log close
log using "/Users/shuhuisun/Downloads/bike-sharing-demand/final project4", text replace

clear all
set more off

use "/Users/shuhuisun/Downloads/Bike-Sharing-Dataset/hour.dta"

*summary statistics
sum season holiday workingday weathersit temp atemp hum windspeed casual registered cnt
outreg2 using Table_summary, excel replace sum(log)

pwcorr cnt temp atemp hum windspeed workingday holiday


*OLS
reg cnt i.season i.holiday i.workingday i.weather temp hum windspeed
outreg2 using OLS, excel dec(3) replace


**test of heteroskedasticity
*1plot
rvfplot, yline(0)
graph save "/Users/shuhuisun/Downloads/Bike-Sharing-Dataset",replace
graph export "/Users/shuhuisun/Downloads/Bike-Sharing-Dataset/visual_heteroskedasticity.tif", as(tif) replace

*2Breush-Pagon test
reg cnt i.season i.holiday i.workingday i.weather temp hum windspeed 
estat hettest
*3Aternative White's test
imtest, white
*there exists heteroskedasticity


*ols+hr
reg cnt i.season i.holiday i.workingday i.weather temp hum windspeed i.hr, robust
outreg2 using ols_hr, excel dec(3) replace
*graph hr coefficient would show that at 8/17/18o'clock, the demand is high (rush hours)

*ols+hr+t
reg cnt i.season i.holiday i.workingday i.weather temp hum windspeed i.hr instant, robust
outreg2 using ols_hr, excel dec(3)
*season coefs become more reasonable when separating time trend from season

*Get R^2 without time trend
reg cnt instant, robust
predict cnthat, r
reg cnthat i.season i.holiday i.workingday i.weather temp hum windspeed i.hr, robust 
outreg2 using ols_hr, excel dec(3) 
*R-squared is 0.6473, not bad.

*simplify the model by rush and non-rush hours
gen rush = 1 if hr == 8 | hr == 17 | hr == 18 
replace rush = 0 if rush ==.
*coef >= 300 as threshold
reg cnt i.season i.holiday i.workingday i.weather temp hum windspeed i.rush, robust
outreg2 using OLS, excel dec(3)
*graph hr coefficient would show that at 8/17/18o'clock, the demand is high (rush hours)

*ols+rush+t
reg cnt i.season i.holiday i.workingday i.weather temp hum windspeed i.rush instant, robust
outreg2 using OLS, excel dec(3) 
*season coefs become more reasonable when separating time trend from season

*Get R^2 without time trend
reg cnthat i.season i.holiday i.workingday i.weather temp hum windspeed i.rush, robust 
outreg2 using OLS, excel dec(3) 

tsset instant, generic
**test autocorr
reg cnt i.season i.holiday i.workingday i.weather temp hum windspeed i.rush 
predict u, r
scatter u instant
graph save "/Users/shuhuisun/Downloads/Bike-Sharing-Dataset",replace
graph export "/Users/shuhuisun/Downloads/Bike-Sharing-Dataset/visual_autocorrelation.tif", as(tif) replace
reg u l.u ll.u lll.u
outreg2 using ar, excel dec (3) replace
*lag 1 is most economically significant

*Breusch-Godfrey lm test on lag residuals significance
reg cnt i.season i.holiday i.workingday i.weather temp hum windspeed i.rush 
estat bgodfrey, lags(1)
*significant autocorrelation in the model.
*durbin-watson test
estat dwatson
*for AR(1)
*d=.49. far from 2, center of its distribution. Given #Xs=36, #obs=17319, the lower 5% is larger than 1.855. Durbin-watson test concludes that there is positive autocorrelation.
*estat durbinalt, lags(1)
*Alternative D-W test just to make sure



*stationarity way:  differencing, take square root, taking moving average. we use ma.
gen dcnt = cnt-l.cnt
tsline dcnt in 1/100
dfuller dcnt
gen lcnt = log(cnt)
tsline lcnt in 1/100
dfuller lcnt
gen sqrtcnt = cnt^.5
tsline sqrtcnt in 1/100
dfuller sqrtcnt
*above methods dont work well

tssmooth ma macnt = cnt, window(72)
dfuller macnt
tssmooth ma matemp = temp, window(72)
dfuller matemp 
tssmooth ma mahum = hum, window(72)
dfuller mahum 
tssmooth ma mawindspeed = windspeed, window(72)
dfuller mawindspeed
*after taking ma of 72 lags which is 72 hours, all continuous variables are statoinary


xi: arima macnt i.season i.holiday i.workingday i.weather matemp mahum mawindspeed i.rush, arima(1,0,0) robust
outreg2 using arima, excel dec(3) replace

*test structural break? -- chow's

*reg cnt i.season i.holiday i.workingday i.weather temp hum windspeed i.hr
*estat archlm
*not valid
*lm test concludes that there exists autoregressive conditional heteroskedasticity (ARCH)

*prais cnt i.season i.holiday i.workingday i.weather temp hum windspeed i.hr, rhotype(regress)
*FGLS gets rho value at around .8017 by interation

*GARCH specification might be helpful in predicting demand and the volatility of demand
*coefficient is significant, implying that the variance of the bike sharing demand is conditional on the variance of the previous period. 
xi: arch macnt i.season i.holiday i.workingday i.weather matemp mahum mawindspeed i.rush, arch(1)
outreg2 using arima, excel dec(3) 




log close 
