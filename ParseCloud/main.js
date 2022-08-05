Parse.Cloud.define("getListingsWithGeohashes", async (request) => {
  const promises = [];
  const n = request.params.geohashes.length;
  for(let i = 0; i < n; i ++){
    const query = new Parse.Query("Listing");
    const geohash = request.params.geohashes[i];
    query.startsWith("geohash", geohash);
    promises.push(query.find());
  }
  try{
      let result = await Promise.all(promises);
    return result;
  } catch(error){
    throw error;
  }
})

Parse.Cloud.define("getDynamicPricesForRangeOfDates", async(request) => {
  const location = request.params.location;
  const categoryId = request.params.categoryId;
  const listingId = request.params.listingId;
  const minPrice = request.params.minPrice;
  const dateRanges = request.params.dates;
  let dates = [];
  const cachePromises = [];
  for (let i = 0; i < dateRanges.length; i++){
    const dateRange = dateRanges[i];
    const startDate = new Date (dateRange[0] * 1000);
    const endDate = new Date(dateRange[1] * 1000);
    dates = dates.concat(getDatesBetween(startDate, endDate));
    const cacheQuery = new Parse.Query("SupplyCache");
    cacheQuery.equalTo("location", location);
    cacheQuery.equalTo("categoryId", categoryId);
    cachePromises.push(cacheQuery.find());
  }
  try{
    let cacheResults = await Promise.all(cachePromises);
    const dateToSupplyFactor = {};
    for (let i = 0; i < cacheResults.length; i ++){
      const cacheRange = cacheResults[i];
      for(let j = 0; j < cacheRange.length; j++){
        const cache = cacheRange[j];
        dateToSupplyFactor[cache.get("date").getTime()] = cache.get("available") <= 0? 0 : cache.get("reserved") / cache.get("available");
      }
    }
    const oneDayAgo = addDays(new Date(), -1 );
    const searchesQuery = new Parse.Query("Filter");
    searchesQuery.equalTo("location", location);
    searchesQuery.equalTo("categoryId", categoryId);
    searchesQuery.greaterThanOrEqualTo("createdAt", oneDayAgo);
    const searchesQueryResults = await searchesQuery.find();
    const reservationQuery = new Parse.Query("Reservation");
    reservationQuery.equalTo("itemId", listingId);
    reservationQuery.greaterThanOrEqualTo("createdAt", oneDayAgo);
    const reservationQueryResults = await reservationQuery.find();
    const dateToDynamicPrice = {};
    for(let i = 0; i < dates.length; i++){
      const date = dates[i];
      const weekendSurcharge = ([0,6].indexOf(date.getDay()) != -1) ? 0.05 : 0.0;
      const holidaySurcharge = isBankHoliday(date) ? 0.05 : 0.0;
      const numSearches = searchesQueryResults.length;
      const numReservations = reservationQueryResults.length;
      const searchesSurcharge = 0.15 * (numSearches / (1 + numSearches));
      const reservationSurcharge = 0.5 * (numReservations / (1 + numReservations));
      const supplySurcharge = 0.25 * dateToSupplyFactor[date.getTime()];
      const dynamicPrice = minPrice * (1 + weekendSurcharge + holidaySurcharge + searchesSurcharge + reservationSurcharge + supplySurcharge);
      dateToDynamicPrice[date.getTime()] = dynamicPrice;
    }
    return dateToDynamicPrice;
  } catch(error){
    throw error;
  }
})

Parse.Cloud.beforeDelete("Listing", async(request) => {
  const listing = request.object;
  const datesAvailable = await getDatesAvailable(listing);
  let caches = [];
  if(listing.get("isAlwaysAvailable")){
    caches = await getIsAlwaysAvailableCaches(listing.get("location"), listing.get("categoryId"));
  } else{
    caches = await getCaches(datesAvailable, listing.get("location"), listing.get("categoryId"));
  }
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
    cache.decrement("available");
    if(cache.get("date").getTime() in reservedDateSet){
      cache.decrement("reserved");
    }
    cache.save();
  }
})

Parse.Cloud.beforeSave("Reservation", async (request) => {
  const reservation = request.object;
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
    if(reservation.get("status") === "CONFIRMED"){
      cache.increment("reserved");
      cache.save();
    } else if(reservation.get("status") === "DECLINED"){
      cache.decrement("reserved");
      cache.save();
    }
  }
})

