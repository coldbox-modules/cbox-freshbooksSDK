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

			it( "can register the module and models", function(){
				var sdk = getInstance( "SDK@cbfreshbooks" );
				expect( sdk ).toBeComponent();
				//debug( sdk );
			});

			it( "can register the APIToken in the SDK", function(){
				var sdk = getInstance( "SDK@cbfreshbooks" );
				expect( sdk.getAPIToken() ).notToBeEmpty();
			});

			describe( "Authentication Mechanisms", function(){
				given( "an invalid token", function(){
					then( "I should get an error response", function(){
					
					});
				});
				given( "a valid token", function(){
					then( "I should get a good response", function(){
					
					});
				
				});
			
			});


		});
	}
	
}