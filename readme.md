[![Build Status](https://travis-ci.org/coldbox-modules/cbox-forgeboxSDK.svg?branch=master)](https://travis-ci.org/coldbox-modules/cbox-forgeboxSDK)

# WELCOME TO THE COLDBOX FRESHBOOKS MODULE

This module will connect your ColdBox applications to the Freshbooks API (https://www.freshbooks.com/developers)

## LICENSE
Apache License, Version 2.0.

## IMPORTANT LINKS
- https://github.com/coldbox-modules/cbox-freshbooksSDK
- https://forgebox.io/view/cbfreshbooks
- [Changelog](changelog.md)

## SYSTEM REQUIREMENTS
- Lucee 4.5+
- ColdFusion 10+

# INSTRUCTIONS

Just drop into your **modules** folder or use CommandBox to install

`box install cbfreshbooks`

## Settings

Create a `cbfreshbooks` struct inside of your `config/Coldbox.cfc` under the `moduleSettings` configuration structure. Below are the following settings for this module:


```js
// Module Settings
moduleSettings = {
    // Freshbooks Module Settings
    cbfreshbooks = {
		// The Freshbooks client ID and Client secret
		APIToken.clientID = "",
		APIToken.clientSecret = "",
		//Authorization code obtained manually after allowing the access to the FreshBooks application (Authorization link is required)
		APIToken.authorizationCode = "",
		APIURL = "https://api.freshbooks.com/auth/oauth/token/",
		authLink = "https://my.freshbooks.com/service/auth/oauth/",
		redirectURI = ""
    }
};
```

## WireBox Mappings

The module will register the sdk for you as:

* `SDK@cbfreshbooks`

## Implemented Endpoints

* Authentication
* Categories
* Clients
* Estimates
* Invoices
* Items
* Projects
* Recurring
* System
* Time Entries
* Reports



********************************************************************************
Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************
####HONOR GOES TO GOD ABOVE ALL
Because of His grace, this project exists. If you don't like this, then don't read it, its not for you.

>"Therefore being justified by faith, we have peace with God through our Lord Jesus Christ:
By whom also we have access by faith into this grace wherein we stand, and rejoice in hope of the glory of God.
And not only so, but we glory in tribulations also: knowing that tribulation worketh patience;
And patience, experience; and experience, hope:
And hope maketh not ashamed; because the love of God is shed abroad in our hearts by the 
Holy Ghost which is given unto us. ." Romans 5:5

###THE DAILY BREAD
 > "I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12