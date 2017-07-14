/**
* This is the Freshbooks SDK class
*/
component{
	
	// DI
	property name="settings" inject="coldbox:modulesettings:cbfreshbooks";

	/**
	* Constructor
	*/
	function init(){
		return this;
	}

	/**
	 * Retrieve the application token for this module
	 */
	function getAPIToken(){
		return settings.APIToken;
	}

}