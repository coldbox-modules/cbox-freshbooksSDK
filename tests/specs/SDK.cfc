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
					//writeDump( clientsList );
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
				it( "can update a single client" , function(){
					var userInfo = {};
					userInfo[ "fname"] = "Miky";
					var singleCLient = sdk.updateSingleClient( "EalP4", "164816", userInfo );
					expect ( singleCLient.fname ).toBe ( "Miky" );
				});
				it( "can delete a single client" , function(){
					var userInfo = {};
					userInfo[ "vis_state"] = 1;
					var singleCLient = sdk.updateSingleClient( "EalP4", "164816", userInfo );
					expect ( singleCLient.vis_state ).toBe ( 1 );
				});
				it( "can list the expenses" , function(){
					var expensesList = sdk.getExpensesList( "EalP4" );
					expect ( expensesList ).toBeArray();

				});
				it( "can get an expense by id" , function(){
					var expense = sdk.getExpenseById( "EalP4", "1119673"  );
					expect ( expense.amount.amount ).toBe( 125.00 );
				});
				it( "can create an expense" , function(){
					var expenseInfo = {};
					expenseInfo["amount"]["amount"] = 39.991;
					expenseInfo["categoryid"] = "5094363";
					expenseInfo["staffid"] = 1;
					expenseInfo["date"] = "2017-09-11";
					//var expense = sdk.createExpense( "EalP4", expenseInfo );
					//expect ( expense.categoryid ).toBe( "5094363" );
				});
				it( "can update a single expense" , function(){
					var expenseInfo = {};
					expenseinfo[ "vendor" ] = "Ortus Vendor";
					var expense = sdk.updateExpense( "EalP4", "1119673", expenseInfo );
					//writeDump( expense );
				});
				it( "can delete a single expense" , function(){
					var expenseFlag = {};
					expenseFlag[ "vis_state" ] = 1;
					//var expense = sdk.deleteExpense( "EalP4", "1119673", expenseFlag );
				});
				it( "can list the invoices" , function(){
					var invoicesList = sdk.getInvoicesList( "EalP4" );
					expect ( invoicesList ).toBeArray();
				});
				it( "can get an invoice by id" , function(){
					var invoice = sdk.getInvoiceById( "EalP4", "725686"  );
					expect ( invoice.payment_status ).toBe( "partial" );
				});
				it( "can create an invoice" , function(){
					var invoiceInfo = {};
					invoiceInfo[ "email" ] = "testingInvoice@ortus.com";
					invoiceInfo[ "customerid" ] = "156482";
					invoiceInfo[ "create_date" ] = "2017-09-13";
					//var invoice = sdk.createInvoice( "EalP4", invoiceInfo );
					//expect ( invoice.auto_bill ).notToBe( true );
				});
				it( "can update a single invoice" , function(){
					var invoiceInfo = {};
					invoiceInfo[ "customerid" ] = "156482";
					invoiceInfo[ "create_date" ] = "2017-09-12";
					var invoice = sdk.updateInvoice( "EalP4", "755890", invoiceInfo );
					//writeDump( invoice );
				});
				it( "can delete an invoice" , function(){
					var invoiceFlag = {};
					invoiceFlag[ "vis_state" ] = 1;
					//var invoice = sdk.deleteInvoice( "EalP4", "755890", invoiceFlag );
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
					expect( gateways ).toBeArray();
					expect( gateways ).toBeEmpty();
				});
				it( "can list estimates" , function(){
					var estimates = sdk.getEstimatesList( "EalP4" );
					expect ( estimates ).toBeArray();
				});
				it( "can get an estimate by id" , function(){
					var estimate = sdk.getEstimateById( "EalP4", "258237" );
					expect ( estimate.invoiced ).toBe( false );
				});
				it( "can create an estimate" , function(){
					var estimateInfo = {};
					estimateInfo[ "email" ] = "test@example";
					estimateInfo[ "customerid" ] = "156482";
					estimateInfo[ "create_date" ] = "2017-09-13";
					//var estimate = sdk.createEstimate( "EalP4", estimateInfo );
					//expect ( estimate.status ).toBe( 1 );
				});
				it( "can update an estimate" , function(){
					var estimateInfo = {};
					estimateInfo[ "customerid" ] = "156482";
					estimateInfo[ "create_date" ] = "2017-09-12";
					var estimate = sdk.updateEstimate( "EalP4", "260285", estimateInfo );
					expect ( estimate.ui_status ).toBe( "draft" );
				});
				it( "can delete an estimate" , function(){
					var estimateFlag = {};
					estimateInfo[ "vis_state" ] = 1;
					//var estimate = sdk.deleteEstimate( "EalP4", "260285", estimateInfo );
				});
				it( "can list items" , function(){
					var items = sdk.getItemsList( "EalP4" );
					expect ( items ).toBeArray();
					//writeDump( items );
				});
				it( "can get an item by id" , function(){
					var item = sdk.getItemById( "EalP4", "123456" );
					expect ( item ).toBeEmpty();
				});
				it( "can create a single item" , function(){
					var itemInfo = {};
					itemInfo[ "name" ] = "Test item";
					//var item = sdk.createItem( "EalP4", itemInfo );
					//expect ( item ).toBeEmpty();
				});
				it( "can update an item" , function(){
					var itemDetails = {};
					var item = {};
					itemDetails[ "name" ] = "Updated item";
					item[ "item" ] = itemDetails
					var itemResult = sdk.updateItem( "EalP4", "186088", item );
					expect ( itemResult.name ).toBe( "Updated item" );
				});
				it( "can delete an item" , function(){
					var item = {};
					var itemDetails = {};
					itemDetails[ "vis_state" ] = 1; 
					item[ "item" ] = itemDetails;
					//sdk.deleteItem( "EalP4", "186088", item );
				});
				it( "can list payments" , function(){
					var payments = sdk.getPaymentsList( "EalP4" );
					expect ( payments ).toBeArray();
				});
				it( "can get a payment by id" , function(){
					var payment = sdk.getPaymentById( "EalP4", "123456" );
					expect ( payment ).toBeEmpty();
				});
				it( "can create a payment" , function(){
					var paymentDetails = {};
					var payment = {};
					var amount[ "amount" ] = "10.00";
					paymentDetails[ "invoiceid" ] = 725686;
					paymentDetails[ "amount" ] = amount;
					paymentDetails[ "date" ] = "2017-09-15";
					paymentDetails[ "type" ] = "Check";
					payment[ "payment" ] = paymentDetails;
					//var paymentResult = sdk.createPayment( "EalP4", payment );
					//expect ( paymentResult.type ).toBe( "Check" );
				});
				it( "can update a payment" , function(){
					var paymentDetails = {};
					var payment = {};
					paymentDetails[ "invoiceid" ] = 755890;
					payment[ "payment" ] = paymentDetails;
					//var paymentResult = sdk.updatePayment( "EalP4", 136088, payment );
					//expect ( paymentResult.invoiceid ).toBe( 755890 );
				});
				it( "can delete a payment" , function(){
					var paymentDetails = {};
					var payment = {};
					paymentDetails[ "vis_state" ] = 1;
					payment[ "payment" ] = paymentDetails;
					//sdk.deletePayment( "EalP4", 136088, payment );
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
				});
			});
		});
	}
}