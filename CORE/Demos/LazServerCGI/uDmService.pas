unit uDmService;

interface

uses
  SysUtils, Classes, IBConnection, sqldb, mysql55conn, mysql50conn,
  uDWDatamodule, uDWJSONObject, Dialogs, uDWConstsData, uRESTDWPoolerDB,
  uRESTDWServerEvents, uRESTDWServerContext, uRestDWLazDriver, uConsts,
  uDWConsts, uSystemEvents;

type

  { TServerMethodDM }

  TServerMethodDM = class(TServerMethodDataModule)
    DWServerContext1: TDWServerContext;
    DWServerEvents1: TDWServerEvents;
    FDQuery1: TSQLQuery;
    RESTDWLazDriver1: TRESTDWLazDriver;
    RESTDWPoolerDB1: TRESTDWPoolerDB;
    Server_FDConnection: TIBConnection;
    SQLTransaction1: TSQLTransaction;
    procedure DWServerContext1ContextListangularReplyRequest(
      const Params: TDWParams; Var ContentType, Result: String);
    procedure DWServerContext1ContextListindexReplyRequest(
      const Params: TDWParams; Var ContentType, Result: String);
    procedure DWServerContext1ContextListinitReplyRequest(
      const Params: TDWParams; Var ContentType, Result: String);
    procedure DWServerContext1ContextListopenfileReplyRequestStream(
      const Params: TDWParams; Var ContentType: String;
      Var Result: TMemoryStream);
    procedure DWServerEvents1EventsgetemployeeReplyEvent(Var Params: TDWParams;
      Var Result: String);
    procedure DWServerEvents1EventsservertimeReplyEvent(Var Params: TDWParams;
      Var Result: String);
    procedure DWServerEvents1EventstesteReplyEvent(Var Params: TDWParams;
      Var Result: String);
    procedure ServerMethodDataModuleReplyEvent(SendType: TSendEvent;
      Context: string; var Params: TDWParams; var Result: string);
    procedure ServerMethodDataModuleCreate(Sender: TObject);
    procedure Server_FDConnectionBeforeConnect(Sender: TObject);
  private
    { Private declarations }
   Function ConsultaBanco(Var Params : TDWParams) : String;Overload;
  public
    { Public declarations }
  end;

var
  ServerMethodDM: TServerMethodDM;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses uDWJSONTools;

{$R *.lfm}

Function TServerMethodDM.ConsultaBanco(Var Params : TDWParams) : String;
Var
 vSQL      : String;
 JSONValue : TJSONValue;
 fdQuery   : TSQLQuery;
Begin
 If Params.ItemsString['SQL'] <> Nil Then
  Begin
   JSONValue          := TJSONValue.Create;
   If Params.ItemsString['SQL'].value <> '' Then
    Begin
     If Params.ItemsString['TESTPARAM'] <> Nil Then
      Params.ItemsString['TESTPARAM'].SetValue('OK, OK');
     vSQL      := Params.ItemsString['SQL'].value;
     fdQuery   := TSQLQuery.Create(Nil);
     Try
      fdQuery.DataBase := Server_FDConnection;
      fdQuery.SQL.Add(vSQL);
      JSONValue.LoadFromDataset('sql', fdQuery, EncodedData);
      Result             := JSONValue.ToJSON;
     Finally
      JSONValue.Free;
      fdQuery.Free;
     End;
    End;
  End;
End;

procedure TServerMethodDM.ServerMethodDataModuleCreate(Sender: TObject);
begin
 RESTDWPoolerDB1.Active := ActivePooler;
end;

procedure TServerMethodDM.ServerMethodDataModuleReplyEvent(SendType: TSendEvent;
  Context: string; var Params: TDWParams; var Result: string);
Begin
 Case SendType Of
  sePOST   :
   Begin
    If UpperCase(Context) = Uppercase('ConsultaBanco') Then
     Result := ConsultaBanco(Params)
    Else
     Result := '{(''STATUS'',   ''NOK''), (''MENSAGEM'', ''Método não encontrado'')}';
   End;
 End;
End;

procedure TServerMethodDM.DWServerEvents1EventsservertimeReplyEvent(
  Var Params: TDWParams; Var Result: String);
begin
 If Params.ItemsString['inputdata'].AsString <> '' Then //servertime
  Params.ItemsString['result'].AsDateTime := Now
 Else
  Params.ItemsString['result'].AsDateTime := Now - 1;
 Params.ItemsString['resultstring'].AsString := 'testservice';
end;

procedure TServerMethodDM.DWServerEvents1EventsgetemployeeReplyEvent(
  Var Params: TDWParams; Var Result: String);
Var
 JSONValue: TJSONValue;
