{******************************************************************************}
{                                                                              }
{       WiRL: RESTful Library for Delphi                                       }
{                                                                              }
{       Copyright (c) 2015-2019 WiRL Team                                      }
{                                                                              }
{       https://github.com/delphi-blocks/WiRL                                  }
{                                                                              }
{******************************************************************************}
unit WiRL.http.Client.Indy;

{$I ..\Core\WiRL.inc}

interface

uses
  System.SysUtils, System.Classes,

  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  IdHTTPHeaderInfo, IdStack, IdResourceStringsProtocols,

  WiRL.http.Client.Interfaces,
  WiRL.http.Accept.MediaType,

  WiRL.http.Headers,
  WiRL.http.Core,
  WiRL.http.Cookie;

type
  TWiRLClientResponseIndy = class(TInterfacedObject, IWiRLResponse)
  private
    FIdHTTPResponse: TIdHTTPResponse;
    FHeaders: IWiRLHeaders;
    FMediaType: TMediaType;
    FOwnContentStream: Boolean;

    { IWiRLResponse }
    function GetHeaderValue(const AName: string): string;
    function GetStatusCode: Integer;
    function GetStatusText: string;
    function GetContentType: string;
    function GetContent: string;
    function GetContentStream: TStream;
    function GetHeaders: IWiRLHeaders;
    function GetContentMediaType: TMediaType;
    function GetRawContent: TBytes;
    procedure SetStatusCode(AValue: Integer);
    procedure SetStatusText(const AValue: string);
    procedure SetOwnContentStream(const AValue: Boolean);
  public
    constructor Create(AIdHTTPResponse: TIdHTTPResponse);
    destructor Destroy; override;
  end;

  TWiRLClientIndy = class(TInterfacedObject, IWiRLClient)
  private
    FHttpClient: TIdHTTP;
    FProxyParams: TWiRLProxyConnectionInfo;
    // Setters and getters
    function GetConnectTimeout: Integer;
    procedure SetConnectTimeout(Value: Integer);
    function GetReadTimeout: Integer;
    procedure SetReadTimeout(Value: Integer);
    function GetProxyParams: TWiRLProxyConnectionInfo;
    procedure SetProxyParams(Value: TWiRLProxyConnectionInfo);
    function GetMaxRedirects: Integer;
    procedure SetMaxRedirects(const Value: Integer);
    function GetClientImplementation: TObject;

    procedure BuildRequestObject(AHeaders: IWiRLHeaders);
  public
    constructor Create; virtual;
    destructor Destroy; override;

    // Http methods
    function Get(const AURL: string; AResponseContent: TStream; AHeaders: IWiRLHeaders): IWiRLResponse;
    function Post(const AURL: string; ARequestContent, AResponseContent: TStream; AHeaders: IWiRLHeaders): IWiRLResponse;
    function Put(const AURL: string; ARequestContent, AResponseContent: TStream; AHeaders: IWiRLHeaders): IWiRLResponse;
    function Delete(const AURL: string; AResponseContent: TStream; AHeaders: IWiRLHeaders): IWiRLResponse;
    function Options(const AURL: string; AResponseContent: TStream; AHeaders: IWiRLHeaders): IWiRLResponse;
    function Head(const AURL: string; AHeaders: IWiRLHeaders): IWiRLResponse;
    function Patch(const AURL: string; ARequestContent, AResponseContent: TStream; AHeaders: IWiRLHeaders): IWiRLResponse;
  end;

const
  IndyVendorName = 'TIdHttp (Indy)';

implementation

const
  DefaultUserAgent = 'Mozilla/3.0 (compatible; WiRL with Indy Library)';

{ TWiRLClientIndy }

constructor TWiRLClientIndy.Create;
begin
  FHttpClient := TIdHTTP.Create(nil);
  FHttpClient.MaxAuthRetries := -1;
  FHttpClient.HTTPOptions := FHttpClient.HTTPOptions + [hoNoProtocolErrorException, hoWantProtocolErrorContent];
end;

function TWiRLClientIndy.Delete(const AURL: string; AResponseContent: TStream; AHeaders: IWiRLHeaders): IWiRLResponse;
begin
  BuildRequestObject(AHeaders);
  try
    FHttpClient.Delete(AURL, AResponseContent);
  except
    on E: EIdSocketError do
      Exception.RaiseOuterException(EWiRLSocketException.Create(E.Message));
  end;
  Result := TWiRLClientResponseIndy.Create(FHttpClient.Response);
end;

destructor TWiRLClientIndy.Destroy;
begin
  FHttpClient.Free;
  inherited;
end;

function TWiRLClientIndy.Get(const AURL: string; AResponseContent: TStream; AHeaders: IWiRLHeaders): IWiRLResponse;
begin
  BuildRequestObject(AHeaders);
  try
    FHttpClient.Get(AURL, AResponseContent);
  except
    on E: EIdSocketError do
      Exception.RaiseOuterException(EWiRLSocketException.Create(E.Message));
  end;
  Result := TWiRLClientResponseIndy.Create(FHttpClient.Response);
end;

function TWiRLClientIndy.GetClientImplementation: TObject;
begin
  Result := FHttpClient;
end;

function TWiRLClientIndy.GetConnectTimeout: Integer;
begin
  Result := FHttpClient.ConnectTimeout;
end;

function TWiRLClientIndy.GetMaxRedirects: Integer;
begin
  Result := FHttpClient.RedirectMaximum;
end;

function TWiRLClientIndy.GetProxyParams: TWiRLProxyConnectionInfo;
begin
  Result := FProxyParams;
end;

function TWiRLClientIndy.GetReadTimeout: Integer;
begin
  Result := FHttpClient.ReadTimeout;
end;

function TWiRLClientIndy.Head(const AURL: string; AHeaders: IWiRLHeaders): IWiRLResponse;
begin
  BuildRequestObject(AHeaders);
  try
    FHttpClient.Head(AURL);
  except
    on E: EIdSocketError do
      Exception.RaiseOuterException(EWiRLSocketException.Create(E.Message));
  end;
  Result := TWiRLClientResponseIndy.Create(FHttpClient.Response);
end;

procedure TWiRLClientIndy.BuildRequestObject(AHeaders: IWiRLHeaders);
var
  LHeader: TWiRLHeader;
begin
  // Copy custom headers
  FHttpClient.Request.CustomHeaders.Clear;
  for LHeader in AHeaders do
  begin
    FHttpClient.Request.CustomHeaders.AddValue(
      LHeader.Name,
      LHeader.Value
    );
  end;

  // Copy standard indy http headers
  FHttpClient.Request.Accept := AHeaders.Accept;
  FHttpClient.Request.AcceptCharSet := AHeaders.AcceptCharSet;
  FHttpClient.Request.AcceptEncoding := AHeaders.AcceptEncoding;
  FHttpClient.Request.AcceptLanguage := AHeaders.AcceptLanguage;
//  FHttpClient.Request.Host := FRequest.Host;
//  FHttpClient.Request.From := FRequest.From;
//  FHttpClient.Request.Referer := FRequest.Referer;
//  FHttpClient.Request.Range := FRequest.Range;
  if AHeaders.UserAgent = '' then
    FHttpClient.Request.UserAgent := DefaultUserAgent
  else
    FHttpClient.Request.UserAgent := AHeaders.UserAgent;

  // Write proxy setting
  if Assigned(FProxyParams) then
  begin
    FHttpClient.ProxyParams.BasicAuthentication := FProxyParams.BasicAuthentication;
    FHttpClient.ProxyParams.ProxyServer := FProxyParams.ProxyServer;
    FHttpClient.ProxyParams.ProxyPort := FProxyParams.ProxyPort;
    FHttpClient.ProxyParams.ProxyUsername := FProxyParams.ProxyUsername;
    FHttpClient.ProxyParams.ProxyPassword := FProxyParams.ProxyPassword;
  end;
end;

function TWiRLClientIndy.Options(const AURL: string; AResponseContent: TStream; AHeaders: IWiRLHeaders): IWiRLResponse;
begin
  BuildRequestObject(AHeaders);
  try
    FHttpClient.Options(AURL, AResponseContent);
  except
    on E: EIdSocketError do
      Exception.RaiseOuterException(EWiRLSocketException.Create(E.Message));
  end;
  Result := TWiRLClientResponseIndy.Create(FHttpClient.Response);
end;

function TWiRLClientIndy.Patch(const AURL: string; ARequestContent, AResponseContent: TStream; AHeaders: IWiRLHeaders): IWiRLResponse;
begin
  BuildRequestObject(AHeaders);
  try
    FHttpClient.Patch(AURL, ARequestContent, AResponseContent);
  except
    on E: EIdSocketError do
      Exception.RaiseOuterException(EWiRLSocketException.Create(E.Message));
  end;
  Result := TWiRLClientResponseIndy.Create(FHttpClient.Response);
end;

function TWiRLClientIndy.Post(const AURL: string; ARequestContent, AResponseContent: TStream; AHeaders: IWiRLHeaders): IWiRLResponse;
begin
  BuildRequestObject(AHeaders);
  try
    FHttpClient.Post(AURL, ARequestContent, AResponseContent);
  except
    on E: EIdSocketError do
      Exception.RaiseOuterException(EWiRLSocketException.Create(E.Message));
  end;
  Result := TWiRLClientResponseIndy.Create(FHttpClient.Response);
end;

function TWiRLClientIndy.Put(const AURL: string; ARequestContent, AResponseContent: TStream; AHeaders: IWiRLHeaders): IWiRLResponse;
begin
  BuildRequestObject(AHeaders);
  try
    FHttpClient.Put(AURL, ARequestContent, AResponseContent);
  except
    on E: EIdSocketError do
      Exception.RaiseOuterException(EWiRLSocketException.Create(E.Message));
  end;
  Result := TWiRLClientResponseIndy.Create(FHttpClient.Response);
end;

procedure TWiRLClientIndy.SetConnectTimeout(Value: Integer);
begin
  FHttpClient.ConnectTimeout := Value;
end;

procedure TWiRLClientIndy.SetMaxRedirects(const Value: Integer);
begin
  FHttpClient.RedirectMaximum := Value;
end;

procedure TWiRLClientIndy.SetProxyParams(Value: TWiRLProxyConnectionInfo);
begin
  FProxyParams := Value;
end;

procedure TWiRLClientIndy.SetReadTimeout(Value: Integer);
begin
  FHttpClient.ReadTimeout := Value;
end;

{ TWiRLClientResponseIndy }

constructor TWiRLClientResponseIndy.Create(AIdHTTPResponse: TIdHTTPResponse);
begin
  inherited Create;
  FIdHTTPResponse := AIdHTTPResponse;
  FOwnContentStream := True;
end;

destructor TWiRLClientResponseIndy.Destroy;
begin
  FMediaType.Free;
  if FOwnContentStream then
    FreeAndNil(FIdHTTPResponse.ContentStream);
  inherited;
end;

function TWiRLClientResponseIndy.GetContent: string;
begin
  Result := EncodingFromCharSet(GetContentMediaType.Charset).GetString(GetRawContent);
end;

function TWiRLClientResponseIndy.GetContentMediaType: TMediaType;
begin
  if not Assigned(FMediaType) then
    FMediaType := TMediaType.Create(GetContentType);
  Result := FMediaType;
end;

function TWiRLClientResponseIndy.GetContentStream: TStream;
begin
  Result := FIdHTTPResponse.ContentStream;
end;

function TWiRLClientResponseIndy.GetContentType: string;
begin
  Result := GetHeaderValue('Content-Type');
end;

function TWiRLClientResponseIndy.GetHeaders: IWiRLHeaders;
var
  LIndex: Integer;
  LName, LValue: string;
begin
  if not Assigned(FHeaders) then
  begin
    FHeaders := TWiRLHeaders.Create;
    for LIndex := 0 to FIdHTTPResponse.RawHeaders.Count - 1 do
    begin
      LName := FIdHTTPResponse.RawHeaders.Names[LIndex];
      LValue := FIdHTTPResponse.RawHeaders.Values[LName];
      FHeaders.AddHeader(TWiRLHeader.Create(LName, LValue));
    end;
  end;
  Result := FHeaders;
end;

function TWiRLClientResponseIndy.GetHeaderValue(const AName: string): string;
begin
  Result := FIdHTTPResponse.RawHeaders.Values[AName];
end;

function TWiRLClientResponseIndy.GetRawContent: TBytes;
begin
  if (GetContentStream <> nil) and (GetContentStream.Size > 0) then
  begin
    GetContentStream.Position := 0;
    SetLength(Result, GetContentStream.Size);
    GetContentStream.ReadBuffer(Result[0], GetContentStream.Size);
  end;
end;

function TWiRLClientResponseIndy.GetStatusCode: Integer;
begin
  Result := FIdHTTPResponse.ResponseCode;
end;

function TWiRLClientResponseIndy.GetStatusText: string;
begin
  Result := FIdHTTPResponse.ResponseText;
end;

procedure TWiRLClientResponseIndy.SetOwnContentStream(const AValue: Boolean);
begin
  FOwnContentStream := AValue;
end;

procedure TWiRLClientResponseIndy.SetStatusCode(AValue: Integer);
begin
  FIdHTTPResponse.ResponseCode := AValue;
end;

procedure TWiRLClientResponseIndy.SetStatusText(const AValue: string);
begin
  FIdHTTPResponse.ResponseText := AValue;
end;

initialization
  TWiRLClientRegistry.Instance.RegisterClient<TWiRLClientIndy>(
    IndyVendorName{$IFNDEF HAS_NETHTTP_CLIENT}, True{$ENDIF});

end.
