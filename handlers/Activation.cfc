/**
* Handler which activates the module.
*/
component{

	/**
	 * The module settings
	 */
	property name ="sdk" inject="SDK@cbfreshbooks";

	/**
	 * Load view to let user allow Freshbooks account access
	 * @param  event Event
	 * @param rc Request Collection
	 * @param prc Private Request Collection
	 */
	any function activate( event, rc, prc ){
		prc.isAuth = false;
		if (sdk.isAuth() OR ( len( sdk.getTokenAccess() ) AND len( sdk.getRefreshToken() )) ){
			prc.isAuth = true;
		}
		event.setView( "activation/index" );
	}

	/**
	 * Build the authorization URL and redirect to the confirmation page
	 */
	any function authorization(){
		setNextEvent( URL=sdk.buildAuthorizationURL() );
	}

	/**
	 * Authenticate a freshbooks account into the Freshbooks SDK Module
	 * @event Event
	 * @prc Private Request Collection
	 */
	any function authenticate( event, prc ){
		if ( isNull( url.code ) ){
			throw "Authorization code was not found as a parameter in the URL";
		}
		sdk.setAuthorizationCode( url.code );
		var tokenResponse = sdk.Authenticate();
		prc.result = tokenResponse.success;
		if ( tokenResponse.success ){
			prc.response = "You have been successfully authenticated into the Freshbooks SDK Module";
		}
		else{
			prc.response = "There was an error in the authentication: " & tokenResponse.message;
		}
		event.setView( "activation/confirmation" );
	}

	/**
	 * Revoke Freshbooks access
	 */
	function revokeAccess(){
		sdk.revokeAccess();
		prc.Revokemessage = "The access has been revoked!"
		event.setView( "activation/revokeAccess" );
	}
}