begin
 JSONValue          := TJSONValue.Create;
 Try
  FDQuery1.Close;
  FDQuery1.SQL.Clear;
  FDQuery1.SQL.Add('select * from employee');
  Try
   FDQuery1.Open;
   JSONValue.Encoding        := Encoding;
   JSONValue.DatabaseCharSet := RESTDWLazDriver1.DatabaseCharSet;
   JSONValue.LoadFromDataset('employee', FDQuery1, False,  Params.JsonMode, '');
   Result := JSONValue.ToJSON;
  Except
   On E : Exception Do
    Begin
     Result := Format('{"Error":"%s"}', [E.Message]);
    End;
  End;
 Finally
  JSONValue.Free;
 End;
end;

procedure TServerMethodDM.DWServerContext1ContextListindexReplyRequest(
  const Params: TDWParams; Var ContentType, Result: String);
var
 s : TStringlist;
begin
 s := TStringlist.Create;
 Try
  s.LoadFromFile('.\www\index.html');
  Result := s.Text;
 Finally
  s.Free;
 End;
end;

procedure TServerMethodDM.DWServerContext1ContextListangularReplyRequest(
  const Params: TDWParams; Var ContentType, Result: String);
var
 s : TStringlist;
begin
 s := TStringlist.Create;
 Try
  s.LoadFromFile('.\www\dw_angular.html');
  Result := s.Text;
 Finally
  s.Free;
 End;
end;

procedure TServerMethodDM.DWServerContext1ContextListinitReplyRequest(
  const Params: TDWParams; Var ContentType, Result: String);
begin
 Result := '<!DOCTYPE html> ' +
           '<html>' +
           '  <head>' +
           '    <meta charset="utf-8">' +
           '    <title>My test page</title>' +
           '    <link href=''http://fonts.googleapis.com/css?family=Open+Sans'' rel=''stylesheet'' type=''text/css''>' +
           '  </head>' +
           '  <body>' +
           '    <h1>REST Dataware is cool - Lazarus CGI</h1>' +
           '    <img src="http://www.resteasyobjects.com.br/myimages/LogoDW.png" alt="The REST Dataware logo: Powerfull Web Service.">' +
           '  ' +
           '  ' +
           '    <p>working together to keep the Internet alive and accessible, help us to help you. Be free.</p>' +
           ' ' +
           '    <p><a href="http://www.restdw.com.br/">REST Dataware site</a> to learn and help us.</p>' +
           '  </body>' +
           '</html>';
end;

procedure TServerMethodDM.DWServerContext1ContextListopenfileReplyRequestStream(
  const Params: TDWParams; Var ContentType: String; Var Result: TMemoryStream);
Var
 vNotFound   : Boolean;
 vFileName   : String;
 vStringStream : TStringStream;
begin
 vNotFound := True;
 Result    := TMemoryStream.Create;
 If Params.ItemsString['filename'] <> Nil Then
  Begin
   vFileName := '.\www\' + DecodeStrings(Params.ItemsString['filename'].AsString, csUndefined);
   vNotFound := Not FileExists(vFileName);
   If Not vNotFound Then
    Begin
     Try
      Result.LoadFromFile(vFileName);
      ContentType := GetMIMEType(vFileName);
     Finally
     End;
    End;
  End;
 If vNotFound Then
  Begin
   vStringStream := TStringStream.Create('<!DOCTYPE html> ' +
                                         '<html>' +
                                         '  <head>' +
                                         '    <meta charset="utf-8">' +
                                         '    <title>My test page</title>' +
                                         '    <link href=''http://fonts.googleapis.com/css?family=Open+Sans'' rel=''stylesheet'' type=''text/css''>' +
                                         '  </head>' +
                                         '  <body>' +
                                         '    <h1>REST Dataware</h1>' +
                                         '    <img src="http://www.resteasyobjects.com.br/myimages/LogoDW.png" alt="The REST Dataware logo: Powerfull Web Service.">' +
                                         '  ' +
                                         '  ' +
                                         Format('    <p>File "%s" not Found.</p>', [vFileName]) +
                                         '  </body>' +
                                         '</html>');
   Try
    vStringStream.Position := 0;
    Result.CopyFrom(vStringStream, vStringStream.Size);
   Finally
    vStringStream.Free;
   End;
  End;
end;

procedure TServerMethodDM.DWServerEvents1EventstesteReplyEvent(
  Var Params: TDWParams; Var Result: String);
begin
 Result := Format('{"Message":"%s"}', ['Sou eu ServerEvents 1']);
end;

procedure TServerMethodDM.Server_FDConnectionBeforeConnect(Sender: TObject);
Begin
 TIBConnection(Sender).HostName     := Servidor;
 TIBConnection(Sender).DatabaseName := pasta + database;
 TIBConnection(Sender).UserName     := usuario_BD;
 TIBConnection(Sender).Password     := senha_BD;
end;

end.
