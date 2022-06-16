// C.1. Database Design.

// Import data from the CSV files and ensure that the imported data represent your
// identified nodes and edges.

// Check the database for the existing data
MATCH (n) RETURN n;

// User node
LOAD CSV WITH HEADERS FROM "file:///userProfile.csv"
AS row
WITH row WHERE row._id IS NOT NULL
MERGE (u:User {userId: toInteger(row._id)})
  ON CREATE SET u.locationLatitude = toFloat(row.`location latitude`)
  ON CREATE SET u.locationLongitude = toFloat(row.`location longitude`)
  ON CREATE SET u.birthYear = toInteger(row.`personalTraits birthYear`)
  ON CREATE SET u.weight = toInteger(row.`personalTraits weight`)
  ON CREATE SET u.height = toFloat(row.`personalTraits height`)
  ON CREATE SET u.maritalStatus = row.`personalTraits maritalStatus`
  ON CREATE SET u.interest = row.`personality interest`
  ON CREATE SET u.typeOfWorker = row.`personality typeOfWorker`
  ON CREATE SET u.favColor = row.`personality favColor`
  ON CREATE SET u.drinkLevel = row.`personality drinkLevel`
  ON CREATE SET u.smoker = toBoolean(row.`preferences smoker`)
  ON CREATE SET u.ambience = row.`preferences ambience`
  ON CREATE SET u.transport = row.`preferences transport`
  ON CREATE SET u.religion = row.`otherDemographics religion`
  ON CREATE SET u.employment = row.`otherDemographics employment`

// Check the imported data:
MATCH (u:User) RETURN u

// Place node
LOAD CSV WITH HEADERS FROM "file:///places.csv"
AS row
WITH row WHERE row._id IS NOT NULL
MERGE (p:Place {placeId: toInteger(row._id)})
  ON CREATE SET p.placeName = row.placeName
  ON CREATE SET p.locationLatitude = toFloat(row.`location latitude`)
  ON CREATE SET p.locationLongitude = toFloat(row.`location longitude`)
  ON CREATE SET p.streetAddress = row.`address street`
  ON CREATE SET p.alcohol = row.`placeFeatures alcohol`
  ON CREATE SET p.smokingArea = row.`placeFeatures smoking_area`
  ON CREATE SET p.accessibility = row.`placeFeatures accessibility`
  ON CREATE SET p.franchise = (case row.`placeFeatures franchise` when "t" then true else false end)
  ON CREATE SET p.area = row.`placeFeatures area`
  ON CREATE SET p.otherServices = row.`placeFeatures otherServices`
  ON CREATE SET p.parkingArragements = row.parkingArragements

// Check the imported data
MATCH (p:Place) RETURN p

// OpeningHour node and [:HAS_HOURS] edge
LOAD CSV WITH HEADERS FROM "file:///openingHours.csv"
AS row
WITH row WHERE row.placeID IS NOT NULL
MATCH (p:Place {placeId: toInteger(row.placeID)})
MERGE (o:OpeningHour {hour: split(row.hours,';'), day: split(row.days,';')})
MERGE (p)-[:HAS_HOURS]->(o)

// Check the imported data
MATCH (o:OpeningHour) RETURN o

// Check the imported data
MATCH (o:OpeningHour)--(p:Place)
RETURN o,p

// City, State, Country nodes and [:LOCATED_AT], [:BELONGS_TO], [:PART_OF] edges
LOAD CSV WITH HEADERS FROM "file:///places.csv"
AS row
WITH row WHERE row._id IS NOT NULL
MATCH (p:Place {placeId: toInteger(row._id)})
MERGE (c:City {city: row.`address city`})
MERGE (s:State {state: row.`address state`})
MERGE (co:Country {country: row.`address country`})
MERGE (p)-[:LOCATED_AT]->(c)
MERGE (c)-[:BELONGS_TO]->(s)
MERGE (s)-[:PART_OF]->(co)

// Check the imported data
MATCH(c:City)--(s:State)--(co:Country)
RETURN c, s, co

// Check the imported data
MATCH(p:Place)--(c:City)--(s:State)--(co:Country)
RETURN p, c, s, co

// Budget node and [:OFFER_PRICE] edge
LOAD CSV WITH HEADERS FROM "file:///places.csv"
AS row
WITH row WHERE row._id IS NOT NULL
MATCH (p:Place {placeId: toInteger(row._id)})
MERGE (b:Budget {budgetLevel: row.`placeFeatures price`})
MERGE (p)-[:OFFER_PRICE]->(b)

// Check the imported data
MATCH (b:Budget) RETURN b

// Check the imported data
MATCH (p:Place)--(b:Budget)
RETURN p,b

