/**
* This is the Freshbooks SDK class
*/
component accessors=true singleton threadsafe{
	
	/**
	 * The module settings
	 */
	property name="settings";


	/**
	 * The client ID
	 */
	property name="clientID";
	property name="clientSecret";

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
	 * APIURL, Authorization link, and the redirect URI
	 */
	property name="APIURL";
	property name="authLink";
	property name="redirectURI";

	/**
	 * 
	 */
	property name="identityInformation";

	// DI
	property name="log" inject="logbox:logger:{this}";

	/**
	* Constructor
	* @settings The module settings
	* @settings.inject coldbox:modulesettings:cbfreshbooks
	*/
	function init( settings ){
		variables.settings = arguments.settings;
		variables.APIURL = arguments.settings.APIURL;
		variables.authLink = arguments.settings.authLink;
		variables.redirectURI = arguments.settings.redirectURI;
		variables.clientID = arguments.settings.APIToken.clientID;
		variables.clientSecret = arguments.settings.APIToken.clientSecret;
		variables.authorizationCode = arguments.settings.APIToken.authorizationCode;

		return this;
	}

	/**
	 * Retrieve the application token for this module
	 */
	function getAPITokenStruct(){
		return settings.APIToken;
	}

	/**
	* Generate the authorization link to retrieve the authorization code
	* The user has to allow manually the access to the FreshBooks account and paste the authorization code into the module settings
	* @results String -> Authorization URL
	*/
	function getLoginURL(){
		var strLoginURL = getAuthLink()
 		 & "authorize?client_id=" & getClientID()
 		 & "&response_type=code"
         & "&redirect_uri=" & getRedirectURI();
		
		return strLoginURL;
	}


	/**
	* Do the authentication process and retrieve the token access from a given authorization code
	* @results struct = { access_token:string, expires_in:date, expires_in_raw:number, refresh_token:string, success:boolean, token_type:string } 
	*/
	function authenticate(){
		//check if the token struct exists in the session and returns it if it has not expired
		if ( isDefined( "session.tokenStruct" ) AND session.tokenStruct.success 
												AND dateCompare(now(), parseDateTime(session.tokenStruct.expires_in), "n") <= 0 ){
			return session.tokenStruct;
		}
		else if( len(getTokenAccess() ) AND len( getRefreshToken() ) ){
			return this.refreshToken( getRefreshToken() );
		}
		var body = {};
		var headers = {};
		var APIURL = getAPIURL();
		response = {};
		headers [ "Content-Type" ] = "application/json" ;
		headers [ "Api-Version" ] = "alpha" ;
		
		body['grant_type'] = "authorization_code";
		body['client_secret'] = "#getClientSecret()#";
		body['code'] = "#getAuthorizationCode()#";
		body['client_id'] = "#getClientID()#";
		body['redirect_uri'] = "#getRedirectURI()#";

		response = makeRequest( method="POST", url=APIURL, body=body, headers=headers );
		return authResponse( response );
	}

	/**
	 * I take the refresh token from the authorization procedure and get you a new access token.
	 * @refreshToken the most recent refresh token that has been provided
	 * @results struct = { access_token:string, expires_in:date, expires_in_raw:number, refresh_token:string, success:boolean, token_type:string } 
	 */
	 function refreshToken( required String refreshToken ){
	 	var headers = {};
	 	var body = {};
	 	var APIURL = getAPIURL();
		var response = {};
		headers [ "Content-Type" ] = "application/json" ;
		headers [ "Api-Version" ] = "alpha" ;
		
		body['grant_type'] = "refresh_token";
		body['client_secret'] = "#getClientSecret()#";
		body['refresh_token'] = arguments.refreshToken;
		body['client_id'] = "#getClientID()#";
		body['redirect_uri'] = "#getRedirectURI()#";

		var response = makeRequest( method="post", url=APIURL, body=body, headers=headers );
		return authResponse( response );
	 }

	
	/**
	 * Manage response and build an struct with the token information and store it in the session
	 * @response HTTP Response
	 * @results struct { success:boolean,  access_token, token_type, expires_in_raw, expires_in, refresh_token}
	 */
	 function authResponse( required response ){
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
		session.tokenStruct = stuResponse;

		return stuResponse;
	 }


	/**
	* Make a test call
	* It will be deleted later
	*/
	function testCall(){
		var headers = {};
		headers [ "Api-Version" ] = "alpha" ;
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/test";

		var result =  makeRequest( headers=headers, url=endpoint );

		if ( result.error ){
			throw result.message;
		}
		return result.response;

	}

	/**
	* Returns the list of clients
	* @accountID The account ID that the client belongs to
	* @results an array of structs with the list of clients -> clients [ {client1},{client2},{client3},... ]
	*/
	function getClients( required String accountID ){
		var headers = {};
		var clients = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &"/users/clients";

		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return clients;
			}
			throw result.message;
		}
		for(cl in result.response.response.result.clients) {
			clients.append( cl );
		}
		return clients;
	}

	/**
	* Retrieve a single client
	* @accountID The account ID that the client belongs to
	* @clientID ID of the client to retrieve
	* @results struct -> { allow_late_notifications, updated, last_activity, s_code, vat_number, pref_email, id, direct_link_token, s_province, lname, s_country, s_street2, statement_token, note, mob_phone, role, home_phone, last_login, company_industry, subdomain, email, username, fax, fname, vat_name, p_city, p_code, allow_late_fees, s_street, p_country, company_size, accounting_systemid, bus_phone, p_province, signup_date, language, level, notified, userid, p_street2, pref_gmail, vis_state, s_city, num_logins, organization, p_street, currency_code }
	*/
	function getSingleClient( required String accountID, required String clientID ){
		if( !len( arguments.accountID ) ){
			throw( "Account id cannot be null or empty");
		}
		if( !len( arguments.clientID ) ){
			throw( "Client id cannot be null or empty");
		}
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/users/clients/" & arguments.clientID;
		
		var result =  makeRequest( headers=headers, url=endpoint );

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
	* @userInfo The struct with the client's info to create a new entry
	* @accountID The account ID where the client will be created in
	* @results struct -> { allow_late_notifications, updated, last_activity, s_code, vat_number, pref_email, id, direct_link_token, s_province, lname, s_country, s_street2, statement_token, note, mob_phone, role, home_phone, last_login, company_industry, subdomain, email, username, fax, fname, vat_name, p_city, p_code, allow_late_fees, s_street, p_country, company_size, accounting_systemid, bus_phone, p_province, signup_date, language, level, notified, userid, p_street2, pref_gmail, vis_state, s_city, num_logins, organization, p_street, currency_code }
	*/
	function createSingleClient( required struct userInfo, required String accountID ){
		if( !len( userInfo )){
			throw( "UserInfo Struct cannot be null or empty");
		}
		if( !len( accountID ) ){
			throw( "Client id cannot be null or empty");
		}

		var headers = {};
		var newClient = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/users/clients";

		newClient[ "client"] = arguments.userInfo;

		var result =  makeRequest( method="POST", url=endpoint, headers=headers, body=newClient );

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
	function UpdateSingleClient( required String accountID, required String clientID, required struct userInfo ){
		var headers = {};
		var userDataToUpdate = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/users/clients/"& arguments.clientID;

		userDataToUpdate[ "client"] = arguments.userInfo;

		var result =  makeRequest( method="PUT", url=endpoint, headers=headers, body=userDataToUpdate );

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
		var headers = {};
		var userInfo = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/users/clients/"& arguments.clientID;

		userInfo[ "client"] = arguments.userFlag;

		var result =  makeRequest( method="PUT", url=endpoint, headers=headers, body=userInfo );

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
	function getExpensesList( required String accountID ){
		var headers = {};
		var expenses = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/expenses/expenses";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return expenses;
			}
			throw result.message;
		}
		for( var exp in result.response.response.result.expenses ) {
			expenses.append( exp );
		}
		return expenses;

	}

	/**
	* Returns a single expense if it exists
	* @accountID Account Id where the expense belong to
	* @expenseID Id of the expense to return
	* @results expense -> { categoryid, markup_percent, projectid, clientid, isduplicate, taxName2, taxName1, taxPercent1, profileid, taxPercent2, id, invoiceid, account_name, taxAmount2, taxAmount1, vis_state, status, bank_name, updated, vendor, has_receipt, ext_systemid, staffid, date, transactionid, include_receipt, accounting_systemid, background_jobid, notes, ext_invoiceid, amount, expenseid, compounded_tax, accountid }
	*/
	function getExpenseById( required String accountID, required String expenseID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/expenses/expenses/"& arguments.expenseID;

		var result =  makeRequest( headers=headers, url=endpoint );

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
	function createExpense( required String accountID, required struct expenseInfo ){
		var headers = {};
		var newExpense = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/expenses/expenses";

		newExpense[ "expense"] = arguments.expenseInfo;

		var result =  makeRequest( method="POST", url=endpoint, headers=headers, body=newExpense );

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
	function updateExpense( required String accountID, required String expenseID ,required struct expenseInfo ){
		var headers = {};
		var expense = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/expenses/expenses/" & arguments.expenseID;

		expense[ "expense"] = arguments.expenseInfo;

		var result =  makeRequest( method="POST", url=endpoint, headers=headers, body=expense );

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
		var headers = {};
		var expense = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/expenses/expenses/" & arguments.expenseID;

		expense[ "expense"] = arguments.expenseFlag;

		var result =  makeRequest( method="POST", url=endpoint, headers=headers, body=expense );

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
	function getExpensesList( required String accountID ){
		var headers = {};
		var expenses = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/expenses/expenses";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return expenses;
			}
			throw result.message;
		}
		for( var exp in result.response.response.result.expenses ) {
			expenses.append( exp );
		}
		return expenses;

	}

	/**
	* Returns a single expense if it exists
	* @accountID Account Id where the expense belong to
	* @expenseID Id of the expense to return
	* @results expense -> { categoryid, markup_percent, projectid, clientid, isduplicate, taxName2, taxName1, taxPercent1, profileid, taxPercent2, id, invoiceid, account_name, taxAmount2, taxAmount1, vis_state, status, bank_name, updated, vendor, has_receipt, ext_systemid, staffid, date, transactionid, include_receipt, accounting_systemid, background_jobid, notes, ext_invoiceid, amount, expenseid, compounded_tax, accountid }
	*/
	function getExpenseById( required String accountID, required String expenseID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/expenses/expenses/"& arguments.expenseID;

		var result =  makeRequest( headers=headers, url=endpoint );

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
	function createExpense( required String accountID, required struct expenseInfo ){
		var headers = {};
		var newExpense = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/expenses/expenses";

		newExpense[ "expense"] = arguments.expenseInfo;

		var result =  makeRequest( method="POST", url=endpoint, headers=headers, body=newExpense );

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
	function updateExpense( required String accountID, required String expenseID ,required struct expenseInfo ){
		var headers = {};
		var expense = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/expenses/expenses/" & arguments.expenseID;

		expense[ "expense"] = arguments.expenseInfo;

		var result =  makeRequest( method="PUT", url=endpoint, headers=headers, body=expense );

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
		var headers = {};
		var expense = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/expenses/expenses/" & arguments.expenseID;

		expense[ "expense"] = arguments.expenseFlag;

		var result =  makeRequest( method="PUT", url=endpoint, headers=headers, body=expense );

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
	function getInvoicesList( required String accountID ){
		var headers = {};
		var invoices = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/invoices/invoices";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return invoices;
			}
			throw result.message;
		}
		for( var invoice in result.response.response.result.invoices ) {
			invoices.append( invoice );
		}
		return invoices;
	}

	/**
	* Returns a single invoice if it exists
	* @accountID Account Id where the invoice belong to
	* @invoiceID Id of the invoice to return
	* @results invoice -> { status, deposit_percentage, create_date, outstanding, payment_status, street, code, ownerid, vat_number, id, gmail, vat_name, v3_status, discount_description, dispute_status, lname, deposit_status, ext_archive, template, basecampid, sentid, show_attachments, vis_state, current_organization, province, due_date, updated, terms, description, parent, last_order_status, street2, deposit_amount, paid, invoiceid, discount_total, address, invoice_number, customerid, discount_value, accounting_systemid, organization, due_offset_days, language, po_number, display_status, created_at, auto_bill, date_paid, amount, estimateid, city, currency_code, country, autobill_status, generation_date, return_uri, fname, notes, payment_details, accountid }
	*/
	function getInvoiceById( required String accountID, required String invoiceID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/invoices/invoices/"& arguments.invoiceID;

		var result =  makeRequest( headers=headers, url=endpoint );

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
	function createInvoice( required String accountID, required struct invoiceInfo ){
		var headers = {};
		var newInvoice = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/invoices/invoices";

		newInvoice[ "invoice"] = arguments.invoiceInfo;

		var result =  makeRequest( method="POST", url=endpoint, headers=headers, body=newInvoice );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.invoice;
	}

	/**
	* Update an invoice
	* @accountID The account ID associated with the invoice that will be updated
	* @invoiceInfo The struct with the invoice's info to create a new entry
	* @results invoice -> { status, deposit_percentage, create_date, outstanding, payment_status, street, code, ownerid, vat_number, id, gmail, vat_name, v3_status, discount_description, dispute_status, lname, deposit_status, ext_archive, template, basecampid, sentid, show_attachments, vis_state, current_organization, province, due_date, updated, terms, description, parent, last_order_status, street2, deposit_amount, paid, invoiceid, discount_total, address, invoice_number, customerid, discount_value, accounting_systemid, organization, due_offset_days, language, po_number, display_status, created_at, auto_bill, date_paid, amount, estimateid, city, currency_code, country, autobill_status, generation_date, return_uri, fname, notes, payment_details, accountid }
	*/
	function updateInvoice( required String accountID, required String invoiceID, required struct invoiceInfo ){
		var headers = {};
		var invoice = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/invoices/invoices/" & arguments.invoiceID;

		invoice[ "invoice"] = arguments.invoiceInfo;

		var result =  makeRequest( method="PUT", url=endpoint, headers=headers, body=invoice );

		if( result.error ){
			throw result.message;
		}
		return result.response.response.result.invoice;
	}

	/**
	* Delete an invoice
	* @accountID The account ID associated with the invoice that will be deleted
	* @invoiceInfo The struct with the invoice's info to update an existing entry
	*/
	function deleteInvoice( required String accountID, required String invoiceID, required struct invoiceFlag ){
		var headers = {};
		var invoice = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/invoices/invoices/" & arguments.invoiceID;

		invoice[ "invoice"] = arguments.invoiceFlag;

		var result =  makeRequest( method="PUT", url=endpoint, headers=headers, body=invoice );

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
	function getExpenseCategoriesList( required String accountID ){
		var headers = {};
		var expenseCategoriesList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/expenses/categories";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return expenseCategoriesList;
			}
			throw result.message;
		}
		
		for( var expCategory in result.response.response.result.categories ) {
			expenseCategoriesList.append( expCategory );
		}
		return expenseCategoriesList;
	}

	/**
	* Returns a single expense category if it exists
	* @accountID Account Id where the expense category belongs to
	* @expenseCategoryID Id of the expense category to return
	* @results struct {category:string, created_at:string, updated_at:string, categoryid:number, is_editable:boolean,
	* 									is_cogs:boolean, parentid, vis_state:number, id:number }
	*/
	function getExpenseCategoryById( required String accountID, required String expenseCategoryID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/expenses/categories/"& arguments.expenseCategoryID;

		var result =  makeRequest( headers=headers, url=endpoint );

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
	function getGatewaysList( required String accountID ){
		var headers = {};
		var gatewaysList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/system/gateways";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return gatewaysList;
			}
			throw result.message;
		}
		for( var gateway in result.response.response.result.gateways ) {
			gatewaysList.append( gateway );
		}
		return gatewaysList;
	}

	/**
	* Get the list of estimates
	* @accountID The account ID of the estimates to list
	* @results an array of structs -> estimates: [ estimate:{ province, code, create_date, street, ownerid, vat_number, id, invoiced, city, lname, ext_archive, template, created_at, vis_state, current_organization, status, estimate_number, updated, terms, description, vat_name, street2, sentid, ui_status, discount_total, address, accepted, customerid, discount_value, accounting_systemid, language, po_number, country, notes, amount, estimateid, display_status, organization, rich_proposal, fname, reply_status, currency_code }, ... ]
	*/
	function getEstimatesList( required String accountID ){
		var headers = {};
		var estimatesList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/estimates/estimates";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return estimatesList;
			}
			throw result.message;
		}
		for( var estimate in result.response.response.result.estimates ) {
			estimatesList.append( estimate );
		}
		return estimatesList;
	}

	/**
	* Returns a single estimate if it exists
	* @accountID Account Id where the estimate belongs to
	* @estimateID Id of the estimate to return
	* @results estimate:{ province, code, create_date, street, ownerid, vat_number, id, invoiced, city, lname, ext_archive, template, created_at, vis_state, current_organization, status, estimate_number, updated, terms, description, vat_name, street2, sentid, ui_status, discount_total, address, accepted, customerid, discount_value, accounting_systemid, language, po_number, country, notes, amount, estimateid, display_status, organization, rich_proposal, fname, reply_status, currency_code }
	*/
	function getEstimateById( required String accountID, required String estimateID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/estimates/estimates/"& arguments.estimateID;

		var result =  makeRequest( headers=headers, url=endpoint );

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
	function createEstimate( required String accountID, required struct estimateInfo ){
		var headers = {};
		var newEstimate = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/estimates/estimates";

		newEstimate[ "estimate"] = arguments.estimateInfo;

		var result =  makeRequest( method="POST", url=endpoint, headers=headers, body=newEstimate );

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
	function updateEstimate( required String accountID, required String estimateID, required struct estimateInfo ){
		var headers = {};
		var estimate = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/estimates/estimates/" & arguments.estimateID;

		estimate[ "estimate"] = arguments.estimateInfo;

		var result =  makeRequest( method="PUT", url=endpoint, headers=headers, body=estimate );

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
		var headers = {};
		var estimate = {};
		headers [ "Api-Version" ] = "alpha";
		headers [ "Authorization" ] = "Bearer " & getTokenAccess();
		headers [ "Content-Type" ] = "application/json" ;

		var endpoint = "https://api.freshbooks.com/accounting/account/"& arguments.accountID &
		 				   "/estimates/estimates/" & arguments.estimateID;

		estimate[ "estimate"] = arguments.estimateFlag;

		var result =  makeRequest( method="PUT", url=endpoint, headers=headers, body=estimate );

		if( result.error ){
			throw result.message;
		}
	}

	/**
	* Get the list of items
	* @accountID The account ID of the items to list
	* @results array of structs -> items: [ item: { itemid, accounting_systemid, updated, name, qty, inventory,unit_cost: { amount, code" }, tax1, vis_state, tax2, id, description }, ... ]
	*/
	function getItemsList( required String accountID ){
		var headers = {};
		var itemsList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/items/items";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return itemsList;
			}
			throw result.message;
		}
		for( var item in result.response.response.result.items ) {
			itemsList.append( item );
		}
		return itemsList;
	}

	/**
	* Returns a single item if it exists
	* @accountID Account Id where the item belongs to
	* @itemID Id of the item to return
	* @results item: { itemid, accounting_systemid, updated, name, qty, inventory,unit_cost: { amount, code" }, tax1, vis_state, tax2, id, description }
	*/
	function getItemById( required String accountID, required String itemID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/items/items/"& arguments.itemID;

		var result =  makeRequest( headers=headers, url=endpoint );

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
	function createItem( required String accountID, required struct itemInfo ){
		var headers = {};
		var newItem = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/items/items";

		newItem[ "item" ] = arguments.itemInfo;
		var result =  makeRequest( method="POST", headers=headers, url=endpoint, body=newItem );
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
	function updateItem( required String accountID, required String itemID, required struct itemInfo ){
		var headers = {};
		var newItem = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						 "/items/items/" & arguments.itemID;

		var result =  makeRequest( method="PUT", headers=headers, url=endpoint, body=arguments.itemInfo );
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
		var headers = {};
		var newItem = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & 
						"/items/items/" & arguments.itemID;

		var result =  makeRequest( method="PUT", headers=headers, url=endpoint, body=arguments.itemInfo );
		if( result.error ){
			throw result.message;
		}
	}

	/**
	* Get the list of payments
	* @accountID The account ID of the payments to list
	* @results array of structs -> payments: [ { payment: { orderid, accounting_systemid, updated, invoiceid, creditid, amount { amount, code }, clientid, vis_state, logid, note, overpaymentid, gateway, date, transactionid, from_credit, type, id } , ... ]
	*/
	function getPaymentsList( required String accountID ){
		var headers = {};
		var paymentsList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/payments/payments";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return paymentsList;
			}
			throw result.message;
		}
		for( var item in result.response.response.result.payments ) {
			paymentsList.append( item );
		}
		return paymentsList;
	}

	/**
	* Returns a single payment if it exists
	* @accountID Account Id where the payment belongs to
	* @itemID Id of the payment to return
	* @results payment: { orderid, accounting_systemid, updated, invoiceid, creditid, amount { amount, code }, clientid, vis_state, logid, note, overpaymentid, gateway, date, transactionid, from_credit, type, id }
	*/
	function getPaymentById( required String accountID, required String paymentID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/estimates/estimates/"& arguments.paymentID;

		var result =  makeRequest( headers=headers, url=endpoint );

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
	function createPayment( required String accountID, required struct paymentInfo ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/payments/payments";

		var result =  makeRequest( method="POST", headers=headers, url=endpoint, body=arguments.paymentInfo );
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
	function updatePayment( required String accountID, required String paymentID, required struct paymentInfo ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & 
						"/payments/payments/" & arguments.paymentID;

		var result =  makeRequest( method="PUT", headers=headers, url=endpoint, body=arguments.paymentInfo );
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
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & 
						"/payments/payments/" & arguments.paymentID;

		var result =  makeRequest( method="PUT", headers=headers, url=endpoint, body=arguments.paymentInfo );
		if( result.error ){
			throw result.message;
		}
	}

	/**
	* Get the list of taxes
	* @accountID The account ID of the taxes to list
	* @results an array of structs -> taxes: [ tax: { accounting_systemid, updated, name, number, taxid, amount, compound, id }, ... ]
	*/
	function getTaxesList( required String accountID ){
		var headers = {};
		var taxesList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/taxes/taxes";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return taxesList;
			}
			throw result.message;
		}
		for( var tax in result.response.response.result.taxes ) {
			taxesList.append( tax );
		}
		return taxesList;
	}

	/**
	* Returns a single tax if it exists
	* @accountID Account Id where the tax belongs to
	* @itemID Id of the tax to return
	* @results tax: { accounting_systemid, updated, name, number, taxid, amount, compound, id }
	*/
	function getTaxById( required String accountID, required String taxID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/taxes/taxes/"& arguments.taxID;

		var result =  makeRequest( headers=headers, url=endpoint );

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
	function createTax( required String accountID, required struct taxInfo ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/taxes/taxes";

		var result =  makeRequest( method="POST", headers=headers, url=endpoint, body=arguments.taxInfo );
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
	function updateTax( required String accountID, required String taxID, required struct taxInfo ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						 "/taxes/taxes/" & arguments.taxID;

		var result =  makeRequest( method="PUT", headers=headers, url=endpoint, body=arguments.taxInfo );
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
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						 "/taxes/taxes/" & arguments.taxID;

		var result =  makeRequest( method="DELETE", headers=headers, url=endpoint );
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
	function getStaffList( required String accountID ){
		var headers = {};
		var staffList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & "/users/staffs";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return staffList;
			}
			throw result.message;
		}
		for( var staff in result.response.response.result.staff ) {
			staffList.append( staff );
		}
		return staffList;
	}

	/**
	* Returns a single staff member if it exists
	* @accountID Account Id where the staff member belongs to
	* @staffID Id of the staff member to return
	* @results struct {fax, rate, num_logins, api_token, id, note, display_name, lname, mob_phone, last_login, home_phone, email, username,
	* 				   updated, p_province, p_city, p_code, p_country, accounting_systemid, bus_phone, signup_date, language, level, userid,
	* 				   p_street2, vis_state, fname, organization, p_street, currency_code}
	*/
	function getStaffById( required String accountID, required String staffID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						   "/users/staffs/"& arguments.staffID;

		var result =  makeRequest( headers=headers, url=endpoint );

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
	function updateStaff( required String accountID, required String staffID, required struct staffInfo ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						 "/users/staffs/" & arguments.taxID;

		var result =  makeRequest( method="PUT", headers=headers, url=endpoint, body=arguments.staffInfo );
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
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID &
						 "/users/staffs/" & arguments.taxID;

		var result =  makeRequest( method="PUT", headers=headers, url=endpoint, body=arguments.staffInfo );
		if( result.error ){
			throw result.message;
		}
	}

	/**
	* Get time entries
	* @businessID The business ID associated with the time entries
	* @results struct -> time_entries { note, duration, project_id, client_id, is_logged, started_at, active, id, timer { id, is_running},
	* 									meta { pages, total_logged, total_unbilled, per_page, total, page } }
	*/
	function getTimeEntries( required String businessID ){
		var headers = {};
		var timeEntries = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/timetracking/business/" & arguments.businessID & "/time_entries";

		var result =  makeRequest( headers=headers, url=endpoint );
		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return staffList;
			}
			throw result.message;
		}
		for( var timeEntry in result.response.time_entries ) {
			timeEntries.append( timeEntry );
		}
		return timeEntries;
	}

	/**
	* Get the list of the projects associated with a business ID
	* @businessID The business ID associated with the projects to list
	* @results an array of structs -> projects: [ project: { due_date, logged_duration, fixed_price, group, description, complete, title, project_type, budget, updated_at, sample, services, rate, internal, client_id, active, created_at, id, billing_method }  ]
	*/
	function getProjectsList( required String businessID ){
		var headers = {};
		var projectsList = [];
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/projects/business/" & arguments.businessID & 
						"/projects";

		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return projectsList;
			}
			throw result.message;
		}
		for( var project in result.response.projects ) {
			projectsList.append( project );
		}
		return projectsList;
	}

	/**
	* Create time entry
	* @accountID The account ID Associated with the time entry to create
	* @businessID The business ID associated with the time entry to create
	* @timeEntryInfo struct with the time entry's info to create a new entry
	* @results struct -> time_entry { note, duration, project_id, client_id, is_logged, started_at, active, id, timer { id, is_running},
	* 									meta { pages, total_logged, total_unbilled, per_page, total, page } }
	*/
	function createTimeEntry( required String accountID, required String businessID, required struct timeEntryInfo ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/timetracking/business/" & arguments.businessID & "/time_entries";

		var result =  makeRequest( method="POST", headers=headers, url=endpoint, body=arguments.timeEntryInfo );
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
	function UpdateTimeEntry( required String accountID, required String businessID, required String timeEntryID, required struct timeEntryInfo ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/timetracking/business/" & arguments.businessID &
						 "/time_entries/" & arguments.timeEntryID;

		var result =  makeRequest( method="PUT", headers=headers, url=endpoint, body=arguments.timeEntryInfo );
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
	function DeleteTimeEntry( required String accountID, required String businessID, required String timeEntryID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/timetracking/business/" & arguments.businessID &
						 "/time_entries/" & arguments.timeEntryID;

		var result =  makeRequest( method="DELETE", headers=headers, url=endpoint, body=arguments.timeEntryInfo );
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
	function getProjectById( required String businessID, required String projectID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/projects/business/" & arguments.businessID & 
						"/projects/" & arguments.projectID;

		var result =  makeRequest( headers=headers, url=endpoint );

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
	function getTaskById( required String accountID, required String taskID ){
		var headers = {};
		headers [ "Api-Version" ] = "alpha";
		headers[ "Authorization" ] = "Bearer " & getTokenAccess();
		var endpoint = "https://api.freshbooks.com/accounting/account/" & arguments.accountID & 
						"/projects/tasks/" & arguments.taskID;

		var result =  makeRequest( headers=headers, url=endpoint );

		if( result.error ){
			if ( result.message == "404 NOT FOUND" ){
				return StructNew();
			}
			throw result.message;
		}
		return result.response.response.result.task;
	}


	/**
	* Make a request to FreshBooks
	* @method The HTTP method call
	* @url The url to make the request
	* @body The body contents of the request
	* @headers Request headers
	* @parameters Request parameters
	* @timeout Request Timeout
	* @results struct = { error:boolean, response:struct, message, reponseHeader:struct, rawResponse, stacktrace }
	*/
	private struct function makeRequest(
		string method = "GET",
		required string url,
		body = {},
		struct headers = structNew(),
		struct parameters = structNew(),
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


		// Default Content Type
		if( NOT structKeyExists( arguments.headers, "content-type" ) ){
			arguments.headers[ "content-type" ] = "";
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