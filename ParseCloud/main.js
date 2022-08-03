
// The example below shows you how a cloud code function looks like.

/* Parse Server 3.x
* Parse.Cloud.define("hello", (request) => {
* 	return("Hello world!");
* });
*/

/* Parse Server 2.x
* Parse.Cloud.define("hello", function(request, response){
* 	response.success("Hello world!");
* });
*/

// To see it working, you only need to call it through SDK or REST API.
// Here is how you have to call it via REST API:co

/** curl -X POST \
* -H "X-Parse-Application-Id: vmgU8MNHBekVm2Ta8nF5pNNV04vABaIqMSdBzPFR" \
* -H "X-Parse-REST-API-Key: Husz7E8zLgczMqNGMlSAszMGS1n37gpPGnsXxaMz" \
* -H "Content-Type: application/json" \
* -d "{}" \
* https://parseapi.back4app.com/functions/hello
*/

// If you have set a function in another cloud code file, called "test.js" (for example)
// you need to refer it in your main.js, as you can see below:

/* require("./test.js"); */


Parse.Cloud.define("getListingsWithGeohashes", async (request) => {
  const promises = [];
  const n = request.params.geohashes.length;
  for(let i = 0; i < n; i ++){
    const query = new Parse.Query("Listing");
    const geohash = request.params.geohashes[i];
    query.startsWith("geohash", geohash);
    promises.push(query.find()); //making a list of promises
  }
  try{
      let result = await Promise.all(promises);
    return result;
  } catch(error){
    throw error;
  }

})

Parse.Cloud.beforeDelete("Listing", async(request) => {
  const listing = request.object;
  const datesAvailable = await getDatesAvailable(listing);
  console.log("[Delete] Dates available to decrement: " + datesAvailable);
  const caches = await getCaches(datesAvailable, listing.get("location"), listing.get("categoryId"));
  console.log("[Delete] Caches affected: " + JSON.stringify(caches));
  const confirmedReservations = await fetchConfirmedReservations(listing);
  const reservedDateSet = new Set();
  for(let i = 0; i < confirmedReservations.length; i ++){
    const reservation = confirmedReservations[i];
    const dates = getDatesBetween(reservation.get("dates").get("startDate"), reservation.get("dates").get("endDate"));
    for(date in dates){
      reservedDateSet.add(date.getTime());
    }
  }
  for(let i = 0;i < caches.length; i ++){
    const cache = caches[i];
    console.log("Decrementing cache: " + cache.id);
    cache.decrement("available");
    if(cache.get("date").getTime() in reservedDateSet){
      cache.decrement("reserved");
    }
    cache.save();
  }
})

Parse.Cloud.beforeSave("Reservation", async (request) => {
  const reservation = request.object;
    console.log("[Before Save Reservation] reservation status: " + reservation.get("status"));
  const listingQuery = new Parse.Query("Listing");
  listingQuery.equalTo("objectId", reservation.get("itemId"));
  const queryResult = await listingQuery.find();
  const listing = queryResult[0];
  const timeIntervalQuery = new Parse.Query("TimeInterval");
  timeIntervalQuery.equalTo("objectId", reservation.get("dates").id);
  const timeIntervalQueryResult = await timeIntervalQuery.find();
  const timeInterval = timeIntervalQueryResult[0];
  const datesReserved = getDatesBetween(timeInterval.get("startDate"), timeInterval.get("endDate"));
  const caches = await getCaches(datesReserved, listing.get("location"), listing.get("categoryId"));
  for(let i = 0; i < caches.length; i ++){
    const cache = caches[i];
    console.log("[Before Save Reservation] Cache: " + JSON.stringify(cache));
    if(reservation.get("status") === "CONFIRMED"){
      cache.increment("reserved");
      cache.save();
    } else if(reservation.get("status") === "DECLINED"){
      cache.decrement("available");
      cache.save();
    }
  }
})

