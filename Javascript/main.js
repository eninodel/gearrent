
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
    const oldSupplyCaches = new Parse.Query("SupplyCache");
    const newSupplyCaches = new Parse.Query("SupplyCache");
    oldSupplyCaches.containedIn("date", oldDates);
    oldSupplyCaches.equalTo("location", oldListing.get("location"));
    oldSupplyCaches.equalTo("categoryId", oldListing.get("categoryId"));
    newSupplyCaches.containedIn("date", newDates);
    newSupplyCaches.equalTo("location", newListing.get("location"))
    newSupplyCaches.equalTo("categoryId", newListing.get("categoryId"));
    const oldSupplyCachesResults = await oldSupplyCaches.find();
    const newSupplyCachesResults = await newSupplyCaches.find();
    const newDatesSet = new Set(newDates);
    const oldDatesSet = new Set(newDates);
    const oldSupplyCachesSet = new Set(oldSupplyCachesResults);
    const newSupplyCachesSet = new Set(newSupplyCachesResults);
    const oldCachesToDecrementSet = setDifference(oldSupplyCachesSet, newSupplyCachesSet);
    const newCachesToIncrementSet = setDifference(newSupplyCachesSet, oldSupplyCachesSet);
    console.log("oldCachesToDecrementSet: " + Array.from(oldCachesToDecrementSet).join(" "));
    console.log("newCachesToIncrementSet: " + Array.from(newCachesToIncrementSet).join(" "));
    oldCachesToDecrementSet.forEach((cache) =>{
      console.log("decrementing old cache: " + cache.get("date"));
      cache.decrement("available"); // decrement defaults to 1
      cache.save();
    });
    newCachesToIncrementSet.forEach((cache) => {
      console.log("incrementing new cache: " + cache.get("date"));
      newDatesSet.delete(cache.get("date"));
      cache.increment("available");
      cache.save();
    });
    // any dates left in newDatesSet are caches to create
    console.log("new dates set: " + Array.from(newDatesSet).join(" "));
    newDatesSet.forEach((cache) => {
       await createNewCache(newListing, date);
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
        await createNewCache(newListing, newDates[i]);
      } else{ // update cache
        console.log("updating cache");
        const cache = supplyCaches[0];
        cache.set("available", 1 + cache.get("available"));
        cache.save();
      }
    }

  }
})

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
  const _difference = new Set(setA);
  for (const elem of setB) {
    _difference.delete(elem);
  }
  return _difference;
}

function getDatesBetween(start, end) {
    for(var arr=[],dt=new Date(start); dt<=new Date(end); dt.setDate(dt.getDate()+1)){
        arr.push(new Date(dt));
    }
    return arr;
};


