# Working Hours and Wealth (Clustering)
- Change in global work hours and national wealth over a 20 year period
    - Analyzed the global relationship between productivity (working hours) and national wealth (GDP per capita) from 1997 - 2017.
    - Comparing change in GDP per capita against change in work hours two different ways
        ![gdp_vs_work_plot](https://user-images.githubusercontent.com/37217825/151073299-9831d10e-822e-42c1-b07e-b179d7202818.png)
        - Using the raw change in GDP per capita (USD $) portrays a skewed picture. Seems to indicate that most countries reduced working hours and increased wealth by varying degrees, while nations who increased working hours did not gain as  much wealth.
        - This is not the best way to look at GDP per capita changes because does not apply appropriate scale to the gains poorer countries have had in wealth over the two decades.
        - Using the percentage change in GDP per capita better exemplifies the impact of working hours on wealth. Poorer countries were the ones to increase their working hours due to manufacturing being shifted to those locations, causing more than doubling of national wealth.
    - More detail examination of growth of GDP per capita (%) versus change in weekly hours worked
        - South & East Asian, and Eastern European countries have gotten exponentially richer while increasing working hours, mainly due to global shift in manufacturing to these geographic areas.
        - South America has  a paradox  where some countries (Argentina, Chile, Uruguay) have decreased working hours while some (Colombia, Peru) have increased working hours with both groups having relatively similar rise in GDP per capita growth
    - Clustering
        - Used K-Means clustering method to assess if I could determine better groupings. Hartigan’s rule test determined 8 groups to be ideal but I assessed clustering models using from 4 to 8 groups and determined 4 groups was ideal.
       ![cluster_plot](https://user-images.githubusercontent.com/37217825/151073381-b3d0576d-b641-49be-966d-12b431b17af1.png)
        - Grouping analysis:
            - 1. East Asian Economic Giants
                - Consists of Myanmar & China who both have very high working hours and have reach exponential GDP per capita growth
            - 2. Rich Work-Life Adjusters & New Middle Incomers
                - Consists of global rich countries (South Korea/Ireland/Malta/Singapore) that reduced work hours and countries that have recently become middle income
                    - Interesting to note that South Korea went from one of countries with the most working hours per week (1997)  to more in line with 40 hour work week (2017)
                - Other nations like Russia, Turkey, Philippines previously considered outside the middle income group have comfortably shifted into MI with massive economic changes.
            - 3. Diverse Economic Developers
                - Consists of South East Asian nations and Eastern European countries that have undertaken more conventional manufacturing jobs and lower-level IT work
                - Slight spread in change in weekly hours worked. Vietnam drop ~2.5 hours while Cambodia increased 5 hours.
            - 4. Steady (already rich) countries:
                - Countries would typically be associated with the OECD/developed economies.
