# Hubhacks

This is the [Vermonster](http://www.vermonster.com/) team's repository for [Hubhacks challenge](http://hubhacks2.challengepost.com/).

We are using [Tableau](http://www.tableau.com/) for the visualizations. In this repository, we are:
* adding links to the raw data we're using
* committing any data-munging scripts we write
* adding links to processed data for importing into Tableau
* adding graph screenshots and ideas for integrating the graphs into a flow, if it's useful

Take a look at our [Trello board](https://trello.com/b/ujpMKWdD/hubhacks), too.

## Our Project

Our project utilizes:

- [Runkeeper](http://runkeeper.com/)'s data on running and biking in Boston between 2010 and 2015
    * [Link to request the full runkeeper dataset](https://docs.google.com/forms/d/14tmXeophCx0yUKbFW24Ge9kqvBAL2AlbSaaoqyDO_dA/viewform?c=0&w=1)
- The [Boston Area Research Initiative](http://www.bostonarearesearchinitiative.net/data-library.php?dvn_subpage=/faces/study/StudyPage.xhtml?globalId=doi:10.7910/DVN/24713&studyListingIndex=0_793b56b69639262a4ff832a1af7c)'s Bicycle Collision dataset (between 2009 and 2012)
    * [Geocoded](https://s3-us-west-2.amazonaws.com/hubhacks/bike_collision_geo.csv)
- Boston Bike Network (http://maps.cityofboston.gov/bikenetwork/) dataset on bike lanes and when they were added or plan to be added (from 2009)
    * [Existing Bike Network](https://github.com/asross/hubhacks/blob/master/Existing_Bike_Network.json)

We are looking for insight into:

1. where do people run/bike, when, and what accounts for the differences?
2. what streets are most and least safe for biking?
3. what is the effect of adding a bike lane?
    * to total ridership?
    * to total collisions?
    * to collisions per biker?

## The Website

Now live on [Amazon](http://hubhacks-vermonster.s3-website-us-west-2.amazonaws.com/). We hope you find it useful!