Parse.Cloud.beforeSave("Listing", async (request) => {
  const availabilitiesPromises = [];
  const newListing = request.object;
  const newDates = await getDatesAvailable(newListing);
  if(!newListing.isNew()){ // listing was updated
    const oldListing = request.original;
    const oldDates = await getDatesAvailable(oldListing);
    let newDatesSet = datesToSet(newDates);
    let oldDatesSet = datesToSet(oldDates);
    let dateObject = datesToObject(oldDates.concat(newDates));
    let oldSupplyCachesResults = [];
    let newSupplyCachesResults = [];
    if(newListing.get("isAlwaysAvailable") &&oldListing.get("isAlwaysAvailable")){
      if(newListing.get("location") == oldListing.get("location")
      && newListing.get("categoryId") == oldListing.get("categoryId")){
        return;
      }
      oldSupplyCachesResults = await getIsAlwaysAvailableCaches(oldListing.get("location"), oldListing.get("categoryId"));
      newSupplyCachesResults = await getIsAlwaysAvailableCaches(newListing.get("location"), newListing.get("categoryId"));
    } else if (newListing.get("isAlwaysAvailable")){ 
        const dates = isAlwaysAvailableDates();
        newDatesSet = datesToSet(dates);
        dateObject = datesToObject(oldDates.concat(dates));
        newSupplyCachesResults = await getIsAlwaysAvailableCaches(newListing.get("location"), newListing.get("categoryId"));
        oldSupplyCachesResults = await getCaches(oldDates, oldListing.get("location"), oldListing.get("categoryId"));
    } else if (oldListing.get("isAlwaysAvailable")){
      oldSupplyCachesResults = await getIsAlwaysAvailableCaches(oldListing.get("location"), oldListing.get("categoryId"));
      newSupplyCachesResults = await getCaches(newDates, newListing.get("location"), newListing.get("categoryId"));
    } else{
      oldSupplyCachesResults = await getCaches(oldDates, oldListing.get("location"), oldListing.get("categoryId"));
      newSupplyCachesResults = await getCaches(newDates, newListing.get("location"), newListing.get("categoryId"));
    }
    const oldSupplyCachesSet = cachesToObjectIdSet(oldSupplyCachesResults);
    const newSupplyCachesSet = cachesToObjectIdSet(newSupplyCachesResults);
    const oldCachesToDecrementSet = setDifference(oldSupplyCachesSet, newSupplyCachesSet);
    const objectIdToCache = cachesToObjectIdObject(oldSupplyCachesResults.concat(newSupplyCachesResults));
    oldCachesToDecrementSet.forEach((objectId) =>{
      const cache = objectIdToCache[objectId];
      cache.decrement("available");
      cache.save();
    });
    newSupplyCachesSet.forEach((objectId) => {
      const cache = objectIdToCache[objectId];
      const currentCacheTime = cache.get("date").getTime();
      if(!oldDatesSet.has(currentCacheTime) || oldListing.get("isAlwaysAvailable")){
        cache.increment("available");
        cache.save();
      }
      newDatesSet.delete(cache.get("date").getTime());
    });
    newDatesSet.forEach((time) => {
      const date = dateObject[time];
      createNewCache(newListing, date);
    });
  } else{ 
    if(newListing.get("isAlwaysAvailable")){
      const dates = isAlwaysAvailableDates();
      const dateSet = datesToSet(dates);
      const dateObject = datesToObject(dates);
      const caches = await getIsAlwaysAvailableCaches(newListing.get("location"), newListing.get("categoryId"));
      for(let i = 0; i < caches.length; i++){
        const cache = caches[i];
        cache.increment("available");
        dateSet.delete(cache.get("date").getTime());
        cache.save();
      }
      dateSet.forEach((time) => {
        createNewCache(newListing, dateObject[time]);
      })
    }
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


function isAlwaysAvailableDates(){
  const today = new Date();
  today.setMinutes(0);
  today.setHours(7);
  today.setMilliseconds(0);
  today.setSeconds(0);
  const thirtyDaysInFuture = addDays(today, 90);
  return getDatesBetween(today, thirtyDaysInFuture);
}

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

async function getIsAlwaysAvailableCaches(location, categoryId){
  const query = new Parse.Query("SupplyCache");
  query.equalTo("location", location);
  query.equalTo("categoryId", categoryId);
  const today = new Date();
  today.setMinutes(0);
  today.setHours(7);
  today.setMilliseconds(0);
  today.setSeconds(0);
  query.greaterThanOrEqualTo("date", today);
  return query.find();
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

function addDays(date, days) {
  var result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
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

function isBankHoliday(date) {
    const isDate = (d, month, date) => {
        return d.getMonth() == (month - 1) && d.getDate() == date;
    };
    if (isDate(date, 1, 1)) { return "New Year"; }
    else if (isDate(date, 7, 4)) { return "Independence Day"; }
    else if (isDate(date, 11, 11)) { return "Veterans Day"; }
    else if (isDate(date, 12, 25)) { return "Christmas Day"; }
    const isDay = (d, month, day, occurance) => {
        if (d.getMonth() == (month - 1) && d.getDay() == day) {
            if (occurance > 0) {
                return occurance == Math.ceil(d.getDate() / 7);
            } else {
                // check last occurance
                let _d = new Date(d);
                _d.setDate(d.getDate() + 7);
                return _d.getMonth() > d.getMonth();
            }
        }
        return false;
    };
    if (isDay(date, 1, 1, 3)) { return "MLK Day"; }
    else if (isDay(date, 2, 1, 3)) { return "Presidents Day"; }
    else if (isDay(date, 5, 1, -1)) { return "Memorial Day"; }
    else if (isDay(date, 9, 1, 1)) { return "Labor Day"; }
    else if (isDay(date, 10, 1, 2)) { return "Columbus Day"; }
    else if (isDay(date, 11, 4, 4)) { return "Thanksgiving Day"; }
    if (date.getDay() == 0) { return "Sunday"; }
    else if (date.getDay() == 6) { return "Saturday" }
    return "";
}
