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
	property name="APItoken";
	property name="APIURL";
	property name="authLink";
	property name="redirectURI"

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
		//writedump( arguments ); abort;
		variables.settings = arguments.settings;
		variables.APIURL = arguments.settings.APIURL;
		variables.authLink = arguments.settings.authLink;
		variables.redirectURI = arguments.settings.redirectURI;
		variables.clientID = arguments.settings.APIToken.clientID;
		variables.clientSecret = arguments.settings.APIToken.clientSecret;
		return this;
	}

	/**function onDIComplete(){
		var tokenStruct = getAPITokenStruct();
		setAPIUrl( "https://api.freshbooks.com/auth/oauth/token/" );
		setClientID( tokenStruct.clientId );
		setClientSecret( tokenStruct.clientSecret );
		identityInformation = {};
	}*/

	/**
	 * Retrieve the application token for this module
	 */
	function getAPITokenStruct(){
		return settings.APIToken;
	}

	/**
	* Genrate the Login URL to get the authorization code
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
	* code The authorization code associated to the application and client Id
	*/
	function authenticate( String code ){
		var params = {};
		var body = {};
		params [ "method" ] = "post" ;
		params [ "URL" ] = getApiUrl();
		params [ "Content-Type" ] = "application/json" ;
		params [ "Api-Version" ] = "alpha" ;
		
		body['grant_type'] = "authorization_code";
		body['client_secret'] = trim( getClientSecret() );
		body['code'] = arguments.code;
		body['client_id'] = getClientID();
		body['redirect_uri'] = "https://github.com/coldbox-modules/cbox-freshbooksSDK";

		params [ "body" ] = body ;
		response = makeRequest( params );

		return AuthResponse( response );
	}

	/**
	* Make a test call
	* It will be deleted later
	*/
	function testCall(){
		var params = {};
		params[ "method" ] = "get";
		params [ "Api-Version" ] = "alpha";
		params[ "Authorization" ] = "Bearer " & getAPITokenStruct().access_token;
		params [ "URL" ] = "https://api.freshbooks.com/test";
		return makeRequest( params );
	}

	/**
	* Returns an array of structs with the list of clients
	*/
	function getClients( required String accountID )
	{
		var params = {};
		var response = {};
		params[ "method" ] = "get";
		params [ "Api-Version" ] = "alpha";
		params[ "Authorization" ] = "Bearer " & getAPITokenStruct().access_token;
		params [ "URL" ] = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &"/users/clients";

		response = buildStruct( makeRequest( params ) );

		if( response.success ){
			var clients = [];
			for(cl in response.data.result.clients) {
				arrayAppend(clients, cl);
			}
			return clients;
		}
		else{
			throw response.error[1].message;
		}
	}

	/**
	* Retrieve a single client
	* accountID The account Id that the client belongs to, id of the client
	*/
	function getSingleClient( required String accountID, required String id ){
		if( isNull( arguments.accountID ) )

		// NOTES: isDefined(), isNull(), structKeyExists()
		// arguments.accountID.len() or len( arguments.accountID )

		if( NOT IsDefined("arguments.accountID") OR arguments.accountID EQ "" ){
			throw( "Account id cannot be null or empty");
		}
		if( NOT IsDefined("accountID") OR accountID EQ "" ){
			throw( "Client id cannot be null or empty");
		}
		var params = {};
		params [ "Api-Version" ] = "alpha";
		params[ "Authorization" ] = "Bearer " & getAPITokenStruct().access_token;
		params[ "method" ] = "get";
		params [ "URL" ] = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/users/clients/" & arguments.id;
		
		response = buildStruct( makeRequest( params ) );

		if( response.success ){
			return response.data.result.client;
		}
		else{
			throw response.error[1].message;
		}
	}

	/**
	* Create a single client
	* userInfo The struct with the client's info to create a new entry
	*/
	function createSingleClient( required struct userInfo, required String accountID ){
		if( NOT IsDefined("arguments.userInfo") OR isEmpty( userInfo )){
			throw( "UserInfo Struct cannot be null or empty");
		}
		if( NOT IsDefined("accountID") OR accountID EQ "" ){
			throw( "Client id cannot be null or empty");
		}

		var params = {};
		var newClient = {};
		params [ "Api-Version" ] = "alpha";
		params [ "Authorization" ] = "Bearer " & getAPITokenStruct().access_token;
		params [ "Content-Type" ] = "application/json" ;
		params [ "method" ] = "post";
		params [ "URL" ] = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/users/clients";

		newClient [ "client" ] = userInfo;
		params [ "body" ] = newClient;
		return makeRequest( params );

	}

	/**
	* Retrieve the list of expenses
	*/
	function getExpensesList( required String accountID )
	{
		var params = {};
		params[ "method" ] = "get";
		params [ "Api-Version" ] = "alpha";
		params[ "Authorization" ] = "Bearer " & getAPITokenStruct().access_token;
		params [ "URL" ] = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/expenses/expenses";

		response = buildStruct( makeRequest( params ) );
		if( response.success ){
			var expenses = [];
			for( var exp in response.data.result.expenses) {
				arrayAppend(expenses, exp);
				expenses.append( exp );
			}
			return expenses;
		}
		else{
			throw response.error[1].message;
		}
	}

	/**
	* Returns a single expense if it exists
	* accountID Account Id where the expense belong to
	* expenseID Id of the expense to return
	*/
	function getExpenseById( required String accountID, required String expenseID )
	{
		var params = {};
		params[ "method" ] = "get";
		params [ "Api-Version" ] = "alpha";
		params[ "Authorization" ] = "Bearer " & getAPITokenStruct().access_token;
		params [ "URL" ] = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/expenses/expenses/"& arguments.expenseID;

		response = buildStruct( makeRequest( params ) );

		if( response.success ){
			return response.data.result.expense;
		}
		else{
			throw response.error[1].message;
		}
	}

	/**
	* Get the identity information to retrieve id and account id
	*/
	function getIdentityInformation()
	{
		return variables.identityInformation;
	}

	/**
	* Set the id and account id with the information found in the freshbooks account 
	*/
	function setIdentityInformation(String token)
	{
		var params = {};
		params[ "method" ] = "get";
		params[ "Authorization" ] = "Bearer " & token;
		params [ "Api-Version" ] = "alpha";
		params[ "Content-Type" ] = "application/json";
		params [ "URL" ] = "https://api.freshbooks.com/auth/api/v1/users/me";

		result = deserializeJSON( makeRequest( params ) );
		variables.identityInformation.id = result.response[ "id" ];
		//to ask: how to retrieve the id of this specific account, one user can have more than one account.
		variables.identityInformation.account_id = result.response.business_memberships[1].business[ "account_id" ];
	}

	/**
	* Make an http request to send and return data
	* method and URL keys are required
	*/
	function makeRequest( struct params )
	{
		var httpService = new http();
		httpService.setMethod( arguments.params[ "method" ] );
		httpService.setUrl( arguments.params[ "URL" ] );
		StructDelete(params,"method");
		StructDelete(params,"URL");
		if (structKeyExists(arguments.params, "body")){
			var bodyJSON = serializeJSON( arguments.params[ "body" ] );
			httpService.addParam( type= "body" , value=bodyJSON );
			StructDelete(params,"body");
		}
		//loop extra header parameters and add them to the request
		for(var key in params) {
			httpService.addParam( type= "header" , name = key, value=params[key] );
		}
		var result = httpService.send().getPrefix().filecontent;
		return result;
	}

	/**
	* take the response and build an struct with the information
	* it returns a 'success' key to verify if an error occurred in the request
	*/
	function buildStruct( required response ){
		var stuResponse = {};
		var jsonResponse = deserializeJSON(arguments.response);
		
		if (!structKeyExists(jsonResponse[ "response" ], "errors")){
			structInsert(stuResponse, "data", jsonResponse[ "response" ]);
			structInsert(stuResponse, "success", true);
		}
		
		else{
			structInsert(stuResponse, "error", jsonResponse[ "response" ][ "errors"]);
			structInsert(stuResponse, "success", false);
		}

		return stuResponse;
	}

	/**
	* take the response from the access and refresh token requests 
	*/
	function AuthResponse( required response ){
		var stuResponse = {};
		var jsonResponse = deserializeJSON(arguments.response);
		
		if (structKeyExists(jsonResponse, "access_token")){
			<!--- Insert the access token into the properties --->
			structInsert( stuResponse, "access_token",	jsonResponse.access_token);
			structInsert( stuResponse, "token_type",		jsonResponse.token_type);
			structInsert( stuResponse, "expires_in_raw",	jsonResponse.expires_in);
			structInsert( stuResponse, "expires_in",		DateAdd("s", jsonResponse.expires_in, Now()));
			
			if (structKeyExists(jsonResponse, "refresh_token")){
				structInsert(stuResponse, "refresh_token", jsonResponse.refresh_token);
			}
			structInsert(stuResponse, "success", true);
		}
		else{
			structInsert(stuResponse, "access_token", "Authorization Failed " & response);
			structInsert(stuResponse, "success", false);
		}
		StructAppend(getAPITokenStruct(), stuResponse, true);

		return stuResponse;
	}


	/**
	* Make a request to FreshBooks
	* @method The HTTP method call
	* @url The url to make the request
	* @body The body contents of the request
	* @headers Request headers
	* @paremeters Request parameters
	* @timeout Request Timeout
	* 
	* @results struct = { error:boolean, response:struct, message, reponseHeader:struct, rawResponse }
	*/
	private struct function makeRequest(
		string method = "GET",
		required string url,
		body = "",
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
		var HTTPResults = "";
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
			oHTTP.addParam( type="body", value="#arguments.body#" );
		}
		
		// Make the request
		try{
			var HTTPResults = oHTTP.send().getPrefix();

			// Set Results
			results.responseHeader 	= HTTPResults.responseHeader;
			results.rawResponse 	= HTTPResults.fileContent.toString();
			
			// Error Details found?
			results.message = HTTPResults.errorDetail;
			if( len( HTTPResults.errorDetail ) ){ results.error = true; }
			
			// Try to inflate JSON
			results.response = deserializeJSON( results.rawResponse, false );

			// Verify response error?
			if( results.response.error ){
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