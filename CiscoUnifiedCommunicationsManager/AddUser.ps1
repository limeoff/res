$Body = [string]@"
<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.cisco.com/AXL/API/9.0\">     
	<soapenv:Header/>     
		<soapenv:Body>         
			<ns:addUser sequence=\"?\">             
				<user>                 
					<firstName>Joffdrgteggr</firstName>                 
					<lastName>Samffdgtrgttrrle</lastName>                 
					<userid>jsatpff4gtrlgte</userid>                 
					<password>password</password>                 
					<pin>12345</pin>                 
					<mailid>jsample@company.com</mailid>                 
					<department>Marketing</department>                 
					<manager>Jane Doe</manager>                 
					<associatedDevices>                     
					<!--Zero or more repetitions:-->                     
					<device>SEP121212121220</device>                 
					</associatedDevices>                 
					<primaryExtension>                     
					<pattern>1011</pattern>                 
					</primaryExtension>             
				</user>         
			</ns:addUser>     
		</soapenv:Body> 
</soapenv:Envelope>
"@


[string]$result = curl  -k -u test:test -H 'Content-type: text/xml;' -H 'SOAPAction:CUCM:DB ver=9.0' -d $Body  https://192.168.254.22:8443/axl/ 

#in case of error
$result.Envelope.Body.Fault.faultstring

#in case of success - id of the new user
$result.Envelope.Body.addUserResponse











