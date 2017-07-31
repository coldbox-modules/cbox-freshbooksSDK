/**
* My BDD Test
*/
component extends="coldbox.system.testing.BaseTestCase"{
	
/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
		super.beforeAll();
	}

	// executes after all suites+specs in the run() method
	function afterAll(){
		
	}

/*********************************** BDD SUITES ***********************************/

	function run( testResults, testBox ){
		// all your suites go here.
		describe( "Freshbooks SDK Module", function(){

			beforeEach(function( currentSpec ){
				sdk = getInstance( "SDK@cbfreshbooks" );	
			});

			it( "can register the module and models", function(){
				expect( sdk ).toBeComponent();
				debug( sdk );
			});

			it( "can register the APIToken in the SDK", function(){
				expect( sdk.getAPITokenStruct() ).notToBeEmpty();
				expect( sdk.getAPITokenStruct() ).toBeStruct();
			});

			describe( "Authentication Mechanisms", function(){

				it( "can build the Login URL" , function(){
					writeDump( sdk.getLoginURL() );
					expect ( sdk.getLoginURL() ).notToBeEmpty();
				});	
				it( "can retrieve a valid token" , function(){
					//I obtain the authorization code from the URL built from the client ID 
					tokenStruct = sdk.getAccessToken( "b3fd942a4ce16f290c9e3689b7b75cac765aa7cc2834647de14daef8e1005738" );
					expect ( tokenStruct ).notToBeEmpty();
				});
				given( "an invalid token", function(){
					then( "I should get an error response", function(){
					
					});
				});
			});
			describe( "Requests to the API", function(){

				it( "can make a request to the API" , function(){
					testCall =  sdk.testCall();
					expect ( testCall ).notToBeEmpty();
				});
				it( "can get the list of clients" , function(){
					writeDump( sdk.getClients() );
				});
			});
		});
	}
	
}