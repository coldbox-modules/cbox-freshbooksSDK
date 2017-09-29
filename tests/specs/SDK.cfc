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
				expect( sdk.getAuthenticationCredentials() ).notToBeEmpty();
				expect( sdk.getAuthenticationCredentials() ).toBeStruct();
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
					var clientDetails               = {};
					clientDetails[ "fname" ]        = "Carlos";
					clientDetails[ "email" ]        = "Carlos@ortus.com";
					clientDetails[ "organization" ] = "Ortus";
					clientDetails[ "home_phone" ]   = "8326754346";
					var newClient[ "client"]        = clientDetails;
					var result                      = sdk.createSingleClient( "EalP4", newClient );
				});
				it( "can update a single client" , function(){
					var clientDetails            = {};
					clientDetails[ "fname" ]     = "Alexis";
					var updateClient[ "client" ] = clientDetails;
					var result                   = sdk.updateSingleClient( "EalP4", "180007", updateClient );
					expect ( result.fname ).toBe ( "Alexis" );
				});
				it( "can delete a single client" , function(){
					var clientDetails             = {};
					clientDetails[ "vis_state" ]  = 1;
					var deleteClient [ "client" ] = clientDetails;
					sdk.deleteSingleClient( "EalP4", "164816", deleteClient );
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
					var expenseDetails                     = {};
					expenseDetails[ "amount" ][ "amount" ] = 49.991;
					expenseDetails[ "categoryid" ]         = "5094363";
					expenseDetails[ "staffid" ]            = 1;
					expenseDetails[ "date" ]               = "2017-09-28";
					var expense[ "expense" ]               = expenseDetails;
					//var result                           = sdk.createExpense( "EalP4", expense );
					//expect ( result.categoryid ).toBe( "5094363" );
				});
				it( "can update a single expense" , function(){
					var expenseDetails         = {};
					expenseDetails[ "vendor" ] = "Other Vendor";
					var expense[ "expense"]    = expenseDetails;
					var result                 = sdk.updateExpense( "EalP4", "1119673", expense );
					expect ( result.vendor ).toBe( "Other Vendor" );
				});
				it( "can delete a single expense" , function(){
					var expenseDetails            = {};
					expenseDetails[ "vis_state" ] = 1;
					var expense [ "expense" ]     = expenseDetails;
					//sdk.deleteExpense( "EalP4", "1119673", expense );
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
					var invoiceDetails              = {};
					invoiceDetails[ "email" ]       = "testingInvoice2@ortus.com";
					invoiceDetails[ "customerid" ]  = "156482";
					invoiceDetails[ "create_date" ] = "2017-09-28";
					invoice[ "invoice"]             = invoiceDetails;
					
					//var result                    = sdk.createInvoice( "EalP4", invoice );
					//expect ( result.auto_bill ).notToBe( true );
				});
				it( "can update a single invoice" , function(){
					var invoiceDetails              = {};
					invoiceDetails[ "customerid" ]  = "156482";
					invoiceDetails[ "create_date" ] = "2017-09-12";
					var invoice[ "invoice"]         = invoiceDetails;
					var result                      = sdk.updateInvoice( "EalP4", "755890", invoice );
				});
				it( "can delete an invoice" , function(){
					var invoiceFlag            = {};
					invoiceFlag[ "vis_state" ] = 1;
					var invoice[ "invoice"]    = invoiceFlag;
					//sdk.deleteInvoice( "EalP4", "755890", invoice );
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
					var estimateDetails              = {};
					estimateDetails[ "email" ]       = "test2@example";
					estimateDetails[ "customerid" ]  = "156482";
					estimateDetails[ "create_date" ] = "2017-09-28";
					estimate[ "estimate"]            = estimateDetails;

					var result = sdk.createEstimate( "EalP4", estimate );
					expect ( result.status ).toBe( 1 );
				});
				it( "can update an estimate" , function(){
					var estimateDetails              = {};
					estimateDetails[ "customerid" ]  = "156482";
					estimateDetails[ "create_date" ] = "2017-09-28";
					estimate[ "estimate"]            = estimateDetails;
					var result                       = sdk.updateEstimate( "EalP4", "260285", estimate );
					expect ( result.ui_status ).toBe( "draft" );
				});
				it( "can delete an estimate" , function(){
					var estimateFlag            = {};
					estimateFlag[ "vis_state" ] = 1;
					estimate[ "estimate"]       = estimateFlag;
					//sdk.deleteEstimate( "EalP4", "260285", estimate );
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
					var itemDetails       = {};
					itemDetails[ "name" ] = "One more item";
					var item [ "item" ]   = itemDetails;
					//var result          = sdk.createItem( "EalP4", item );
					//expect ( result ).notToBeEmpty();
				});
				it( "can update an item" , function(){
					var itemDetails       = {};
					itemDetails[ "name" ] = "Updated item";
					var item[ "item" ]    = itemDetails;
					var result            = sdk.updateItem( "EalP4", "186088", item );
					expect ( result.name ).toBe( "Updated item" );
				});
				it( "can delete an item" , function(){
					var item                   = {};
					var itemDetails            = {};
					itemDetails[ "vis_state" ] = 1; 
					item[ "item" ]             = itemDetails;
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
					var paymentDetails            = {};
					var amount[ "amount" ]        = "10.00";
					paymentDetails[ "invoiceid" ] = 725686;
					paymentDetails[ "amount" ]    = amount;
					paymentDetails[ "date" ]      = "2017-09-15";
					paymentDetails[ "type" ]      = "Check";
					var payment[ "payment" ]      = paymentDetails;
					//var result                  = sdk.createPayment( "EalP4", payment );
					//expect ( result.type ).toBe( "Check" );
				});
				it( "can update a payment" , function(){
					var paymentDetails            = {};
					var payment                   = {};
					paymentDetails[ "invoiceid" ] = 755890;
					payment[ "payment" ]          = paymentDetails;
					//var result                  = sdk.updatePayment( "EalP4", 136088, payment );
					//expect ( result.invoiceid ).toBe( 755890 );
				});
				it( "can delete a payment" , function(){
					var paymentDetails            = {};
					paymentDetails[ "vis_state" ] = 1;
					var payment[ "payment" ]      = paymentDetails;
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
				it( "can create a single tax" , function(){
					var taxDetails       = {};
					taxDetails[ "name" ] = "some tax";
					var tax[ "tax" ]     = taxDetails;
					//var result         = sdk.createTax( "EalP4", tax );
					//expect ( result.name ).toBe( "some tax" );
				});
				it( "can update a single tax" , function(){
					var taxDetails       = {};
					taxDetails[ "name" ] = "other tax";
					var tax[ "tax" ]     = taxDetails;
					var result           = sdk.updateTax( "EalP4", "12283", tax );
					expect ( result.name ).toBe( "other tax" );
				});
				it( "can delete a single tax" , function(){
					//sdk.deleteTax( "EalP4", "12282" );
				});
				it( "can list staff" , function(){
					var staffs = sdk.getStaffList( "EalP4" );
					expect ( staffs ).toBeArray();
				});
				it( "can get a staff member by id" , function(){
					var staff = sdk.getStaffById( "EalP4", "1" );
					expect ( staff ).notToBeEmpty();
				});
				it( "can update a staff member" , function(){
					var staffDetails               = {};
					staffDetails[ "organization" ] = "Ortus Solutions";
					var staff[ "staff" ]           = staffDetails;
					var result                     = sdk.updateStaff( "EalP4", 1, staff );
					expect ( result.organization ).toBe( "Ortus Solutions" );
				});
				it( "can delete a staff member" , function(){
					// this method has not been tested. I do not want to delete the only user :)
					var staffDetails = {};
					staffDetails[ "vis_state" ] = 1;
					//sdk.deleteStaff( "EalP4", 1, staffDetails );
				});
				it( "can list time entries" , function(){
					var timeEntries = sdk.getTimeEntries( "400641" );
					expect ( timeEntries ).toBeArray();
				});
				it( "can create a time entry" , function(){
					var entryDetails             = {};
					entryDetails[ "is_logged" ]  = true;
					entryDetails[ "duration" ]   = 7200;
					entryDetails[ "note" ]       = "stuff";
					entryDetails[ "started_at" ] = "2017-09-25T20:00:00.000z";
					entryDetails[ "client_id" ]  = "164810";
					entryDetails[ "project_id" ] = "831050";
					var entry[ "time_entry" ]    = entryDetails;
					//var result                 = sdk.createTimeEntry( "EalP4", "400641", entry );
					//expect ( result.duration ).toBe( 7200 );
				});
				it( "can update a time entry" , function(){
					var timeEntryDetails             = {};
					timeEntryDetails[ "is_logged" ]  = true;
					timeEntryDetails[ "duration" ]   = 600;
					timeEntryDetails[ "note" ]       = "updated Note";
					timeEntryDetails[ "started_at" ] = "2017-09-25T10:00:00.000z";
					timeEntryDetails[ "client_id" ]  = "164816";
					timeEntryDetails[ "project_id" ] = "831050";
					var timeEntry[ "time_entry" ]    = timeEntryDetails;
					//var result                     = sdk.updateTimeEntry( "EalP4", "400641", "831050", timeEntry );
					//expect ( result.duration ).toBe( 600 );
				});
				it( "can delete a time entry" , function(){
					//sdk.deleteTimeEntry( "EalP4", "400641", "831050" );
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