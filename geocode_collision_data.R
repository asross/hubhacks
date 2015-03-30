# Request Bicycle Collisions in Boston, MA (2009-2012) from BARI
# http://www.bostonarearesearchinitiative.net/data-library.php
# and rename the file to bike_collision.csv

# Run the code below inside the same directory as the csv file

crash <- read.csv("bike_collision.csv")

crash_address <- crash$Address
crash_district <- crash$PlanningDi
crash_district <- gsub('Allston/Brighton','Allston', crash_district)
crash_district <- gsub('Back Bay/Beacon Hill','Back Bay', crash_district)
crash_district <- gsub('Fenway/Kenmore','Fenway', crash_district)

crash_location <- paste(crash_address, crash_district, ", MA, USA")

# resolve ambiguous addresess
gsub("South End , MA", "South End, Boston, MA", crash_location)
gsub("Central , MA", "Central Boston , MA", crash_location)

# load the ggmap library to geocode the addresses
library(ggmap)
crash_coordinate <- geocode(crash_location)
write.csv(crash_coordinate, "crash_coordinates.csv")

# latitude and longitude data can be combined manually with the
# data sets for bike paths and runkeeper routes data