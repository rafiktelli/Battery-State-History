# Battery-State-History
Battery state history is a tool for Windows to plot the battery level variation during a period of time.
In order to fetch the Battery level (percentage) in every minute, I wrote a #Batchfile script using windows command lines. 
For ploting the graph of Battery level changes I used #Visual-Basic-Script-VBS.
This tool also plots the state of the computer in every minute, whether the charger is charger plugged or not, when the laptop is plugged; the blue graph is upon the varation graph in the given minute, otherwise the blue graph is under the variation graph.

<br>

For every period of observation, a .png file of the graph is saved with a .csv file that stores the data. All the observations are stored in a directory called " Battery State History ", each observation is saved in a child folder that contains the graph and the csv file.    

<br><br>
![2020-07-04_0h19](https://user-images.githubusercontent.com/38439929/127409633-b3ec21ea-1878-463e-bc69-358ee44a5ed6.png)
