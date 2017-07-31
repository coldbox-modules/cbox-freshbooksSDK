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
	* Retrieve the token access from a given authorization code
	* code The authorization code associated to the application and client Id
	*/
	function getAccessToken( String code ){
		var httpService = new http();
		var body = {};
		httpService.setMethod( "post" );
		httpService.setUrl( getApiUrl() );
		httpService.addParam( type="header", name="Content-Type", value="application/json" );
		httpService.addParam( type="header",name="Api-Version",value="alpha" );
		
		body['grant_type'] = "authorization_code";
		body['client_secret'] = trim( getClientSecret() );
		body['code'] = arguments.code;
		body['client_id'] = getClientID();
		body['redirect_uri'] = "https://github.com/coldbox-modules/cbox-freshbooksSDK";

		bodyJSON = serializeJSON( body );
		httpService.addParam( type = "body", value = bodyJSON );
		var result = httpService.send().getPrefix().filecontent;

		return deserializeJSON( result );
	}

	/**
	* Make a test call
	* It will be deleted later
	*/
	function testCall()
	{
		var params = {};
		params[ "APImethod" ] = "TEST";
		params[ "HttpMethod" ] = "get";
		params [ "URL" ] = "https://api.freshbooks.com/test";
		return makeRequest( params );
	}

	/**
	* Retrieve the list of clients
	*/
	function getClients()
	{
		var params = {};
		params[ "APImethod" ] = "client.list";
		params[ "HttpMethod" ] = "get";
		params [ "URL" ] = "https://api.freshbooks.com/accounting/account/EalP4/users/clients";
		return makeRequest( params );
	}

	/**
	* Make an http request to send and return data
	*/
	function makeRequest( struct params )
	{
		var httpService = new http();
		var argumentsList = arguments.params;
		var authSubToken = "Bearer " & getAPITokenStruct().access_token;
		var HttpMethod = argumentsList [ "HttpMethod" ];
		var apiMethod = argumentsList [ "APImethod" ];
		var remoteURL = argumentsList [ "URL" ];

		httpService.setMethod( HttpMethod );
		httpService.setUrl( remoteURL );

		httpService.addParam( type= "header" , name = "Api-Version", value="alpha" );
		httpService.addParam( type = "header", name = "Authorization", value = authSubToken );
		//httpService.addParam( type= "header" , name = "Content-Type", value="application/json" );

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