// C.2. Queries.
// 1. How many reviews does “Chilis Cuernavaca” have?

MATCH (p:Place {placeName:"Chilis Cuernavaca" })<-[r:RECEIVE_RATING]-()
RETURN count(r) AS reviewsCount

// 2. Show all place, cuisines, and service ratings for restaurants in “Morelos” state.

MATCH (p:Place)--()--(st:State)
WHERE st.state=~"(?i)Morelos"
OPTIONAL MATCH (p:Place)-[t:OFFER_CUISINE]->(c)
OPTIONAL MATCH (p:Place)<-[s:RECEIVE_RATING]-(ra)
RETURN p.placeId AS PlaceID, p.placeName AS PlaceName, c.cuisine AS Cuisines,
collect(ra.ratingService) AS ServiceRatings

// 3. Can you recommend places that user 1003 has never been but user 1033 have been
and gave ratings above 1?

MATCH (u:User)--(r:Rating)--(p)
WHERE u.userId = 1033 AND r.ratingPlace > 1 AND r.ratingFood > 1 AND
r.ratingService > 1
WITH collect(p.placeName) AS col1033
MATCH (u1:User)--(r1:Rating)--(p1)
WHERE u1.userId = 1003
WITH col1033, collect(p1.placeName) AS col1003
RETURN [n IN col1033 WHERE NOT n IN col1003] AS reccomendedPlaces

// 4. List all restaurant names and locations that do not provide Mexican cuisines.

// Index for cuisine
CREATE INDEX cuisine_index FOR (c:Cuisine) ON
(c.cuisine);

// Query
MATCH(p:Place)--(ci:City)--(st:State)--(co:Country)
OPTIONAL MATCH (p:Place)--(c:Cuisine)
WITH p,c,ci, st, co
WHERE NOT "Mexican" IN c.cuisine OR c IS NULL
RETURN p.placeName AS RestaurantName, p.streetAddress AS StreetAddress,
ci.city AS City, st.state AS State, co.country AS Country

// 5. Count how many times each user provides ratings.

MATCH(u:User)-[l:LEAVE_RATING]-()
WITH DISTINCT u,l AS rating
WITH u, count(rating) AS numberTimesProvideRating
RETURN u.userId AS user, numberTimesProvideRating

// 6. Display a list of pairs of restaurants having more than three features in common.

// composite index for restaurant features
CREATE INDEX place_features_index FOR (p:Place) ON
(p.alcohol, p.smokingArea, p.accessibility, p.franchise, p.area, p.otherServices)

// Query
MATCH (b:Budget)--(p:Place)--(d:DressCode),(b1:Budget)--(p1:Place)--(d1:DressCode)
WHERE p.placeId < p1.placeId
WITH b,p,d,b1,p1,d1, ['alcohol', 'smokingArea','accessibility','franchise','area','otherServices'] AS features
WITH b,p,d,b1,p1,d1, features, collect(b.budgetLevel) AS budget, collect(d.name) AS dress,
reduce(values = [], key IN features | values + p[key]) AS features1,
collect(b1.budgetLevel) AS budget1, collect(d1.name) AS dress1,
reduce(values = [], key IN features | values + p1[key]) AS features2
WITH p,p1,features1 + budget + dress AS place1, features2 + budget1 + dress1 AS place2
WITH p,p1, [x IN place1 where x IN place2] AS commonFeatures
WHERE size(commonFeatures) > 3
RETURN p1.placeName AS Restaurant1, p.placeName AS Restaurant2

// 7. Display International restaurants that are open on Sunday.

MATCH (o:OpeningHour)--(p:Place)--(c:Cuisine)
WHERE "International" IN c.cuisine AND "Sun" in o.day
RETURN p.placeName AS Restaurant

// 8. What is the average food rating for restaurants in Victoria city?

MATCH (r:Rating)--(p:Place)--(c:City)
WITH r,p,c
WHERE toLower(c.city) CONTAINS "victoria"
RETURN avg(r.ratingFood) AS avgFoodRatingVictoria

// 9. What are the top 3 most popular cities based on the total average service ratings?

MATCH (p:Place)--(c:City)
WITH p,c
MATCH (p)--(r:Rating)
WITH p,c,r
RETURN c.city AS City, avg(r.ratingService) AS averageServiceRating
ORDER BY averageServiceRating DESC LIMIT 3

// 10. For each place, rank other places that are close to each other by their locations.
// You will need to use the longitude and latitude to calculate the distance between places.

// composite index for location
CREATE INDEX place_location_index FOR (p:Place) ON
(p.locationLongitude, p.locationLatitude)

// query (to assign ranks, APOC library was used)
MATCH(p:Place)
WITH p, point({longitude:p.locationLongitude, latitude:p.locationLatitude}) AS location1
MATCH(pl:Place)
WITH location1, p, pl, point({longitude:pl.locationLongitude, latitude:pl.locationLatitude}) as location2
WHERE location1 <> location2
WITH p.placeName AS place1, pl.placeName AS place2, distance(location1,location2) AS distance
ORDER BY place1, distance ASC
WITH place1, collect(place2) as pl2
UNWIND pl2 as place
RETURN place1 AS Restaurant1, place AS Restaurant2, apoc.coll.indexOf(pl2, place) + 1 AS RankByDistance
