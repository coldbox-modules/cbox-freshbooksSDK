/**
*********************************************************************************
* Your Copyright
********************************************************************************
*/
component{

	// Module Properties
	this.title 				= "cbfreshbooks";
	this.author 			= "Ortus Solutions";
	this.webURL 			= "https://www.ortussolutions.com";
	this.description 		= "Freshbooks SDK for ColdBox Applications";
	this.version			= "@build.version@+@build.number@";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	// Module Entry Point
	this.entryPoint			= "cbfreshbooks";
	// Model Namespace
	this.modelNamespace		= "cbfreshbooks";
	// CF Mapping
	this.cfmapping			= "cbfreshbooks";
	// Auto-map models
	this.autoMapModels		= true;
	// Module Dependencies That Must Be Loaded First, use internal names or aliases
	this.dependencies		= [ ];

	/**
	* Configure module
	*/
	function configure(){

		settings = {
			// The Freshbooks API Token
			APIToken = ""
		}

	}

	/**
	* Fired when the module is registered and activated.
	*/
	function onLoad(){
	}

	/**
	* Fired when the module is unregistered and unloaded
	*/
	function onUnload(){
		
	}

}