// Cuisine node and [:OFFER_CUISINE] edge
LOAD CSV WITH HEADERS FROM "file:///places.csv"
AS row
WITH row WHERE row._id IS NOT NULL AND row.cuisines IS NOT NULL
MATCH (p:Place {placeId: toInteger(row._id)})
MERGE (c:Cuisine {cuisine: split(row.cuisines, ', ')})
MERGE (p)-[:OFFER_CUISINE]->(c)

// Check the imported data
MATCH(c:Cuisine) RETURN c

// Check the imported data
MATCH(c:Cuisine)--(p:Place)
RETURN c,p

// DressCode node and [:ALLOW_DRESS] edge
LOAD CSV WITH HEADERS FROM "file:///places.csv"
AS row
WITH row WHERE row._id IS NOT NULL
MATCH (p:Place {placeId: toInteger(row._id)})
MERGE (d:DressCode {name: row.`placeFeatures dress_code`})
MERGE (p)-[:ALLOW_DRESS]->(d)

// Check the imported data
MATCH (d:DressCode) RETURN d

// Check the imported data
MATCH (d:DressCode)--(p:Place)
RETURN d,p

// Payment node and [:ACCEPT_PAYMENT] edge
LOAD CSV WITH HEADERS FROM "file:///places.csv"
AS row
WITH row WHERE row._id IS NOT NULL
MATCH (p:Place {placeId: toInteger(row._id)})
MERGE (pa:Payment {type: split(row.`acceptedPaymentModes`,', ')})
MERGE (p)-[:ACCEPT_PAYMENT]->(pa)

// Check the imported data
MATCH(pa:Payment) RETURN pa

// Check the imported data
MATCH(pa:Payment)--(p:Place)
RETURN pa,p

// Rating node and [:LEAVE_RATING], [:RECEIVE_RATING] edges
LOAD CSV WITH HEADERS FROM "file:///place_ratings.csv"
AS row
WITH row WHERE row.rating_id IS NOT NULL
MATCH (u:User {userId: toInteger(row.user_id)})
MATCH (p:Place {placeId: toInteger(row.place_id)})
MERGE (r:Rating {ratingId: toInteger(row.rating_id)})
  ON CREATE SET r.ratingPlace = toInteger(row.rating_place)
  ON CREATE SET r.ratingFood = toInteger(row.rating_food)
  ON CREATE SET r.ratingService = toInteger(row.rating_service)
MERGE (u)-[:LEAVE_RATING]->(r)
MERGE (p)<-[:RECEIVE_RATING]-(r)

// Check the imported data
MATCH(r:Rating) RETURN r

// Check the imported data
MATCH(u:User)--(r:Rating)--(p:Place)
RETURN u,r,p

// Payment node and [:PREFER_PAYMENT] edge
LOAD CSV WITH HEADERS FROM "file:///userProfile.csv"
AS row
WITH row WHERE row._id IS NOT NULL AND row.favPaymentMethod IS NOT NULL
MATCH (u:User {userId: toInteger(row._id)})
MERGE (pa:Payment {type: split(row.favPaymentMethod,', ')})
MERGE (u)-[:PREFER_PAYMENT]->(pa)

// Check the imported data
MATCH (u:User)--(pa:Payment)
RETURN u,pa

// DressCode node and [:PREFER_DRESS] edge
LOAD CSV WITH HEADERS FROM "file:///userProfile.csv"
AS row
WITH row WHERE row._id IS NOT NULL AND row.`preferences dressPreference` IS NOT NULL
MATCH (u:User {userId: toInteger(row._id)})
MERGE (d:DressCode {name: row.`preferences dressPreference`})
MERGE (u)-[:PREFER_DRESS]->(d)

// Check the imported data
MATCH(d:DressCode)--(u:User)
RETURN d, u

// Cuisine node and [:FAVOURITE_COUSINE] edge
LOAD CSV WITH HEADERS FROM "file:///userProfile.csv"
AS row
WITH row WHERE row._id IS NOT NULL
MATCH (u:User {userId: toInteger(row._id)})
MERGE (c:Cuisine {cuisine: split(row.favCuisines, ', ')})
MERGE (u)-[:FAVOURITE_COUSINE]->(c)

// Check the imported data
MATCH(u:User)--(c:Cuisine)
RETURN u,c

// Budget node and [:PREFER_BUDGET] edge
LOAD CSV WITH HEADERS FROM "file:///userProfile.csv"
AS row
WITH row WHERE row._id IS NOT NULL AND row.`preferences budget` IS NOT NULL
MATCH (u:User {userId: toInteger(row._id)})
MERGE (b:Budget {budgetLevel: row.`preferences budget`})
MERGE (u)-[:PREFER_BUDGET]->(b)

// Check the imported data
MATCH (u:User)--(b:Budget)
RETURN u, b

// Check all nodes and edges in the database
MATCH (n) RETURN n;
