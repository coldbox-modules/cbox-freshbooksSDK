/**
* This is the Freshbooks SDK class
*/
component accessors=true{
	
	// DI
	property name="settings" inject="coldbox:modulesettings:cbfreshbooks";

	//Properties
	property name="clientId";
	property name="clientSecret";
	property name="APItoken";
	property name="apiUrl";
	property name="identityInformation";

	/**
	* Constructor
	*/
	function init(){
		return this;
	}

	function onDIComplete(){
		var tokenStruct = getAPITokenStruct();
		setApiUrl( "https://api.freshbooks.com/auth/oauth/token/" );
		setClientID( tokenStruct.clientId );
		setClientSecret( tokenStruct.clientSecret );
		identityInformation = {};
	}

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
		strLoginURL = "https://my.freshbooks.com/service/auth/oauth/"
 		 & "authorize?client_id=" & clientID
 		 & "&response_type=code"
         & "&redirect_uri=" & "https://github.com/coldbox-modules/cbox-freshbooksSDK";
	return strLoginURL;
	}

	/**
	* Do the authentication process and retrieve the token access from a given authorization code
	* code The authorization code associated to the application and client Id
	*/
	function Authenticate( String code ){
		var httpService = new http();
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

		return ManageResponse( response );
	}

	/**
	* Make a test call
	* It will be deleted later
	*/
	function testCall()
	{
		var params = {};
		params[ "method" ] = "get";
		params [ "Api-Version" ] = "alpha";
		params[ "Authorization" ] = "Bearer " & getAPITokenStruct().access_token;
		params [ "URL" ] = "https://api.freshbooks.com/test";
		return makeRequest( params );
	}

	/**
	* Retrieve the list of clients
	*/
	function getClients( required String accountID )
	{
		var params = {};
		params[ "method" ] = "get";
		params [ "Api-Version" ] = "alpha";
		params[ "Authorization" ] = "Bearer " & getAPITokenStruct().access_token;
		params [ "URL" ] = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &"/users/clients";
		return makeRequest( params );
	}

	/**
	* Retrieve a single client
	* accountID The account Id that the client belongs to, id of the clientt
	*/
	function getSingleClient( required String accountID, required String id ){
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
		
		return makeRequest( params );

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
		return makeRequest( params );
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
		return makeRequest( params );
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
		for(key in params) {
			httpService.addParam( type= "header" , name = key, value=params[key] );
		}
		var result = httpService.send().getPrefix().filecontent;
		return result;
	}

	/**
	* take the response from the access and refresh token requests 
	*/
	function ManageResponse( required response ){
		var stuResponse = {};
		var jsonResponse = deserializeJSON(arguments.response);
		
		if (structKeyExists(jsonResponse, "access_token")){
			<!--- Insert the access token into the properties --->
			structInsert(stuResponse, "access_token",	jsonResponse.access_token);
			structInsert(stuResponse, "token_type",		jsonResponse.token_type);
			structInsert(stuResponse, "expires_in_raw",	jsonResponse.expires_in);
			structInsert(stuResponse, "expires_in",		DateAdd("s", jsonResponse.expires_in, Now()));
			
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
}