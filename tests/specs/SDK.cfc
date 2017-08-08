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
				it( "can authenticate and get a valid token" , function(){
					//I obtain the authorization code from the URL built from the client ID
					var tokenResponse = {};
					tokenResponse = sdk.Authenticate( "c6064aa2412fee64a969ee09d26497fa70bbb68c62bc7f6dc6de738c51c98fc7" );
					expect ( tokenResponse ).notToBeEmpty();
					expect ( tokenResponse.success ).toBe ( true );
				});
				it( "can set identity information" , function(){
					sdk.setIdentityInformation( sdk.getAPITokenStruct().access_token );
				});
				it( "can get identity information" , function(){
					identityInfo = sdk.getIdentityInformation( );
					expect ( identityInfo ).notToBeNull();
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
					sdk.getClients( "EalP4" );
				});
				it( "can get a single client" , function(){
					sdk.getSingleClient( "EalP4", "152604" );
				});
				it( "can create a single client" , function(){
					userInfo = {};
					userInfo[ "name"] = "James";
					userInfo[ "email" ] = "James@ortus.com";
					//WriteDump( sdk.createSingleClient( userInfo , "EalP4") );
				});
				it( "can list the expenses" , function(){
					//sdk.getExpensesList( "EalP4" )
					writeDump( sdk.getExpensesList( "EalP4 1" ) );
				});
				it( "can get an expense by id" , function(){
					sdk.getExpenseById( "EalP4", "1119673"  );
				});

			});
		});
	}
	
}