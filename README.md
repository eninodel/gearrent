# Gear Rent

## Table of Contents
1. [Overview](#Overview)
1. [Product Spec](#Product-Spec)
1. [Wireframes](#Wireframes)
1. [Schema](#Schema)

## Overview
### Description
AirBnb for outdoor gear. Users can rent outdoor gear such as kayaks, climbing gear, bicycles, etc. from other users.

### App Evaluation
- **Category:** Lifestyle
- **Mobile:** This app would be primarily developed for mobile but would perhaps be just as viable on a computer. Current focus is on mobile.
- **Story:** Allows users to see rentable gear in their area and allows them to make reservations. Additionally users can add their own gear to be available for rent.
- **Market:** Any individual who wants to do outdoor activities but doen't have hte fund or means to acquire the gear to do so. Also for people who have unused gear looking to earn some extra cash.
- **Habit:** This app can be used everytime a user wants to do an outdoor activity but doesn't want to buy the gear outright.
- **Scope:** Start with allowing users to rent outdoor gear and then expand into other categories.

## Product Spec
### 1. User Stories (Required and Optional)

**Required Must-have Stories**

* User logs in and can customize profile
* User can see a list of rentable items that are available and use simple search filters
* User can create a listing for a rentable item they have
* User can see, update, and delete a listing they created previously
* User can reserve an item available for rent
* User can cancel a reservation
* User is notified if an item of theirs has a status update (is rented, renter canceled reservation, etc.)

**Optional Nice-to-have Stories**

* User rating (like FB Marketplace ratings)
* In app messaging for renters to communicate with lenders
* Allow listings with embedded videos
* Auto suggest a listing prices based on market demand (tell user to list an item for X amount because it’s trending at Y price)
* Integrate payments with Stripe
* Push notifications
* Ability to report listing for inappropriate content
* Dark mode support

### 2. Screen Archetypes

* Login
* Register - User signs up or logs into their account
  * add email verification
* Messaging Screen - Chat for users to communicate (direct 1-on-1)
   * Able to message users to ask for additional listing details and arange pick up and drop off
* Profile Screen 
   * Allows user to upload a photo and edit their information
* Checkout Screen
  * Allows a user to input payment information and reserve an item
* Settings Screen
   * Lets people change language, and app notification settings.
* Listings Screen
  * Main screen that displays listings available for rent
* Create Listing Screen
  * Allows a user to create a listing to be available for rent
* Bookings Screen
  * Able to see reservations for a user's listings and any reservations they have made
* User Listings Screen
   * Displays the listings for the current user

### 3. Navigation

**Tab Navigation** (Tab to Screen)

* Home
* Bookings
* My Listings
* Profile
* Messages

### Digital Wireframes & Mockups
<img src="https://user-images.githubusercontent.com/71790814/178362980-78e0fb73-5026-4f0f-b12a-cb03bbcad4fc.png" height=400>
<img src="https://user-images.githubusercontent.com/71790814/178362989-c85f3378-177c-4419-8dcb-c7d62c65f250.png" height=400>
<img src="https://user-images.githubusercontent.com/71790814/178362996-d6f241b9-9121-4651-b4a8-299f3843150c.png" height=500>

## Schema 
### Models
#### Listing

   | Property      | Type     | Description |
   | ------------- | -------- | ------------|
   | objectId      | String   | unique id for the item (default field) |
   | title         | String   | Title for the listing|
   | description   | String   | Listing description|
   | price         | float    | Price/day to rent the listing|
   | images        | PFFileObject array | Listing images|
   | videoURL      | String   | URL of listing video|
   | ownerId       | String   | objectId of the listing owner|
   | tags          | Tag array  | tags associated with the listing|
   | geoPoint      | PFGeoPoint  | Location of item|
   | city          | String    | city location of item|
   | reservations  | Reservation array | reservations associated with the current listing|
   | availabilities | TimeInterval array | date ranges representing the availability of a listing|
   
#### Reservation
   | Property      | Type     | Description |
   | ------------- | -------- | ------------|
   | objectId    | String  | unique id for the reservation (default field)|
   | itemId      | String  | objectId for the reserved item|
   | leaserId    | String  | objectId for the item leaser|
   | leaseeId    | String  | objectId for the item leasee|
   | dates       | TimeInterval | dates the item is reserved for|
   | status      | String  | status of the reservation (incoming, canceled, accepted, etc.)|
    
 #### TimeInterval
   | Property      | Type     | Description |
   | ------------- | -------- | ------------|
   | objectId    | String  | unique id for the TimeInterval (default field)|
   | startDate      | NSDate | interval start date|
   | endDate    | NSDate  | interval end date|
   
 #### Tag
   | Property      | Type     | Description |
   | ------------- | -------- | ------------|
   | objectId    | String  | unique id for the Tag (default field)|
   | parentId      | String | parent tage objectId|
   | description   | String  | tag description |
   | title         | String  | tag title |
