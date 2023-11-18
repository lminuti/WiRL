{******************************************************************************}
{                                                                              }
{       WiRL: RESTful Library for Delphi                                       }
{                                                                              }
{       Copyright (c) 2015-2019 WiRL Team                                      }
{                                                                              }
{       https://github.com/delphi-blocks/WiRL                                  }
{                                                                              }
{******************************************************************************}
unit WiRL.Core.Register;

{$I ..\Core\WiRL.inc}

interface

uses
  System.SysUtils, System.Classes,
  WiRL.Rtti.Utils,
  WiRL.Core.Engine,
  WiRL.Core.MessageBody.Default,
  WiRL.http.Engines,
  WiRL.http.FileSystemEngine,
  WiRL.http.Server,
  WiRL.http.Server.Indy;

procedure Register;

const
  WIRL_CAPTION = 'WiRL RESTful Library for Delphi 4.5.0';
  WIRL_LICENSE = 'Apache License, Version 2.0';
  WIRL_DESCRIPTION =
    'WiRL: 100% RESTful Library for Delphi' + sLineBreak + sLineBreak +
    'Copyright � 2015-2023 WiRL Team. All rights reserved.' + sLineBreak +
    'https://github.com/delphi-blocks/WiRL' + sLineBreak + sLineBreak +
    '[Powered by]' + sLineBreak + sLineBreak +
    'Delphi JOSE and JWT Library' + sLineBreak +
    'https://github.com/paolo-rossi/delphi-jose-jwt' + sLineBreak + sLineBreak +
    'Neon: JSON Serialization Library' + sLineBreak +
    'https://github.com/paolo-rossi/delphi-neon' + sLineBreak + sLineBreak +
    'OpenAPI for Delphi Library' + sLineBreak +
    'https://github.com/paolo-rossi/OpenAPI-Delphi' + sLineBreak + sLineBreak +
    'GraphQL for Delphi' + sLineBreak +
    'https://github.com/lminuti/graphql' + sLineBreak + sLineBreak +
    'Indy' + sLineBreak +
    'https://github.com/IndySockets/Indy'
  ;

implementation

uses
  Winapi.Windows, ToolsAPI, WiRL.Wizards;

var
  AboutBoxServices: IOTAAboutBoxServices = nil;
  AboutBoxIndex: Integer = -1;


procedure RegisterAboutBox;
var
  ProductImage: HBITMAP;
begin
  if AboutBoxIndex = -1 then
  begin
    Supports(BorlandIDEServices,IOTAAboutBoxServices, AboutBoxServices);
    if not Assigned(AboutBoxServices) then
      Exit;
    ProductImage := LoadBitmap(FindResourceHInstance(HInstance), 'WiRLSplash');
    if ProductImage = 0 then
      Exit;
    AboutBoxIndex := AboutBoxServices.AddPluginInfo(WIRL_CAPTION, WIRL_DESCRIPTION, ProductImage, False);
  end;
end;

procedure UnregisterAboutBox;
begin
  if (AboutBoxIndex <> -1) and Assigned(AboutBoxServices) then
  begin
    AboutBoxServices.RemovePluginInfo(AboutBoxIndex);
    AboutBoxIndex := -1;
    AboutBoxServices := nil;
  end;
end;

procedure RegisterSplashScreen;
var
  ProductImage: HBITMAP;
begin
  if Assigned(SplashScreenServices) then
  begin
    ProductImage := LoadBitmap(FindResourceHInstance(HInstance), 'WiRLSplash');
    if ProductImage <> 0 then
    begin
      SplashScreenServices.AddPluginBitmap(WIRL_CAPTION, ProductImage, False, WIRL_LICENSE);
    end;
  end;
end;


procedure Register;
begin
  RegisterComponents('WiRL Server', [TWiRLEngine]);
  RegisterComponents('WiRL Server', [TWiRLhttpEngine]);
  RegisterComponents('WiRL Server', [TWiRLServer]);
  RegisterComponents('WiRL Server', [TWiRLFileSystemEngine]);
  RegisterComponents('WiRL Server', [TWiRLMBWDefaultProvider]);

  RegisterPackageWizard(TWiRLServeProjectWizard.Create);

  RegisterSplashScreen;
  RegisterAboutBox;
end;

initialization
  {$IFDEF CUSTOM_ATTRIBUTE_BUG}
  TRttiPatch.AutoFreeDescs := True;
  {$ENDIF}

finalization
  UnregisterAboutBox;

end.
