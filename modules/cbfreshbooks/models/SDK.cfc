/**
* This is the Freshbooks SDK class
*/
component accessors=true singleton threadsafe{
	
	/**
	 * The module settings
	 */
	property name="settings";

	/**
	 * Access token and refresh token
	 */
	property name="tokenAccess" default="";
	property name="refreshToken" default="";

	/**
	 * Authorization code
	 */
	property name="authorizationCode";

	/**
	 * Store the identity of the current user
	 */
	property name="identityInformation";

	// DI
	property name="log"          inject="logbox:logger:{this}";
	property name="cachebox"	 inject="cachebox";

	// Static Variables
	variables.API_URL 			= "https://api.freshbooks.com/auth/oauth/token/";
	variables.AUTHORIZATION_URL	= "https://my.freshbooks.com/service/auth/oauth/";
	variables.CACHE_KEY			= "fb_sdk_oauth_token";

	/**
	* Constructor
	* @settings The module settings
	* @settings.inject coldbox:modulesettings:cbfreshbooks
	* @cacheBox The CacheBox reference
	* @cachebox.inject cachebox
	*/
	function init( required settings, required cachebox ){
		variables.settings          = arguments.settings;

		// Load cache configured by user
		variables.cache 			= cachebox.getCache( arguments.settings.cacheName );

		return this;
	}

	/**
	 * Retrieve the authentication credentials for this modules
	 */
	function getAuthenticationCredentials(){
		return settings.authentication_credentials;
	}

	/**
	* Generate the authorization link to retrieve the authorization code
	* The user has to allow manually the access to the FreshBooks account and paste the authorization code into the module settings
	* @results String -> Authorization URL
	*/
	String function getLoginURL(){
		var strLoginURL = AUTHORIZATION_URL
 		 & "authorize?client_id=" & settings.authentication_credentials.clientID
 		 & "&response_type=code"
         & "&redirect_uri=" & settings.redirectURI;
		
		return strLoginURL;
	}

	/**
	* Do the authentication process and retrieve the token access from a given authorization code
	* Authenticate the first time, after that returns the struct stored in cache, if the token has expired call the refreshToken method
	* and get a new token access
	* @results struct = { access_token:string, expires_in:date, expires_in_raw:number, refresh_token:string, success:boolean, token_type:string } 
	*/
	struct function authenticate(){
		var tokenStruct = cache.get( variables.CACHE_KEY );
		if( !isNull( tokenStruct ) AND
			tokenStruct.success AND
			dateCompare( now(), parseDateTime( tokenStruct.expires_in ), "n" ) <= 0
		){
			return tokenStruct;
		} else if( len( getTokenAccess() ) AND len( getRefreshToken() ) ){
			return this.refreshToken( getRefreshToken() );
		}
		var body = {};
		body[ "grant_type" ]    = "authorization_code";
		body[ "client_secret" ] = "#settings.authentication_credentials.clientSecret#";
		body[ "code" ]          = "#settings.authentication_credentials.authorizationCode#";
		body[ "client_id" ]     = "#settings.authentication_credentials.clientID#";
		body[ "redirect_uri" ]  = "#settings.redirectURI#";

		var response = makeRequest( method="POST", url=API_URL, body=body, type="A" );
		return authResponse( response );
	}

	/**
	 * I take the refresh token from the autehntication procedure and get you a new access token.
	 * @refreshToken the most recent refresh token that has been provided
	 * @results struct = { access_token:string, expires_in:date, expires_in_raw:number, refresh_token:string, success:boolean, token_type:string } 
	 */
	 struct function refreshToken( required String refreshToken ){
		var body                = {};
		body[ "grant_type" ]    = "refresh_token";
		body[ "client_secret" ] = "#settings.authentication_credentials.clientSecret#";
		body[ "refresh_token" ] = arguments.refreshToken;
		body[ "client_id" ]     = "#settings.authentication_credentials.clientID#";
		body[ "redirect_uri" ]  = "#settings.redirectURI#";

		var response = makeRequest( method="POST", url=API_URL, body=body, type="A" );
		return authResponse( response );
	 }

	
	/**
	 * Manage response and build an struct with the token information and store it in the cache
	 * @response HTTP Response
	 * @results struct { success:boolean,  access_token, token_type, expires_in_raw, expires_in, refresh_token}
	 */
	 struct function authResponse( required response ){
	 	var stuResponse = {};
 		if ( !response.error ){
			//Insert the access token into the properties
			structInsert( stuResponse, "access_token",	response.response.access_token );
			structInsert( stuResponse, "token_type",	response.response.token_type );
			structInsert( stuResponse, "expires_in_raw",response.response.expires_in );
			structInsert( stuResponse, "expires_in",	 DateAdd("s", response.response.expires_in, Now()) );
			setTokenAccess( response.response.access_token );
			
			if ( structKeyExists( response.response, "refresh_token") ){
				structInsert( stuResponse, "refresh_token", response.response.refresh_token );
				setRefreshToken( response.response.refresh_token );
			}
			structInsert( stuResponse, "success", true );
		}
		else{
			structInsert( stuResponse, "access_token", "Authorization Failed " & response.message );
			structInsert( stuResponse, "success", false );
		}
		
		cache.set( variables.CACHE_KEY, stuResponse, 60,20 );

		return stuResponse;
	 }


	/**
	* Make a test call
	* It will be deleted later
	*/
	function testCall(){
		var endpoint = "https://api.freshbooks.com/test";
		var result   =  makeRequest( url=endpoint );

		if ( result.error ){
			throw result.message;
		}
		return result.response;

	}

	/**
	* Return the list of clients, if a 404 NOT FOUND error is thrown by the request, an empty array is returned
	* @accountID The account ID that the client belongs to
	* @results an array of structs with the list of clients -> clients [ {client1},{client2},{client3},... ]
	* @throws an error if something goes wrong with the request
	*/
	array function getClients( required String accountID ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &"/users/clients";
		var result   =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return var clients  = [];
			}
			throw result.message;
		}

		return result.response.response.result.clients;
	}

	/**
	* Retrieve a single client
	* @accountID The account ID that the client belongs to
	* @clientID ID of the client to retrieve
	* @results struct -> { allow_late_notifications, updated, last_activity, s_code, vat_number, pref_email, id, direct_link_token, s_province, lname, s_country, s_street2, statement_token, note, mob_phone, role, home_phone, last_login, company_industry, subdomain, email, username, fax, fname, vat_name, p_city, p_code, allow_late_fees, s_street, p_country, company_size, accounting_systemid, bus_phone, p_province, signup_date, language, level, notified, userid, p_street2, pref_gmail, vis_state, s_city, num_logins, organization, p_street, currency_code }
	*/
	struct function getSingleClient( required String accountID, required String clientID ){
		if( !len( arguments.accountID ) ){
			throw( "Account id cannot be null or empty");
		}
		if( !len( arguments.clientID ) ){
			throw( "Client id cannot be null or empty");
		}
		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
						"/users/clients/" & arguments.clientID;
		var result   =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.client;
	}

	/**
	* Create a single client
	* @accountID The account ID where the client will be created in
	* @userInfo The struct with the client's info to create a new entry
	* @results struct -> { allow_late_notifications, updated, last_activity, s_code, vat_number, pref_email, id, direct_link_token, s_province, lname, s_country, s_street2, statement_token, note, mob_phone, role, home_phone, last_login, company_industry, subdomain, email, username, fax, fname, vat_name, p_city, p_code, allow_late_fees, s_street, p_country, company_size, accounting_systemid, bus_phone, p_province, signup_date, language, level, notified, userid, p_street2, pref_gmail, vis_state, s_city, num_logins, organization, p_street, currency_code }
	*/
	struct function createSingleClient( required String accountID, required struct userInfo ){
		if( !len( userInfo )){
			throw( "UserInfo Struct cannot be null or empty");
		}
		if( !len( accountID ) ){
			throw( "Client id cannot be null or empty");
		}
		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
						"/users/clients";
		var result   =  makeRequest( method="POST", url=endpoint, body=arguments.userInfo);

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.client;

	}

	/**
	* Update single client
	* @userInfo The struct with the client's data to update
	* @accountID The account ID where the client belongs to
	* @clientID Id of the client to update
	* @results struct -> { allow_late_notifications, updated, last_activity, s_code, vat_number, pref_email, id, direct_link_token, s_province, lname, s_country, s_street2, statement_token, note, mob_phone, role, home_phone, last_login, company_industry, subdomain, email, username, fax, fname, vat_name, p_city, p_code, allow_late_fees, s_street, p_country, company_size, accounting_systemid, bus_phone, p_province, signup_date, language, level, notified, userid, p_street2, pref_gmail, vis_state, s_city, num_logins, organization, p_street, currency_code }
	*/
	struct function updateSingleClient( required String accountID, required String clientID, required struct userInfo ){
		var endpoint                 = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
										"/users/clients/"& arguments.clientID;
				
		var result                   =  makeRequest( method="PUT", url=endpoint, body=arguments.userInfo );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.client;

	}

	/**
	* Delete single client -> It passes an struct with a key "vis_state" = 1 to delete that client
	* @accountID The account ID where the client belongs to
	* @clientID Id of the client to delete
	* @userFlag The struct with key 'vis_state' set to 1 to delete a single client
	* @results struct -> { allow_late_notifications, updated, last_activity, s_code, vat_number, pref_email, id, direct_link_token, s_province, lname, s_country, s_street2, statement_token, note, mob_phone, role, home_phone, last_login, company_industry, subdomain, email, username, fax, fname, vat_name, p_city, p_code, allow_late_fees, s_street, p_country, company_size, accounting_systemid, bus_phone, p_province, signup_date, language, level, notified, userid, p_street2, pref_gmail, vis_state, s_city, num_logins, organization, p_street, currency_code }
	*/
	function deleteSingleClient( required String accountID, required String clientID, required struct userFlag ){
		var userInfo        = {};
		var endpoint        = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
								"/users/clients/"& arguments.clientID;
		var result          =  makeRequest( method="PUT", url=endpoint, body=arguments.userFlag );

		if( result.error ){
			throw result.message;
		}
	}

	/**
	* Retrieve the list of expenses
	* @accountID The account ID of the expenses to list
	* @results an array of structs with the list of expenses -> expenses [ {expense1},{expense2},{expense3},... ]
	* expense -> { categoryid, markup_percent, projectid, clientid, isduplicate, taxName2, taxName1, taxPercent1, profileid, taxPercent2, id, invoiceid, account_name, taxAmount2, taxAmount1, vis_state, status, bank_name, updated, vendor, has_receipt, ext_systemid, staffid, date, transactionid, include_receipt, accounting_systemid, background_jobid, notes, ext_invoiceid, amount, expenseid, compounded_tax, accountid }
	*/
	array function getExpensesList( required String accountID ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/expenses/expenses";	
		var result   =  makeRequest( url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return var expenses = [];
			}
			throw result.message;
		}
		return result.response.response.result.expenses;

	}

	/**
	* Returns a single expense, if it does not exist returns an empty struct
	* @accountID Account Id where the expense belong to
	* @expenseID Id of the expense to return
	* @results expense -> { categoryid, markup_percent, projectid, clientid, isduplicate, taxName2, taxName1, taxPercent1, profileid, taxPercent2, id, invoiceid, account_name, taxAmount2, taxAmount1, vis_state, status, bank_name, updated, vendor, has_receipt, ext_systemid, staffid, date, transactionid, include_receipt, accounting_systemid, background_jobid, notes, ext_invoiceid, amount, expenseid, compounded_tax, accountid }
	*/
	struct function getExpenseById( required String accountID, required String expenseID ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						"/expenses/expenses/"& arguments.expenseID;	
		var result   =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.expense;
	}

	/**
	* Create an expense
	* @expenseInfo The struct with the expense's info to create a new entry
	* @accountID The account ID where the expense will be created in
	* @results expense -> { categoryid, markup_percent, projectid, clientid, isduplicate, taxName2, taxName1, taxPercent1, profileid, taxPercent2, id, invoiceid, account_name, taxAmount2, taxAmount1, vis_state, status, bank_name, updated, vendor, has_receipt, ext_systemid, staffid, date, transactionid, include_receipt, accounting_systemid, background_jobid, notes, ext_invoiceid, amount, expenseid, compounded_tax, accountid }
	*/
	struct function createExpense( required String accountID, required struct expenseInfo ){
		var newExpense         = {};
		var endpoint           = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
									"/expenses/expenses";
		var result             =  makeRequest( method="POST", url=endpoint, body=arguments.expenseInfo );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.expense;
	}

	/**
	* Update an expense
	* @accountID The account ID associated with the expense that will be updated
	* @expenseID ID of the expense to update
	* @expenseInfo The struct with the expense's info to create a new entry
	* @results expense -> { categoryid, markup_percent, projectid, clientid, isduplicate, taxName2, taxName1, taxPercent1, profileid, taxPercent2, id, invoiceid, account_name, taxAmount2, taxAmount1, vis_state, status, bank_name, updated, vendor, has_receipt, ext_systemid, staffid, date, transactionid, include_receipt, accounting_systemid, background_jobid, notes, ext_invoiceid, amount, expenseid, compounded_tax, accountid }
	*/
	struct function updateExpense( required String accountID, required String expenseID ,required struct expenseInfo ){
		var expense         = {};
		var endpoint        = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
								"/expenses/expenses/" & arguments.expenseID;		
		var result          =  makeRequest( method="PUT", url=endpoint, body=arguments.expenseInfo );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.expense;

	}

	/**
	* Delete an expense
	* @accountID The account ID associated with the expense will be deleted
	* @expenseID ID of the expense to delete
	* @expenseFlag The struct with the key 'vis_state' set to 1 to delete an expense
	* @results expense -> { categoryid, markup_percent, projectid, clientid, isduplicate, taxName2, taxName1, taxPercent1, profileid, taxPercent2, id, invoiceid, account_name, taxAmount2, taxAmount1, vis_state, status, bank_name, updated, vendor, has_receipt, ext_systemid, staffid, date, transactionid, include_receipt, accounting_systemid, background_jobid, notes, ext_invoiceid, amount, expenseid, compounded_tax, accountid }
	*/
	function deleteExpense( required String accountID, required String expenseID ,required struct expenseFlag ){
		var expense         = {};
		var endpoint        = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
								"/expenses/expenses/" & arguments.expenseID;
		var result          =  makeRequest( method="PUT", url=endpoint, body=arguments.expenseFlag );

		if( result.error ){
			throw result.message;
		}
	}

	/**
	* Get the list of invoices
	* @accountID The account ID of the invoices to list
	* @results an array of structs with the list of invoices -> invoices [ {invoice1},{invoice2},{invoice3},... ]
	* invoice -> { status, deposit_percentage, create_date, outstanding, payment_status, street, code, ownerid, vat_number, id, gmail, vat_name, v3_status, discount_description, dispute_status, lname, deposit_status, ext_archive, template, basecampid, sentid, show_attachments, vis_state, current_organization, province, due_date, updated, terms, description, parent, last_order_status, street2, deposit_amount, paid, invoiceid, discount_total, address, invoice_number, customerid, discount_value, accounting_systemid, organization, due_offset_days, language, po_number, display_status, created_at, auto_bill, date_paid, amount, estimateid, city, currency_code, country, autobill_status, generation_date, return_uri, fname, notes, payment_details, accountid }
	*/
	array function getInvoicesList( required String accountID ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/invoices/invoices";
		var result   =  makeRequest( url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return var invoices = [];
			}
			throw result.message;
		}
		return result.response.response.result.invoices;
	}

	/**
	* Returns a single invoice if it exists
	* @accountID Account Id where the invoice belong to
	* @invoiceID Id of the invoice to return
	* @results invoice -> { status, deposit_percentage, create_date, outstanding, payment_status, street, code, ownerid, vat_number, id, gmail, vat_name, v3_status, discount_description, dispute_status, lname, deposit_status, ext_archive, template, basecampid, sentid, show_attachments, vis_state, current_organization, province, due_date, updated, terms, description, parent, last_order_status, street2, deposit_amount, paid, invoiceid, discount_total, address, invoice_number, customerid, discount_value, accounting_systemid, organization, due_offset_days, language, po_number, display_status, created_at, auto_bill, date_paid, amount, estimateid, city, currency_code, country, autobill_status, generation_date, return_uri, fname, notes, payment_details, accountid }
	*/
	struct function getInvoiceById( required String accountID, required String invoiceID ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						"/invoices/invoices/"& arguments.invoiceID;
		var result   =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.invoice;
	}

	/**
	* Create an invoice
	* @accountID The account ID associated with the invoice that will be created
	* @invoiceInfo The struct with the invoice's info to create a new entry
	* @results invoice -> { status, deposit_percentage, create_date, outstanding, payment_status, street, code, ownerid, vat_number, id, gmail, vat_name, v3_status, discount_description, dispute_status, lname, deposit_status, ext_archive, template, basecampid, sentid, show_attachments, vis_state, current_organization, province, due_date, updated, terms, description, parent, last_order_status, street2, deposit_amount, paid, invoiceid, discount_total, address, invoice_number, customerid, discount_value, accounting_systemid, organization, due_offset_days, language, po_number, display_status, created_at, auto_bill, date_paid, amount, estimateid, city, currency_code, country, autobill_status, generation_date, return_uri, fname, notes, payment_details, accountid }
	*/
	struct function createInvoice( required String accountID, required struct invoiceInfo ){
		var endpoint           = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
									"/invoices/invoices";		
		var result             =  makeRequest( method="POST", url=endpoint, body=arguments.invoiceInfo );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.invoice;
	}

	/**
	* Update an invoice
	* @accountID The account ID associated with the invoice that will be updated
	* @invoiceID Id of the invoice to update
	* @invoiceInfo The struct with the invoice's info to create a new entry
	* @results invoice -> { status, deposit_percentage, create_date, outstanding, payment_status, street, code, ownerid, vat_number, id, gmail, vat_name, v3_status, discount_description, dispute_status, lname, deposit_status, ext_archive, template, basecampid, sentid, show_attachments, vis_state, current_organization, province, due_date, updated, terms, description, parent, last_order_status, street2, deposit_amount, paid, invoiceid, discount_total, address, invoice_number, customerid, discount_value, accounting_systemid, organization, due_offset_days, language, po_number, display_status, created_at, auto_bill, date_paid, amount, estimateid, city, currency_code, country, autobill_status, generation_date, return_uri, fname, notes, payment_details, accountid }
	*/
	struct function updateInvoice( required String accountID, required String invoiceID, required struct invoiceInfo ){
		var endpoint        = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
								"/invoices/invoices/" & arguments.invoiceID;
		var result          =  makeRequest( method="PUT", url=endpoint, body=arguments.invoiceInfo );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.invoice;
	}

	/**
	* Delete an invoice
	* @accountID The account ID associated with the invoice that will be deleted
	* @invoiceID Id of the invoice to delete
	* @invoiceFlag The struct with the invoice's info to update an existing entry
	*/
	function deleteInvoice( required String accountID, required String invoiceID, required struct invoiceFlag ){
		var endpoint        = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
								"/invoices/invoices/" & arguments.invoiceID;
		var result          =  makeRequest( method="PUT", url=endpoint, body=arguments.invoiceFlag );

		if( result.error ){
			throw result.message;
		}
	}

	/**
	* Get the list of expense categories
	* @accountID The account ID of the expense categories to list
	* @results array [ {category:string, created_at:string, updated_at:string, categoryid:number, is_editable:boolean,
	* 									is_cogs:boolean, parentid, vis_state:number, id:number } , {category2}, ... ]
	*/
	array function getExpenseCategoriesList( required String accountID ){
		var endpoint              = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/expenses/categories";
		var result                =  makeRequest( url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return var expenseCategoriesList = [];
			}
			throw result.message;
		}
		return result.response.response.result.categories;
	}

	/**
	* Returns a single expense category if it exists
	* @accountID Account Id where the expense category belongs to
	* @expenseCategoryID Id of the expense category to return
	* @results struct {category:string, created_at:string, updated_at:string, categoryid:number, is_editable:boolean,
	* 									is_cogs:boolean, parentid, vis_state:number, id:number }
	*/
	struct function getExpenseCategoryById( required String accountID, required String expenseCategoryID ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						"/expenses/categories/"& arguments.expenseCategoryID;
		var result   =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.category;
	}

	/**
	* Get the list of gateways
	* @accountID The account ID of the gateways to list
	* @results gateways -> [ { sgid, connectionid, gateway_name, id }, ... ]
	*/
	array function getGatewaysList( required String accountID ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/system/gateways";
		var result   =  makeRequest( url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return var gatewaysList = [];
			}
			throw result.message;
		}
		return result.response.response.result.gateways;
	}

	/**
	* Get the list of estimates
	* @accountID The account ID of the estimates to list
	* @results an array of structs -> estimates: [ estimate:{ province, code, create_date, street, ownerid, vat_number, id, invoiced, city, lname, ext_archive, template, created_at, vis_state, current_organization, status, estimate_number, updated, terms, description, vat_name, street2, sentid, ui_status, discount_total, address, accepted, customerid, discount_value, accounting_systemid, language, po_number, country, notes, amount, estimateid, display_status, organization, rich_proposal, fname, reply_status, currency_code }, ... ]
	*/
	array function getEstimatesList( required String accountID ){
		var endpoint      = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/estimates/estimates";
		var result        =  makeRequest( url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return var estimatesList = [];
			}
			throw result.message;
		}
		return result.response.response.result.estimates;
	}

	/**
	* Returns a single estimate if it exists
	* @accountID Account Id where the estimate belongs to
	* @estimateID Id of the estimate to return
	* @results estimate:{ province, code, create_date, street, ownerid, vat_number, id, invoiced, city, lname, ext_archive, template, created_at, vis_state, current_organization, status, estimate_number, updated, terms, description, vat_name, street2, sentid, ui_status, discount_total, address, accepted, customerid, discount_value, accounting_systemid, language, po_number, country, notes, amount, estimateid, display_status, organization, rich_proposal, fname, reply_status, currency_code }
	*/
	struct function getEstimateById( required String accountID, required String estimateID ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						"/estimates/estimates/"& arguments.estimateID;
		var result   =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.estimate;
	}

	/**
	* Create an estimate
	* @accountID The account ID associated with the estimate that will be created
	* @estimateInfo The struct with the estimate's info to create a new entry
	* @results estimate:{ province, code, create_date, street, ownerid, vat_number, id, invoiced, city, lname, ext_archive, template, created_at, vis_state, current_organization, status, estimate_number, updated, terms, description, vat_name, street2, sentid, ui_status, discount_total, address, accepted, customerid, discount_value, accounting_systemid, language, po_number, country, notes, amount, estimateid, display_status, organization, rich_proposal, fname, reply_status, currency_code }
	*/
	struct function createEstimate( required String accountID, required struct estimateInfo ){
		var endpoint             = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
									"/estimates/estimates";
		var result               =  makeRequest( method="POST", url=endpoint, body=arguments.estimateInfo );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.estimate;
	}

	/**
	* Update an estimate
	* @accountID The account ID associated with the estimate that will be updated
	* @estimateID ID of the estimate that will be updated
	* @estimateInfo The struct with the estimate's info to update
	* @results estimate:{ province, code, create_date, street, ownerid, vat_number, id, invoiced, city, lname, ext_archive, template, created_at, vis_state, current_organization, status, estimate_number, updated, terms, description, vat_name, street2, sentid, ui_status, discount_total, address, accepted, customerid, discount_value, accounting_systemid, language, po_number, country, notes, amount, estimateid, display_status, organization, rich_proposal, fname, reply_status, currency_code }
	*/
	struct function updateEstimate( required String accountID, required String estimateID, required struct estimateInfo ){
		var estimate          = {};
		var endpoint          = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
								"/estimates/estimates/" & arguments.estimateID;
		var result            =  makeRequest( method="PUT", url=endpoint, body=arguments.estimateInfo );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.estimate;
	}

	/**
	* Delete an estimate
	* @accountID The account ID associated with the estimate that will be deleted
	* @estimateID ID of the estimate that will be deleted
	* @estimateFlag The struct with key 'vis_state' set to 1 to delete an existing estimate
	*/
	function deleteEstimate( required String accountID, required String estimateID, required struct estimateFlag ){
		var estimate          = {};
		var endpoint          = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
								"/estimates/estimates/" & arguments.estimateID;
		var result =  makeRequest( method="PUT", url=endpoint, body=arguments.estimateFlag );

		if( result.error ){
			throw result.message;
		}
	}

	/**
	* Get the list of items
	* @accountID The account ID of the items to list
	* @results array of structs -> items: [ item: { itemid, accounting_systemid, updated, name, qty, inventory,unit_cost: { amount, code }, tax1, vis_state, tax2, id, description }, ... ]
	*/
	array function getItemsList( required String accountID ){
		var endpoint  = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/items/items";
		var result    =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return var itemsList = [];
			}
			throw result.message;
		}
		return result.response.response.result.items;
	}

	/**
	* Returns a single item if it exists
	* @accountID Account Id where the item belongs to
	* @itemID Id of the item to return
	* @results item: { itemid, accounting_systemid, updated, name, qty, inventory,unit_cost: { amount, code" }, tax1, vis_state, tax2, id, description }
	*/
	struct function getItemById( required String accountID, required String itemID ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						"/items/items/"& arguments.itemID;
		var result   =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.item;
	}

	/**
	* Create item
	* @accountID The account ID associated with the item that will be created
	* @itemInfo struct with the item's info to create a new entry
	* @results item: { itemid, accounting_systemid, updated, name, qty, inventory,unit_cost: { amount, code" }, tax1, vis_state, tax2, id, description }
	*/
	struct function createItem( required String accountID, required struct itemInfo ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/items/items";
		var result =  makeRequest( method="POST", url=endpoint, body=arguments.itemInfo );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.item;
	}

	/**
	* Update an item
	* @accountID The account ID associated with the item to update
	* @itemID ID of the item to update
	* @itemInfo struct with the item's info to update
	* @results item: { itemid, accounting_systemid, updated, name, qty, inventory,unit_cost: { amount, code" }, tax1, vis_state, tax2, id, description }
	*/
	struct function updateItem( required String accountID, required String itemID, required struct itemInfo ){
		var newItem  = {};
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						"/items/items/" & arguments.itemID;
		
		var result   =  makeRequest( method="PUT", url=endpoint, body=arguments.itemInfo );
		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.item;
	}

	/**
	* Delete item
	* @accountID The account ID of the items to list
	* @itemID ID of the item to delete
	* @itemInfo struct with the item's key 'vis_state' set to 1 to delete its entry
	*/
	function deleteItem( required String accountID, required String itemID, required struct itemInfo ){
		var newItem  = {};
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & 
						"/items/items/" & arguments.itemID;
		
		var result   =  makeRequest( method="PUT", url=endpoint, body=arguments.itemInfo );
		if( result.error ){
			throw result.message;
		}
	}

	/**
	* Get the list of payments
	* @accountID The account ID of the payments to list
	* @results array of structs -> payments: [ { payment: { orderid, accounting_systemid, updated, invoiceid, creditid, amount { amount, code }, clientid, vis_state, logid, note, overpaymentid, gateway, date, transactionid, from_credit, type, id } , ... ]
	*/
	array function getPaymentsList( required String accountID ){
		var endpoint     = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/payments/payments";
		var result       =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return var paymentsList = [];
			}
			throw result.message;
		}
		return result.response.response.result.payments;
	}

	/**
	* Returns a single payment if it exists
	* @accountID Account Id where the payment belongs to
	* @itemID Id of the payment to return
	* @results payment: { orderid, accounting_systemid, updated, invoiceid, creditid, amount { amount, code }, clientid, vis_state, logid, note, overpaymentid, gateway, date, transactionid, from_credit, type, id }
	*/
	struct function getPaymentById( required String accountID, required String paymentID ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
		"/estimates/estimates/"& arguments.paymentID;
		
		var result   =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.payment;
	}

	/**
	* Create payment
	* @accountID The account ID Associated with the payment to create
	* @paymentInfo struct with the payment's info to create a new entry
	* @results payment: { orderid, accounting_systemid, updated, invoiceid, creditid, amount { amount, code }, clientid, vis_state, logid, note, overpaymentid, gateway, date, transactionid, from_credit, type, id }
	*/
	struct function createPayment( required String accountID, required struct paymentInfo ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/payments/payments";
		var result   =  makeRequest( method="POST", url=endpoint, body=arguments.paymentInfo );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.payment;
	}

	/**
	* Update payment
	* @accountID The account ID Associated with the payment to update
	* @paymentID ID of the payment to update
	* @paymentInfo struct with the payment's info to update
	* @results payment: { orderid, accounting_systemid, updated, invoiceid, creditid, amount { amount, code }, clientid, vis_state, logid, note, overpaymentid, gateway, date, transactionid, from_credit, type, id }
	*/
	struct function updatePayment( required String accountID, required String paymentID, required struct paymentInfo ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & 
						"/payments/payments/" & arguments.paymentID;
		var result   =  makeRequest( method="PUT", url=endpoint, body=arguments.paymentInfo );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.payment;
	}

	/**
	* Delete payment
	* @accountID The account ID Associated with the payment to delete
	* @paymentID ID of the payment to delete
	* @paymentInfo struct with the key 'vis_state' set to 1 to delete its entry
	*/
	function deletePayment( required String accountID, required String paymentID, required struct paymentInfo ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & 
						"/payments/payments/" & arguments.paymentID;
		var result   =  makeRequest( method="PUT", url=endpoint, body=arguments.paymentInfo );

		if( result.error ){
			throw result.message;
		}
	}

	/**
	* Get the list of taxes
	* @accountID The account ID of the taxes to list
	* @results an array of structs -> taxes: [ tax: { accounting_systemid, updated, name, number, taxid, amount, compound, id }, ... ]
	*/
	array function getTaxesList( required String accountID ){
		var endpoint  = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/taxes/taxes";
		var result    =  makeRequest(  url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return var taxesList = [];
			}
			throw result.message;
		}
		return result.response.response.result.taxes;
	}

	/**
	* Returns a single tax if it exists
	* @accountID Account Id where the tax belongs to
	* @itemID Id of the tax to return
	* @results tax: { accounting_systemid, updated, name, number, taxid, amount, compound, id }
	*/
	struct function getTaxById( required String accountID, required String taxID ){
		var endpoint               = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
										"/taxes/taxes/"& arguments.taxID;
		var result                 =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.tax;
	}

	/**
	* Create tax
	* @accountID The account ID Associated with the tax to create
	* @taxInfo struct with the tax's info to create a new entry
	* @results tax: { accounting_systemid, updated, name, number, taxid, amount, compound, id }
	*/
	struct function createTax( required String accountID, required struct taxInfo ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/taxes/taxes";
		var result   =  makeRequest( method="POST", headers=headers, url=endpoint, body=arguments.taxInfo );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.tax;
	}

	/**
	* update tax
	* @accountID The account ID Associated with the tax to update
	* @taxID Id of the tax to update
	* @taxInfo struct with the tax's info to update a new entry
	* @results tax: { accounting_systemid, updated, name, number, taxid, amount, compound, id }
	*/
	struct function updateTax( required String accountID, required String taxID, required struct taxInfo ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						"/taxes/taxes/" & arguments.taxID;
		var result   =  makeRequest( method="PUT", url=endpoint, body=arguments.taxInfo );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.tax;
	}

	/**
	* delete tax
	* @accountID The account ID Associated with the tax to delete
	* @taxID Id of the tax to delete
	* @taxInfo struct with the tax's info to delete
	*/
	function deleteTax( required String accountID, required String taxID ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						"/taxes/taxes/" & arguments.taxID;
		var result   =  makeRequest( method="DELETE", url=endpoint );

		if( result.error ){
			throw result.message;
		}
	}

	/**
	* Get the list of the staff
	* @accountID The account ID of the staff to list
	* @results array of structs -> [ {fax, rate, num_logins, api_token, id, note, display_name, lname, mob_phone, last_login, home_phone, email, 
	* 								 username, updated, p_province, p_city, p_code, p_country, accounting_systemid, bus_phone, signup_date,
	* 				 				 language, level, userid, p_street2, vis_state, fname, organization, p_street, currency_code}, ... ]
	*/
	array function getStaffList( required String accountID ){
		var endpoint  = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/users/staffs";
		var result    =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return var staffList = [];
			}
			throw result.message;
		}
		return result.response.response.result.staff;
	}

	/**
	* Returns a single staff member if it exists
	* @accountID Account Id where the staff member belongs to
	* @staffID Id of the staff member to return
	* @results struct {fax, rate, num_logins, api_token, id, note, display_name, lname, mob_phone, last_login, home_phone, email, username,
	* 				   updated, p_province, p_city, p_code, p_country, accounting_systemid, bus_phone, signup_date, language, level, userid,
	* 				   p_street2, vis_state, fname, organization, p_street, currency_code}
	*/
	struct function getStaffById( required String accountID, required String staffID ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						"/users/staffs/"& arguments.staffID;
		var result   =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.staff;
	}

	/**
	* update a staff member
	* @accountID The account ID Associated with the staff member to update
	* @staffID Id of the staff member to update
	* @staffInfo struct with the staff's info to update a new entry
	* @results struct {fax, rate, num_logins, api_token, id, note, display_name, lname, mob_phone, last_login, home_phone, email, username,
	* 				   updated, p_province, p_city, p_code, p_country, accounting_systemid, bus_phone, signup_date, language, level, userid,
	* 				   p_street2, vis_state, fname, organization, p_street, currency_code}
	*/
	struct function updateStaff( required String accountID, required String staffID, required struct staffInfo ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						"/users/staffs/" & arguments.staffID;
		var result   =  makeRequest( method="PUT", url=endpoint, body=arguments.staffInfo );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.staff;
	}

	/**
	* delete a staff member
	* @accountID The account ID Associated with the staff member to delete
	* @staffID Id of the staff member to delete
	* @staffInfo struct with the staff's info to delete
	* @results struct {fax, rate, num_logins, api_token, id, note, display_name, lname, mob_phone, last_login, home_phone, email, username,
	* 				   updated, p_province, p_city, p_code, p_country, accounting_systemid, bus_phone, signup_date, language, level, userid,
	* 				   p_street2, vis_state, fname, organization, p_street, currency_code}
	*/
	function deleteStaff( required String accountID, required String staffID, required struct staffInfo ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						"/users/staffs/" & arguments.taxID;
		var result   =  makeRequest( method="PUT", url=endpoint, body=arguments.staffInfo );

		if( result.error ){
			throw result.message;
		}
	}

	/**
	* Get the list of the projects associated with a business ID
	* @businessID The business ID associated with the projects to list
	* @results an array of structs -> projects: [ project: { due_date, logged_duration, fixed_price, group, description, complete, title, project_type, budget, updated_at, sample, services, rate, internal, client_id, active, created_at, id, billing_method }  ]
	*/
	array function getProjectsList( required String businessID ){
		var endpoint = "https://api.freshbooks.com/projects/business/" & 
		arguments.businessID & "/projects";
		var result   =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return varprojectsList;
			}
			throw result.message;
		}
		return result.response.projects;
	}

	/**
	* Get time entries
	* @businessID The business ID associated with the time entries
	* @results struct -> time_entries { note, duration, project_id, client_id, is_logged, started_at, active, id, timer { id, is_running},
	* 									meta { pages, total_logged, total_unbilled, per_page, total, page } }
	*/
	array function getTimeEntries( required String businessID ){
		var endpoint    = "https://api.freshbooks.com/timetracking/business/" & arguments.businessID & "/time_entries";
		var result      =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return var timeEntries = [];
			}
			throw result.message;
		}
		return result.response.time_entries;
	}

	/**
	* Create time entry
	* @accountID The account ID Associated with the time entry to create
	* @businessID The business ID associated with the time entry to create
	* @timeEntryInfo struct with the time entry's info to create a new entry
	* @results struct -> time_entry { note, duration, project_id, client_id, is_logged, started_at, active, id, timer { id, is_running},
	* 									meta { pages, total_logged, total_unbilled, per_page, total, page } }
	*/
	struct function createTimeEntry( required String accountID, required String businessID, required struct timeEntryInfo ){
		var endpoint = "https://api.freshbooks.com/timetracking/business/" & arguments.businessID & "/time_entries";
		var result   =  makeRequest( method="POST", url=endpoint, body=arguments.timeEntryInfo );

		if( result.error ){
			throw result.message;
		}
		return result.response.time_entry;
	}

	/**
	* Update time entry
	* @accountID The account ID Associated with the time entry to update
	* @businessID The business ID associated with the time entry to update
	* @timeEntryID Id of the time entry to update
	* @timeEntryInfo struct with the time entry's info to update
	* @results struct -> time_entry { note, duration, project_id, client_id, is_logged, started_at, active, id, timer { id, is_running},
	* 									meta { pages, total_logged, total_unbilled, per_page, total, page } }
	*/
	struct function updateTimeEntry( required String accountID, required String businessID, required String timeEntryID, required struct timeEntryInfo ){
		var endpoint = "https://api.freshbooks.com/timetracking/business/" & arguments.businessID &
						"/time_entries/" & arguments.timeEntryID;
		var result   =  makeRequest( method="PUT", url=endpoint, body=arguments.timeEntryInfo );

		if( result.error ){
			throw result.message;
		}
		return result.response.time_entry;
	}

	/**
	* Delete time entry
	* @accountID The account ID Associated with the time entry to create
	* @businessID The business ID associated with the time entry to create
	* @timeEntryID Id of the time entry to update
	*/
	function deleteTimeEntry( required String accountID, required String businessID, required String timeEntryID ){
		var endpoint = "https://api.freshbooks.com/timetracking/business/" & arguments.businessID &
						"/time_entries/" & arguments.timeEntryID;
		var result   =  makeRequest( method="DELETE", url=endpoint, body=arguments.timeEntryInfo );

		if( result.error ){
			throw result.message;
		}
	}

	/**
	* Returns a single project if it exists
	* @businessID The business ID associated with the projects to list
	* @projectID ID of the project to retrieve
	* @results project: { due_date, logged_duration, fixed_price, group, description, complete, title, project_type, budget, updated_at, sample, services, rate, internal, client_id, active, created_at, id, billing_method } 
	*/
	struct function getProjectById( required String businessID, required String projectID ){
		var endpoint = "https://api.freshbooks.com/projects/business/" & arguments.businessID & 
						"/projects/" & arguments.projectID;
		var result   =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.project;
	}

	/**
	* Returns a single task if it exists
	* @accountID Account Id where the task belongs to
	* @taskID ID of the task to retrieve
	* @results task: { updated, description, vis_state, rate, taskid, billable, tname, tdesc, id, name }
	*/
	struct function getTaskById( required String accountID, required String taskID ){
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & 
						"/projects/tasks/" & arguments.taskID;
		var result   =  makeRequest( url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.task;
	}


	/**
	* Make a request to FreshBooks API
	* @method The HTTP method call
	* @url The url to make the request
	* @body The body contents of the request
	* @headers Request headers
	* @parameters Request parameters
	* @type Flag to determine the type of request, "A" for authenticaton request and "R" for other requests
	* @timeout Request Timeout
	* @results struct = { error:boolean, response:struct, message, reponseHeader:struct, rawResponse, stacktrace }
	*/
	private struct function makeRequest(
		string method = "GET",
		required string url,
		body = {},
		struct headers = structNew(),
		struct parameters = structNew(),
		string type = "R",
		numeric timeout = 15
	){
		var results = { 
			error 			= false,
			response 		= {},
			message 		= "",
			responseheader 	= {},
			rawResponse 	= "",
			stacktrace		= ""
		};
		var param 		= "";
		var jsonRegex 	= "^(\{|\[)(.)*(\}|\])$";

		// Default Api Version
		headers [ "Api-Version" ] = "alpha";

		// Default Content Type for Authorization request
		if( NOT structKeyExists( arguments.headers, "Content-Type" ) AND
			type == "A"
		 ){
			headers [ "Content-Type" ] = "application/json";
		}
		// Add a Bearer header if the type of request is equal to "R"
		else if ( type == "R" ){
			headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		}
		// Create HTTP object
		var oHTTP = new HTTP(
			method 			= arguments.method,
			url 			= arguments.url,
			charset 		= "utf-8",
			timeout 		= arguments.timeout,
			throwOnError 	= true
		);

		// Add Headers
		for( var thisHeader in arguments.headers ){
			oHTTP.addParam( type="header", name="#thisHeader#", value="#arguments.headers[ thisHeader ]#" );
		}

		// Add URL Parameters: encoded automatically by CF 
		for( var thisParam in arguments.parameters ){
			oHTTP.addParam( type="URL", name="#thisParam#", value="#arguments.parameters[ thisParam ]#" );
		}
		
		// Add Body
		if( len( arguments.body ) ){
			var bodyJSON = serializeJSON( arguments.body );
			oHTTP.addParam( type="body", value=bodyJSON );
		}

		// Make the request
		try{	
			var HTTPResults = oHTTP.send().getPrefix();
			// Set Results
			results.responseHeader 	= HTTPResults.responseHeader;
			results.rawResponse 	= HTTPResults.fileContent.toString();

			// Error Details found?
			results.message = HTTPResults.errorDetail;
			if( len( HTTPResults.errorDetail ) ){ 
				results.error = true; 
			}
			
			// Try to inflate JSON
			results.response = deserializeJSON( results.rawResponse, false );

			// Verify response error?
			if( structKeyExists(results.response, "error") ){
				results.error 	= true;
				results.message = results.response.messages.toString();
			}

		} catch( Any e ) {
			results.error 		= true;
			results.message 	= e.message & e.detail;
			results.stacktrace 	= e.stacktrace;
		}
		
		return results;
	}

}