Parse.Cloud.beforeSave("Listing", async (request) => {
  const availabilitiesPromises = [];
  const newListing = request.object;
  const newDates = await getDatesAvailable(newListing);
  console.log("new dates: " + newDates);
  if(!newListing.isNew()){ // listing was updated
    // get all caches from old data and available caches with new data
    console.log("updated listing");
    const oldListing = request.original;
    const oldDates = await getDatesAvailable(oldListing);
    console.log("old dates: " + oldDates);
    
    const oldSupplyCachesResults = await getCaches(oldDates, oldListing.get("location"), oldListing.get("categoryId"));
    const newSupplyCachesResults = await getCaches(newDates, newListing.get("location"), newListing.get("categoryId"));
    
    const newDatesSet = datesToSet(newDates);
    const oldDatesSet = datesToSet(oldDates);
    const dateObject = datesToObject(oldDates.concat(newDates));
    
    const oldSupplyCachesSet = cachesToObjectIdSet(oldSupplyCachesResults);
    const newSupplyCachesSet = cachesToObjectIdSet(newSupplyCachesResults);
    
    const oldCachesToDecrementSet = setDifference(oldSupplyCachesSet, newSupplyCachesSet);
    // const newCachesToIncrementSet = setDifference(newSupplyCachesSet, oldSupplyCachesSet);
    
    console.log("oldCachesToDecrementSet: " + JSON.stringify(oldCachesToDecrementSet));
    // console.log("newCachesToIncrementSet: " + JSON.stringify(newCachesToIncrementSet));
    
    const objectIdToCache = cachesToObjectIdObject(oldSupplyCachesResults.concat(newSupplyCachesResults));
    console.log("objectIdToCache: " + JSON.stringify(objectIdToCache));
    
    oldCachesToDecrementSet.forEach((objectId) =>{
      console.log("decrementing old cache: " + objectId);
      const cache = objectIdToCache[objectId];
      cache.decrement("available"); // decrement defaults to 1
      cache.save();
    });
    newSupplyCachesSet.forEach((objectId) => {
      const cache = objectIdToCache[objectId];
      if(!cache.get("date").getTime() in oldDatesSet){ // not in old dates so need to increment
        console.log("incrementing new cache: " + objectId);
        cache.increment("available");
        cache.save();
      }
      console.log("deleting " + cache.get("date") + " from newDatesSet");
      newDatesSet.delete(cache.get("date").getTime());
      console.log("newDatesSet :" + Array.from(newDatesSet).join(" "));
    });
    // any dates left in newDatesSet are caches to create
    console.log("new dates set: " + Array.from(newDatesSet).join(" "));
    newDatesSet.forEach((time) => {
      const date = dateObject[time];
      createNewCache(newListing, date);
    });
  } else{ //newly created listing
    // increment supply available for location and dates
    console.log("created new listing");
    for(let i = 0; i < newDates.length; i ++){
      const supplyCacheQuery = new Parse.Query("SupplyCache");
      supplyCacheQuery.equalTo("date", newDates[i]);
      supplyCacheQuery.equalTo("location", newListing.get("location"));
      supplyCacheQuery.equalTo("categoryId", newListing.get("categoryId"));
      const supplyCaches = await supplyCacheQuery.find();
      if(supplyCaches.length == 0){// no cache exists, create cache
        createNewCache(newListing, newDates[i]);
      } else{ // update cache
        const cache = supplyCaches[0];
        console.log("updating cache: " + cache.id);
        cache.set("available", 1 + cache.get("available"));
        cache.save();
      }
    }

  }
})

async function fetchConfirmedReservations(listing){
  const query = new Parse.Query("Reservation");
  query.equalTo("status", "CONFIRMED");
  query.equalTo("itemId", listing.id);
  query.include("dates");
  return query.find();
}

function datesToObject(dates){
  const result = {};
  for(let i = 0; i < dates.length; i++){
    result[dates[i].getTime()] = dates[i];
  }
  return result;
}

function datesToSet(dates){
  const result = new Set();
  for(let i = 0; i < dates.length; i++){
    result.add(dates[i].getTime());
  }
  return result;
}

function cachesToObjectIdObject(caches){
  const map = {}
  for(let i = 0; i < caches.length; i++){
      map[caches[i].id] = caches[i];
  }
  return map;
}

function cachesToObjectIdSet(caches){
  const resultSet = new Set();
  for(let i = 0; i < caches.length; i++){
    resultSet.add(caches[i].id);
  }
  return resultSet;
}

async function getCaches(dates, location, categoryId){
    const query = new Parse.Query("SupplyCache");
    query.containedIn("date", dates);
    query.equalTo("location", location);
    query.equalTo("categoryId", categoryId);
    return query.find();
}

async function createNewCache(listing, date){
  try{
    const SupplyCache = Parse.Object.extend("SupplyCache");
    const newCache = new SupplyCache();
    newCache.set("date", date);
    newCache.set("location", listing.get("location"));
    newCache.set("categoryId",listing.get("categoryId"));
    newCache.set("available", 1);
    newCache.set("reserved", 0);
    console.log("creating new cache: " + date);
    await newCache.save();
  }catch(error){
    throw error;
  }
}

async function getDatesAvailable(listing){
  const availabilitiesPointers = listing.get("availabilities");
  const availabilitiesPromises = [];
  for(let i = 0; i < availabilitiesPointers.length; i ++){
    const availabilityId = availabilitiesPointers[i].id;
    const query = new Parse.Query("TimeInterval");
    query.equalTo("objectId", availabilityId);
    availabilitiesPromises.push(query.find());
  }
  let availabilityTimeIntervals = [];
  try{
    availabilityTimeIntervals = await Promise.all(availabilitiesPromises);
  }catch(error){
    throw error;
  }
  const newDates = [];
  for(let i = 0; i < availabilityTimeIntervals.length; i ++){
    const timeInterval = availabilityTimeIntervals[i][0];
    const start = timeInterval.get("startDate");
    const end = timeInterval.get("endDate");
    const datesBetween = getDatesBetween(start, end);
    for(let j = 0; j < datesBetween.length; j ++){
      newDates.push(datesBetween[j]);
    }
  }
  return newDates;
}

function setDifference(setA, setB) {
  const difference = new Set(setA);
  for (const elem of setB) {
    difference.delete(elem);
  }
  return difference;
}

function getDatesBetween(start, end) {
    for(var arr=[],dt=new Date(start); dt<=new Date(end); dt.setDate(dt.getDate()+1)){
        arr.push(new Date(dt));
    }
    return arr;
};


