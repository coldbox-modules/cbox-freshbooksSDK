/**
* This is the Freshbooks SDK class
*/
component accessors=true singleton threadsafe{
	
	/**
	 * The module settings
	 */
	property name="settings";


	/**
	 * The client ID
	 */
	property name="clientID";
	property name="clientSecret";

	/**
	 * Access token and refresh token
	 */
	property name="tokenAccess" default="";
	property name="refreshToken" default="";

	/**
	 * Authorization code
	 */
	property name="authorizationCode";

	/**
	 * APIURL, Authorization link, and the redirect URI
	 */
	property name="APIURL";
	property name="authLink";
	property name="redirectURI";

	/**
	 * 
	 */
	property name="identityInformation";

	// DI
	property name="log" inject="logbox:logger:{this}";

	/**
	* Constructor
	* @settings The module settings
	* @settings.inject coldbox:modulesettings:cbfreshbooks
	*/
	function init( settings ){
		variables.settings = arguments.settings;
		variables.APIURL = arguments.settings.APIURL;
		variables.authLink = arguments.settings.authLink;
		variables.redirectURI = arguments.settings.redirectURI;
		variables.clientID = arguments.settings.APIToken.clientID;
		variables.clientSecret = arguments.settings.APIToken.clientSecret;
		variables.authorizationCode = arguments.settings.APIToken.authorizationCode;

		return this;
	}

	/**
	 * Retrieve the application token for this module
	 */
	function getAPITokenStruct(){
		return settings.APIToken;
	}

	/**
	* Generate the authorization link to retrieve the authorization code
	* The user has to allow manually the access to the FreshBooks account and paste the authorization code into the module settings
	*/
	function getLoginURL(){
		var strLoginURL = getAuthLink()
 		 & "authorize?client_id=" & getClientID()
 		 & "&response_type=code"
         & "&redirect_uri=" & getRedirectURI();
		
		return strLoginURL;
	}


	/**
	* Do the authentication process and retrieve the token access from a given authorization code
	* @results struct = { access_token:string, expires_in:date, expires_in_raw:number, refresh_token:string, success:boolean, token_type:string } 
	*/
	function authenticate(){
		//check if the token struct exists in the session and returns it if it has not expired
		if ( isDefined( "session.tokenStruct" ) AND session.tokenStruct.success 
												AND dateCompare(now(), parseDateTime(session.tokenStruct.expires_in), "n") <= 0 ){
			return session.tokenStruct;
		}
		else if( len(getTokenAccess() ) AND len( getRefreshToken() ) ){
			return this.refreshToken( getRefreshToken() );
		}
		var body = {};
		var headers = {};
		var APIURL = getAPIURL();
		response = {};
		headers [ "Content-Type" ] = "application/json" ;
		headers [ "Api-Version" ] = "alpha" ;
		
		body['grant_type'] = "authorization_code";
		body['client_secret'] = "#getClientSecret()#";
		body['code'] = "#getAuthorizationCode()#";
		body['client_id'] = "#getClientID()#";
		body['redirect_uri'] = "#getRedirectURI()#";

		response = makeRequest( method="POST", url=APIURL, body=body, headers=headers );
		return authResponse( response );
	}

	/**
	 * I take the refresh token from the authorization procedure and get you a new access token.
	 * @refreshToken the most recent refresh token that has been provided
	 * @results struct = { access_token:string, expires_in:date, expires_in_raw:number, refresh_token:string, success:boolean, token_type:string } 
	 */
	 function refreshToken( required String refreshToken ){
	 	var headers = {};
	 	var body = {};
	 	var APIURL = getAPIURL();
		var response = {};
		headers [ "Content-Type" ] = "application/json" ;
		headers [ "Api-Version" ] = "alpha" ;
		
		body['grant_type'] = "refresh_token";
		body['client_secret'] = "#getClientSecret()#";
		body['refresh_token'] = arguments.refreshToken;
		body['client_id'] = "#getClientID()#";
		body['redirect_uri'] = "#getRedirectURI()#";

		var response = makeRequest( method="post", url=APIURL, body=body, headers=headers );
		return authResponse( response );
	 }

	
	/**
	 * Manage response and build an struct with the token information and store it in the session
	 * @response HTTP Response
	 * @results struct { success:boolean,  access_token, token_type, expires_in_raw, expires_in, refresh_token}
	 */
	 function authResponse( required response ){
	 	var stuResponse = {};
 		if ( !response.error ){
			//Insert the access token into the properties
			structInsert( stuResponse, "access_token",	response.response.access_token );
			structInsert( stuResponse, "token_type",	response.response.token_type );
			structInsert( stuResponse, "expires_in_raw",response.response.expires_in );
			structInsert( stuResponse, "expires_in",	 DateAdd("s", response.response.expires_in, Now()) );
			setTokenAccess( response.response.access_token );
			
			if ( structKeyExists( response.response, "refresh_token") ){
				structInsert( stuResponse, "refresh_token", response.response.refresh_token );
				setRefreshToken( response.response.refresh_token );
			}
			structInsert( stuResponse, "success", true );
		}
		else{
			structInsert( stuResponse, "access_token", "Authorization Failed " & response.message );
			structInsert( stuResponse, "success", false );
		}
		session.tokenStruct = stuResponse;

		return stuResponse;
	 }


	/**
	* Make a test call
	* It will be deleted later
	*/
	function testCall(){
		var headers = {};
		headers [ "Api-Version" ] = "alpha" ;
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/test";

		var result =  makeRequest( headers=headers, url=endpoint );

		if ( result.error ){
			throw result.message;
		}
		return result.response;

	}

	/**
	* Returns the list of clients
	* @accountID The account ID that the client belongs to
	* @results an array of structs with the list of clients -> clients [ {client1},{client2},{client3},... ]
	*/
	function getClients( required String accountID ){
		var headers = {};
		var clients = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &"/users/clients";

		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return clients;
			}
			throw result.message;
		}
		for(cl in result.response.response.result.clients) {
			clients.append( cl );
		}
		return clients;
	}

	/**
	* Retrieve a single client
	* @accountID The account ID that the client belongs to
	* @clientID ID of the client to retrieve
	* @results struct 
	*/
	function getSingleClient( required String accountID, required String clientID ){
		if( !len( arguments.accountID ) ){
			throw( "Account id cannot be null or empty");
		}
		if( !len( arguments.clientID ) ){
			throw( "Client id cannot be null or empty");
		}
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/users/clients/" & arguments.clientID;
		
		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.client;
	}

	/**
	* Create a single client
	* @userInfo The struct with the client's info to create a new entry
	* @accountID The account ID where the client will be created in
	* @results returns an Struct with the client's fields
	*/
	function createSingleClient( required struct userInfo, required String accountID ){
		if( !len( userInfo )){
			throw( "UserInfo Struct cannot be null or empty");
		}
		if( !len( accountID ) ){
			throw( "Client id cannot be null or empty");
		}

		var headers = {};
		var newClient = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/users/clients";

		newClient[ "client"] = arguments.userInfo;

		var result =  makeRequest( method="POST", url=endpoint, headers=headers, body=newClient );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.client;

	}

	/**
	* Retrieve the list of expenses
	* @accountID The account ID of the expenses to list
	* @results an array of structs with the list of expenses -> expenses [ {expense1},{expense2},{expense3},... ]
	*/
	function getExpensesList( required String accountID ){
		var headers = {};
		var expenses = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/expenses/expenses";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return expenses;
			}
			throw result.message;
		}
		for( var exp in result.response.response.result.expenses ) {
			expenses.append( exp );
		}
		return expenses;

	}

	/**
	* Returns a single expense if it exists
	* @accountID Account Id where the expense belong to
	* @expenseID Id of the expense to return
	*/
	function getExpenseById( required String accountID, required String expenseID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/expenses/expenses/"& arguments.expenseID;

		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.expense;

	}


	/**
	* Get the list of invoices
	* @accountID The account ID of the invoices to list
	*/
	function getInvoicesList( required String accountID ){
		var headers = {};
		var invoices = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/invoices/invoices";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return invoices;
			}
			throw result.message;
		}
		for( var invoice in result.response.response.result.invoices ) {
			invoices.append( invoice );
		}
		return invoices;
	}

	/**
	* Returns a single invoice if it exists
	* @accountID Account Id where the invoice belong to
	* @invoiceID Id of the invoice to return
	*/
	function getInvoiceById( required String accountID, required String invoiceID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/invoices/invoices/"& arguments.invoiceID;

		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.invoice;
	}

	/**
	* Get the list of expense categories
	* @accountID The account ID of the expense categories to list
	* @results array [ {category:string, created_at:string, updated_at:string, categoryid:number, is_editable:boolean,
	* 									is_cogs:boolean, parentid, vis_state:number, id:number } , {category2}, ... ]
	*/
	function getExpenseCategoriesList( required String accountID ){
		var headers = {};
		var expenseCategoriesList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/expenses/categories";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return expenseCategoriesList;
			}
			throw result.message;
		}
		
		for( var expCategory in result.response.response.result.categories ) {
			expenseCategoriesList.append( expCategory );
		}
		return expenseCategoriesList;
	}

	/**
	* Returns a single invoice if it exists
	* @accountID Account Id where the invoice belong to
	* @invoiceID Id of the invoice to return
	* @results struct {category:string, created_at:string, updated_at:string, categoryid:number, is_editable:boolean,
	* 									is_cogs:boolean, parentid, vis_state:number, id:number }
	*/
	function getExpenseCategoryById( required String accountID, required String expenseCategoryID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/expenses/categories/"& arguments.expenseCategoryID;

		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.category;
	}

	/**
	* Get the list of gateways
	* @accountID The account ID of the expense categories to list
	* @results 
	*/
	function getGatewaysList( required String accountID ){
		var headers = {};
		var gatewaysList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/system/gateways";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return gatewaysList;
			}
			throw result.message;
		}
		for( var gateway in result.response.response.result.gateways ) {
			gatewaysList.append( gateway );
		}
		return gatewaysList;
	}

	/**
	* Get the list of estimates
	* @accountID The account ID of the estimates to list
	* @results 
	*/
	function getEstimatesList( required String accountID ){
		var headers = {};
		var estimatesList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/estimates/estimates";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return estimatesList;
			}
			throw result.message;
		}
		for( var estimate in result.response.response.result.estimates ) {
			estimatesList.append( estimate );
		}
		return estimatesList;
	}

	/**
	* Returns a single estimate if it exists
	* @accountID Account Id where the invoice belong to
	* @estimateID Id of the estimate to return
	* @results
	*/
	function getEstimateById( required String accountID, required String estimateID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/estimates/estimates/"& arguments.estimateID;

		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.estimate;
	}

	/**
	* Get the list of items
	* @accountID The account ID of the items to list
	* @results 
	*/
	function getItemsList( required String accountID ){
		var headers = {};
		var itemsList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/items/items";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return itemsList;
			}
			throw result.message;
		}
		for( var item in result.response.response.result.items ) {
			itemsList.append( item );
		}
		return itemsList;
	}

	/**
	* Returns a single item if it exists
	* @accountID Account Id where the invoice belong to
	* @itemID Id of the item to return
	* @results
	*/
	function getItemById( required String accountID, required String itemID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/estimates/estimates/"& arguments.itemID;

		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.item;
	}

	/**
	* Get the list of payments
	* @accountID The account ID of the payments to list
	* @results 
	*/
	function getPaymentsList( required String accountID ){
		var headers = {};
		var paymentsList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/payments/payments";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return paymentsList;
			}
			throw result.message;
		}
		for( var item in result.response.response.result.payments ) {
			paymentsList.append( item );
		}
		return paymentsList;
	}

	/**
	* Returns a single item if it exists
	* @accountID Account Id where the invoice belong to
	* @itemID Id of the item to return
	* @results
	*/
	function getPaymentById( required String accountID, required String itemID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/estimates/estimates/"& arguments.itemID;

		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.payment;
	}

	/**
	* Get the list of taxes
	* @accountID The account ID of the taxes to list
	* @results 
	*/
	function getTaxesList( required String accountID ){
		var headers = {};
		var taxesList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/taxes/taxes";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return taxesList;
			}
			throw result.message;
		}
		for( var tax in result.response.response.result.taxes ) {
			taxesList.append( tax );
		}
		return taxesList;
	}

	/**
	* Returns a single tax if it exists
	* @accountID Account Id where the tax belong to
	* @itemID Id of the tax to return
	* @results
	*/
	function getTaxById( required String accountID, required String taxID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/taxes/taxes/"& arguments.taxID;

		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.tax;
	}

	/**
	* Get the list of the staff
	* @accountID The account ID of the staff to list
	* @results array of structs -> [ {fax, rate, num_logins, api_token, id, note, display_name, lname, mob_phone, last_login, home_phone, email, 
	* 								 username, updated, p_province, p_city, p_code, p_country, accounting_systemid, bus_phone, signup_date,
	* 				 				 language, level, userid, p_street2, vis_state, fname, organization, p_street, currency_code}, ... ]
	*/
	function getStaffList( required String accountID ){
		var headers = {};
		var staffList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/users/staffs";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return staffList;
			}
			throw result.message;
		}
		for( var staff in result.response.response.result.staff ) {
			staffList.append( staff );
		}
		return staffList;
	}

	/**
	* Returns a single staff member if it exists
	* @accountID Account Id where the staff member belongs to
	* @staffID Id of the staff member to return
	* @results struct {fax, rate, num_logins, api_token, id, note, display_name, lname, mob_phone, last_login, home_phone, email, username,
	* 				   updated, p_province, p_city, p_code, p_country, accounting_systemid, bus_phone, signup_date, language, level, userid,
	* 				   p_street2, vis_state, fname, organization, p_street, currency_code}
	*/
	function getStaffById( required String accountID, required String staffID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/users/staffs/"& arguments.staffID;

		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.staff;
	}

	/**
	* Get time entries
	* @businessID The business ID associated to the time entries
	* @results struct -> time_entries { note, duration, project_id, client_id, is_logged, started_at, active, id, timer { id, is_running},
	* 									meta { pages, total_logged, total_unbilled, per_page, total, page } }
	*/
	function getTimeEntries( required String businessID ){
		var headers = {};
		var timeEntries = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/timetracking/business/" & arguments.businessID & "/time_entries";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return staffList;
			}
			throw result.message;
		}
		for( var timeEntry in result.response.time_entries ) {
			timeEntries.append( timeEntry );
		}
		return timeEntries;
	}

	/**
	* Get the list of the projects associated to a business ID
	* @businessID The account ID of the staff to list
	* @projectID 
	* @results 
	*/
	function getProjectsList( required String businessID ){
		var headers = {};
		var projectsList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/projects/business/" & arguments.businessID & 
						"/projects";

		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return projectsList;
			}
			throw result.message;
		}
		for( var project in result.response.projects ) {
			projectsList.append( project );
		}
		return projectsList;
	}

	/**
	* Returns a single project if it exists
	* @businessID 
	* @projectID 
	* @results 
	*/
	function getProjectById( required String businessID, required String projectID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/projects/business/" & arguments.businessID & 
						"/projects/" & arguments.projectID;

		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.project;
	}

	/**
	* Returns a single task if it exists
	* @accountID 
	* @taskID 
	* @results 
	*/
	function getTaskById( required String accountID, required String taskID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & 
						"/projects/tasks/" & arguments.taskID;

		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.task;
	}


	/**
	* Make a request to FreshBooks
	* @method The HTTP method call
	* @url The url to make the request
	* @body The body contents of the request
	* @headers Request headers
	* @paremeters Request parameters
	* @timeout Request Timeout
	* @results struct = { error:boolean, response:struct, message, reponseHeader:struct, rawResponse, stacktrace }
	*/
	private struct function makeRequest(
		string method = "GET",
		required string url,
		body = {},
		struct headers = structNew(),
		struct parameters = structNew(),
		numeric timeout = 15
	){
		var results = { 
			error 			= false,
			response 		= {},
			message 		= "",
			responseheader 	= {},
			rawResponse 	= "",
			stacktrace		= ""
		};
		var param 		= "";
		var jsonRegex 	= "^(\{|\[)(.)*(\}|\])$";


		// Default Content Type
		if( NOT structKeyExists( arguments.headers, "content-type" ) ){
			arguments.headers[ "content-type" ] = "";
		}

		// Create HTTP object
		var oHTTP = new HTTP(
			method 			= arguments.method,
			url 			= arguments.url,
			charset 		= "utf-8",
			timeout 		= arguments.timeout,
			throwOnError 	= true
		);

		// Add Headers
		for( var thisHeader in arguments.headers ){
			oHTTP.addParam( type="header", name="#thisHeader#", value="#arguments.headers[ thisHeader ]#" );
		}

		// Add URL Parameters: encoded automatically by CF 
		for( var thisParam in arguments.parameters ){
			oHTTP.addParam( type="URL", name="#thisParam#", value="#arguments.parameters[ thisParam ]#" );
		}
		
		// Body
		if( len( arguments.body ) ){
			var bodyJSON = serializeJSON( arguments.body );
			oHTTP.addParam( type="body", value=bodyJSON );
		}

		// Make the request
		try{	
			var HTTPResults = oHTTP.send().getPrefix();
			// Set Results
			results.responseHeader 	= HTTPResults.responseHeader;
			results.rawResponse 	= HTTPResults.fileContent.toString();

			// Error Details found?
			results.message = HTTPResults.errorDetail;
			if( len( HTTPResults.errorDetail ) ){ 
				results.error = true; 
			}
			
			// Try to inflate JSON
			results.response = deserializeJSON( results.rawResponse, false );

			// Verify response error?
			if( structKeyExists(results.response, "error") ){
				results.error 	= true;
				results.message = results.response.messages.toString();
			}

		} catch( Any e ) {
			results.error 		= true;
			results.message 	= e.message & e.detail;
			results.stacktrace 	= e.stacktrace;
		}
		
		return results;
	}

}