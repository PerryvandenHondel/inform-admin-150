//
//	Title
//
//	Description
//
//	
//
//
//


program InformAdmin;


{$MODE OBJFPC} // Do not forget this ever
{$M+}
{$H+}


uses
	DateUtils,
	StrUtils,
	SysUtils,
	Process,
	USupportLibrary;

	

const
	PRE_ALERT_PASSWORD_ABOUT_TO_EXPIRES_SECS = 		1209600;		// 14 days * 86400 seconds per day;

var
	pathExportAccount: string;


function GetDomainMaxPasswordAge(rootDse: string): integer;
//
//	Get the maximum password age of an AD domain as defined in it's Domain Policy
//
//		rootDse:	Format: DC=domain,DC=ext
//
var
	path: string;
	p: TProcess;
	f: TextFile;
	line: string;	// Read a line from the nslookup.tmp file.
	r: longint;
	rs: string;
begin
	r := 0;

	// Get a temp file to store the output of the adfind.exe command.
	path := SysUtils.GetTempFileName(); // Path is C:\Users\<username>\AppData\Local\Temp\TMP00000.tmp
	
	p := TProcess.Create(nil);
	p.Executable := 'cmd.exe'; 
    p.Parameters.Add('/c adfind.exe -b ' + EncloseDoubleQuote(rootDse) + ' -s base maxPwdAge >' + path);
	p.Options := [poWaitOnExit, poUsePipes, poStderrToOutPut];
	p.Execute;
	
	// Open the text file and read the lines from it.
	Assign(f, path);
	
	{I+}
	Reset(f);
	repeat
		ReadLn(f, line);
		if Pos('>maxPwdAge: ', line) > 0 then
			rs := Trim(StringReplace(line, '>maxPwdAge: ', '', [rfIgnoreCase])); 
	until Eof(f);
	Close(f);
	
	// Delete the temp file
	SysUtils.DeleteFile(path);
	rs := ReplaceText(rs, '0000000', ''); 
	rs := ReplaceText(rs, '-', '');
	
	GetDomainMaxPasswordAge := StrToInt(rs);
end; // of GetDomainMaxPasswordAge
	
function GetDomainMaxPasswordAge(): integer;
//
//
//
//
var
	s: string;
	rnum: string;
	num: Extended;
	days: integer;
	secs: integer;
begin

	s := '51840000000000';
	WriteLn(s);
	
	s := ReplaceText(s, '0000000', '');
	
	secs := StrToInt(s);
	
	
	WriteLn(' Seconds: ', secs);
end;	
	

procedure CreateExportAccount(pathExport: string; baseOu: string);
var
	c: Ansistring;
begin

	// userAccountControl userPrincipalName lastLogontimeStamp whenCreated mail 
	c := 'adfind.exe -b ' + EncloseDoubleQuote(baseOu) + ' ';
	c := c + '-f ' + EncloseDoubleQuote('(&(objectClass=user)(objectCategory=person))') + ' ';
	c := c + 'sAMAccountName userAccountControl userPrincipalName mail lastLogontimeStamp whenCreated pwdlastset ';
	c := c + '-jtsv -csvnoq ';
	c := c + '-tdcgt -tdcfmt "%YYYY%-%MM%-%DD% %HH%:%mm%:%ss%" ';
	c := c + '-tdcs -tdcsfmt "%YYYY%-%MM%-%DD% %HH%:%mm%:%ss%" ';
	c := c + '>' + pathExport;
	
	WriteLn(c);
	WriteLn('Accounts exported in: ', pathExport);
	RunCommand(c);
end; // of procedure CreateExportAccount


procedure CheckPasswordLastSet(dn: string; pwdLastset: TDateTime; maxAgeSecs: integer);
var
	passwordAgeSecs: integer;
	passwordExpireDateTime: TDateTime;
begin
	WriteLn('Checking the password age of: ', dn);
	WriteLn('  Password is last changed on: ', DateTimeToStr(pwdLastset));
	// , 'yyyy-mm-dd hh:nn:ss'));
	
	passwordAgeSecs := SecondsBetween(Now(), pwdLastset);
	WriteLn('  Thats ', passwordAgeSecs, ' seconds ago');
	
	passwordExpireDateTime := IncSecond(pwdLastset, maxAgeSecs);
	
	WriteLn('  Password will be expired after: ', DateTimeToStr(passwordExpireDateTime));
	
	
	if passwordAgeSecs > (maxAgeSecs - PRE_ALERT_PASSWORD_ABOUT_TO_EXPIRES_SECS) then
		WriteLn('WARNING password is about to expire within 2 weeks' );
	
end; // of procedure CheckPasswordLastSet


procedure ProcessAdDomain(rootDse: string; OuAccount: string);
var
	maxPasswordAgeSec: longint;
begin
	WriteLn('Processing domain: ', rootDse);
	pathExportAccount := GetTempFileName();
	CreateExportAccount(pathExportAccount, ouAccount + ',' + rootDse);
	
	maxPasswordAgeSec := GetDomainMaxPasswordAge(rootDse);
	WriteLn('Max password age in seconds: ', maxPasswordAgeSec);
	
	CheckPasswordLastSet('CN=GTN_Adri.Kusters,OU=GTN,OU=Beheer,DC=ontwikkel,DC=ns,DC=nl', StrToDateTime('2015-09-11 09:51:24'), maxPasswordAgeSec);
end; // of procedure ProcessAdDomain





procedure ProgramInit();
begin
end; // of procedure ProgramInit


procedure ProgramRun();
var
	secs: integer;
begin

	ProcessAdDomain('DC=ontwikkel,DC=ns,DC=nl', 'OU=Beheer');
	
	//WriteLn(secs);
	
	
	
	//WriteLn(SecondsBetween(Now, StrToDateTime('2015-09-15 12:50:20')));
	
	
	
	
	//WriteLn(SecondsBetween(Now, StrToDateTime('2015-05-25 11:12:31')));
	WriteLn();
end; // of procedure ProgramRun


procedure ProgramDone();
begin
end; // of procedure ProgramDone


begin
	ProgramInit();
	ProgramRun();
	ProgramDone();
end. // of program InformAdmin