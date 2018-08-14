<cfoutput>
	<title>Activation</title>
	<cfif #prc.isAuth#>
		<a href="#event.buildLink( "Activation.revokeAccess" )#">Revoke Access</a>
	<cfelse>
		<a href="#event.buildLink( "Activation.authorization" )#">Activate</a>
	</cfif>
</cfoutput>