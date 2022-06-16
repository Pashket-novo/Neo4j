// C.3. Database Modifications.

// 1. MonR has gained some new information about a trendy new place. Therefore, insert
// all of the information provided in Table 1 (Assignment 2 case study).

// Check that information is not exist about new place in the database
MATCH (d:DressCode)--(p:Place {placeId: 70000})--(a:City)--(s:State)--(c:Country)
WITH d,p,a,s,c
MATCH (cu:Cuisine)--(p)--(pa:Payment)
WITH d,p,a,s,c,cu
MATCH (p)--(o:OpeningHour)
RETURN d,p,a,s,c,cu,o

// Insert the data for placeId: 70000
MERGE (p:Place {placeId: 70000})
  ON CREATE SET p.streetAddress = "Carretera Central Sn"
  ON CREATE SET p.placeName = "Taco Jacks"
  ON CREATE SET p.alcohol = "No_Alcohol_Served"
  ON CREATE SET p.smokingArea = "not permitted"
  ON CREATE SET p.accessibility = "completely"
  ON CREATE SET p.franchise = TRUE
  ON CREATE SET p.area = "open"
  ON CREATE SET p.otherServices = "Internet"
  ON CREATE SET p.parkingArragements = "none"
MERGE (a:City {city: "San Luis Potosi"})
MERGE (s:State {state: "SLP"})
MERGE (c:Country {country: "Mexico"})
MERGE (p)-[:LOCATED_AT]->(a)
MERGE (a)-[:BELONGS_TO]->(s)
MERGE (s)-[:PART_OF]->(c)
MERGE (d:DressCode {name: "informal"})
MERGE (p)-[:ALLOW_DRESS]->(d)
MERGE (b:Budget {budgetLevel: "medium"})
MERGE (p)-[:OFFER_PRICE]->(b)
MERGE (pa:Payment {type: ["any"]})
MERGE (p)-[:ACCEPT_PAYMENT]->(pa)
MERGE (cu:Cuisine {cuisine: split("Mexican, Burgers", ', ')})
MERGE (p)-[:OFFER_CUISINE]->(cu)
MERGE (o:OpeningHour {hour: ["09:00-20:00"], day: split("Mon;Tue;Wed;Thu;Fri;",';')})
MERGE (p)-[:HAS_HOURS]->(o)
MERGE (o1:OpeningHour {hour: ["12:00-18:00"], day: split("Sat; Sun;",';')})
MERGE (p)-[:HAS_HOURS]->(o1)

// Check the data after import
MATCH (d:DressCode)--(p:Place {placeId: 70000})--(a:City)--(s:State)--(c:Country)
WITH d,p,a,s,c
MATCH (cu:Cuisine)--(p)--(pa:Payment)
WITH d,p,a,s,c,cu
MATCH (p)--(o:OpeningHour)
RETURN d,p,a,s,c,cu,o

// Only place node for placeId: 70000
MATCH (p:Place {placeId: 70000})
RETURN p

// 2. They have also realised that the user with user_id 1108, no longer prefers Fast_Food
// and also prefers to pay using debit_cards instead of cash. You are required to update
// user 1108’s favorite cuisines and favorite payment methods.

// Information about user 1108 in the database
MATCH (c:Cuisine)<-[r:FAVOURITE_COUSINE]-(u:User {userId:1108})-[pr:PREFER_PAYMENT]-(p)
RETURN c,u,pr,p

// Update query
MATCH (c:Cuisine)<-[r:FAVOURITE_COUSINE]-(u:User {userId:1108})-[pr:PREFER_PAYMENT]-(p)
SET c.cuisine  = [x IN c.cuisine WHERE x <> "Fast_Food"]
SET p.type = ["debit_cards"] + [x IN p.type WHERE x <> "cash"]
RETURN c,u,pr,p

// 3. The management has realised that the user with user_id 1063 was an error. Therefore
// delete the user 1063 from the database.

// Information about user 1063 in the database
MATCH(u:User{userId:1063})
RETURN u

// Delete query
MATCH(u:User{userId:1063})
DETACH DELETE u

// Check if record deleted
MATCH (u:User{userId:1063})
RETURN u
