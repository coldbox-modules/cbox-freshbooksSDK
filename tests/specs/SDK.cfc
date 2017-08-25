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

				it( "can set the identity" , function(){
					//var identity = sdk.setIdentityInformation( sdk.getTokenAccess() );
					//writeDump( identity );
				});
				it( "can get identity information" , function(){
					//identityInfo = sdk.getIdentityInformation( );
					//expect ( identityInfo ).notToBeNull();
				});
				it( "can build the Login URL" , function(){
					expect ( sdk.getLoginURL() ).notToBeEmpty();
				});	
				it( "can authenticate and get a valid token" , function(){
					var tokenResponse = {};
					tokenResponse = sdk.Authenticate();
					expect ( tokenResponse ).notToBeEmpty();
					expect ( tokenResponse.success ).toBe ( true );
				});
				it( "can refresh the access token" , function(){
					var tokenRefresh = sdk.refreshToken( sdk.getRefreshToken() );
					expect ( tokenRefresh ).notToBeEmpty();
				});
				given( "an invalid token", function(){
					then( "I should get an error response", function(){
					
					});
				});
			});
			describe( "Requests to the API", function(){

				it( "can make a request to the API" , function(){
					var testCall =  sdk.testCall();
					expect ( testCall ).notToBeEmpty();
				});
				it( "can get the list of clients" , function(){
					var clientsList = sdk.getClients( "EalP4" );
					expect ( clientsList ).toBeArray();
				});
				it( "can get a single client" , function(){
					var singleCLient = sdk.getSingleClient( "EalP4", "152604" );
					expect ( singleCLient.fname ).toBe ( "Javier" );
				});
				it( "can create a single client" , function(){
					var userInfo = {};
					userInfo[ "fname"] = "Mike";
					userInfo[ "email" ] = "Mike@ortus.com";
					userInfo[ "organization"] = "Ortus";
					userInfo[ "home_phone" ] = "8326759836";
					//var clien = sdk.createSingleClient( userInfo , "EalP4");
					//writeDump(clien);
				});
				it( "can list the expenses" , function(){
					var expensesList = sdk.getExpensesList( "EalP4" );
					expect ( expensesList ).toBeArray();

				});
				it( "can get an expense by id" , function(){
					var expense = sdk.getExpenseById( "EalP4", "1119673"  );
					expect ( expense.amount.amount ).toBe( 125.00 );
				});
				it( "can list the invoices" , function(){
					var invoicesList = sdk.getInvoicesList( "EalP4" );
					expect ( invoicesList ).toBeArray();
				});
				it( "can get an invoice by id" , function(){
					var invoice = sdk.getInvoiceById( "EalP4", "725686"  );
					expect ( invoice.payment_status ).toBe( "unpaid" );
				});
				it( "can list expense categories" , function(){
					var expenseCategories = sdk.getExpenseCategoriesList( "EalP4" );
					expect ( expenseCategories ).toBeArray();
				});
				it( "can get an expense category by id" , function(){
					var expenseCategory = sdk.getExpenseCategoryById( "EalP4", "5094368" );
					expect ( expenseCategory.category ).toBe( "Contractors" );
				});
				it( "can list gateways" , function(){
					var gateways = sdk.getGatewaysList( "EalP4" );
					expect ( gateways ).toBeArray();
				});
				it( "can list estimates" , function(){
					var estimates = sdk.getEstimatesList( "EalP4" );
					expect ( estimates ).toBeArray();
				});
				it( "can get an estimate by id" , function(){
					var estimate = sdk.getEstimateById( "EalP4", "258237" );
					expect ( estimate.invoiced ).toBe( false );
				});
				it( "can list items" , function(){
					var items = sdk.getItemsList( "EalP4" );
					expect ( items ).toBeArray();
				});
				it( "can get an item by id" , function(){
					var item = sdk.getItemById( "EalP4", "123456" );
					expect ( item ).toBeEmpty();
				});
				it( "can list payments" , function(){
					var payments = sdk.getPaymentsList( "EalP4" );
					expect ( payments ).toBeArray();
				});
				it( "can get a payment by id" , function(){
					var payment = sdk.getPaymentById( "EalP4", "123456" );
					expect ( payment ).toBeEmpty();
				});
				it( "can list taxes" , function(){
					var taxes = sdk.getTaxesList( "EalP4" );
					expect ( taxes ).toBeArray();
				});
				it( "can get a single tax by id" , function(){
					var tax = sdk.getTaxById( "EalP4", "123456" );
					expect ( tax ).toBeEmpty();
				});
				it( "can list staff" , function(){
					var staffs = sdk.getStaffList( "EalP4" );
					expect ( staffs ).toBeArray();
				});
				it( "can get a staff member by id" , function(){
					var staff = sdk.getStaffById( "EalP4", "1" );
					expect ( staff ).notToBeEmpty();
				});
				it( "can list time entries" , function(){
					var timeEntries = sdk.getTimeEntries( "400641" );
					expect ( timeEntries ).toBeArray();
				});
				it( "can list projects" , function(){
					var projects = sdk.getProjectsList( "400641" );
					expect ( projects ).toBeArray();
				});
				it( "can get a single project by id" , function(){
					var project = sdk.getProjectById( "400641", "831050" );
					expect ( project ).notToBeEmpty();
				});
				it( "can get a single task by id" , function(){
					var task = sdk.getTaskById( "EalP4", "144968" );
					expect ( task ).notToBeEmpty();
					writeDump( task );
				});
			});
		});
	}
}