// ************************************************************************
// ***************************** CEF4Delphi *******************************
// ************************************************************************
//
// CEF4Delphi is based on DCEF3 which uses CEF to embed a chromium-based
// browser in Delphi applications.
//
// The original license of DCEF3 still applies to CEF4Delphi.
//
// For more information about CEF4Delphi visit :
//         https://www.briskbard.com/index.php?lang=en&pageid=cef
//
//        Copyright © 2020 Salvador Diaz Fau. All rights reserved.
//
// ************************************************************************
// ************ vvvv Original license and comments below vvvv *************
// ************************************************************************
(*
 *                       Delphi Chromium Embedded 3
 *
 * Usage allowed under the restrictions of the Lesser GNU General Public License
 * or alternatively the restrictions of the Mozilla Public License 1.1
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 *
 * Unit owner : Henri Gourvest <hgourvest@gmail.com>
 * Web site   : http://www.progdigy.com
 * Repository : http://code.google.com/p/delphichromiumembedded/
 * Group      : http://groups.google.com/group/delphichromiumembedded
 *
 * Embarcadero Technologies, Inc is not permitted to use or redistribute
 * this source code without explicit permission.
 *
 *)

unit BrowserUnit;

{$I cef.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  {$ELSE}
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls,
  {$ENDIF}
  uCEFChromium, uCEFWindowParent, uCEFChromiumWindow, uCEFTypes, uCEFInterfaces,
  uCEFWinControl, uCEFSentinel, Vcl.ComCtrls;

const

  YAHOO_SEARCH1 = 'https://search.yahoo.com/search;_ylt=A2KLfScELd1fUs8A5TBDDWVH;';
  YAHOO_SEARCH2 = '_ylc=X1MDMTE5NzgwNDg2NwRfcgMyBGZyAwRncHJpZAN3Zk40RWFXOVFKdS5HTml0c2cuOUlBBG5fcnNsdAMwBG5fc3VnZwMxMARvcmlnaW4Dc2VhcmNoLnlhaG9vLmNvbQRwb3MDMARwcXN0cgMEcHFzdHJsAwRxc3RybAM1BHF1ZXJ5A29iYW1hBHRfc3RtcAMxNjA4MzMwNTA3?fr2=sb-top-search&p=obama&fr=sfp&iscqry=';

  YANDEX_SEARCH1 = 'https://yandex.ru/search/?lr=105083&text=obama';
  DUCKDUCK_SEARCH  = 'https://duckduckgo.com/?q=obama&t=h_&ia=web';

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    FindPanel: TPanel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    ChromiumWindow1: TChromiumWindow;
    TabSheet2: TTabSheet;
    ChromiumWindow2: TChromiumWindow;
    ComboBox1: TComboBox;
    TabSheet3: TTabSheet;
    ChromiumWindow3: TChromiumWindow;
    procedure Timer1Timer(Sender: TObject);

    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure ChromiumWindow1Close(Sender: TObject);
    procedure ChromiumWindow1BeforeClose(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure ComboBox1KeyPress(Sender: TObject; var Key: Char);

  private
    // You have to handle this two messages to call NotifyMoveOrResizeStarted or some page elements will be misaligned.
    procedure WMMove(var aMessage : TWMMove); message WM_MOVE;
    procedure WMMoving(var aMessage : TMessage); message WM_MOVING;
    // You also have to handle these two messages to set GlobalCEFApp.OsmodalLoop
    procedure WMEnterMenuLoop(var aMessage: TMessage); message WM_ENTERMENULOOP;
    procedure WMExitMenuLoop(var aMessage: TMessage); message WM_EXITMENULOOP;

  protected
    // Variables to control when can we destroy the form safely
    FCanClose : boolean;  // Set to True in TChromium.OnBeforeClose
    FClosing  : boolean;  // Set to True in the CloseQuery event.

    procedure Chromium_OnBeforePopup(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const targetUrl, targetFrameName: ustring; targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean; const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo; var client: ICefClient; var settings: TCefBrowserSettings; var extra_info: ICefDictionaryValue; var noJavascriptAccess: Boolean; var Result: Boolean);

  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  uCEFApplication;

// This is a demo with the simplest web browser you can build using CEF4Delphi and
// it doesn't show any sign of progress like other web browsers do.

// Remember that it may take a few seconds to load if Windows update, your antivirus or
// any other windows service is using your hard drive.

// Depending on your internet connection it may take longer than expected.

// Please check that your firewall or antivirus are not blocking this application
// or the domain "google.com". If you don't live in the US, you'll be redirected to
// another domain which will take a little time too.

// Destruction steps
// =================
// 1. The FormCloseQuery event sets CanClose to False and calls TChromiumWindow.CloseBrowser, which triggers the TChromiumWindow.OnClose event.
// 2. The TChromiumWindow.OnClose event calls TChromiumWindow.DestroyChildWindow which triggers the TChromiumWindow.OnBeforeClose event.
// 3. TChromiumWindow.OnBeforeClose sets FCanClose := True and sends WM_CLOSE to the form.


// This function converts a string into a RFC 1630 compliant URL
function URLEncode(Value : String) : String;
const
  ValidURLChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$-_@.&+-!*"''(),;/#?:';
Var I : Integer;
Begin
   Result := '';
   For I := 1 To Length(Value) Do
      Begin
         If Pos(UpperCase(Value[I]), ValidURLChars) > 0 Then
            Result := Result + Value[I]
         Else
            Begin
               If Value[I] = ' ' Then
                  Result := Result + '+'
               Else
                  Begin
                     Result := Result + '%';
                     Result := Result + IntToHex(Byte(Value[I]), 2);
                  End;
            End;
      End;
End;

function GetQwant(F: AnsiString): AnsiString;
begin
  Result:='https://www.qwant.com/?q='+Trim(F)+'&t=all';
  Result:=StringReplace(Result,' ','%20',[rfReplaceAll]);
end;

function GetDuckDuck(F: AnsiString): AnsiString;
begin
  Result:='https://duckduckgo.com/?q='+Trim(F)+'&t=h_&ia=web';
  Result:=StringReplace(Result,' ','%20',[rfReplaceAll]);
end;

function GetYandex(F: AnsiString): AnsiString;
begin
  Result:='https://yandex.ru/search/?lr=105083&text='+Trim(F);
  Result:=StringReplace(Result,' ','%20',[rfReplaceAll]);
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FCanClose;

  if not(FClosing) then
    begin
      FClosing := True;
      Visible  := False;
      ChromiumWindow1.CloseBrowser(True);
      ChromiumWindow2.CloseBrowser(True);
      ChromiumWindow3.CloseBrowser(True);
    end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FCanClose := False;
  FClosing  := False;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  // For simplicity, this demo blocks all popup windows and new tabs
  ChromiumWindow1.ChromiumBrowser.OnBeforePopup := Chromium_OnBeforePopup;
  ChromiumWindow2.ChromiumBrowser.OnBeforePopup := Chromium_OnBeforePopup;
  ChromiumWindow3.ChromiumBrowser.OnBeforePopup := Chromium_OnBeforePopup;

  // You *MUST* call CreateBrowser to create and initialize the browser.
  // This will trigger the AfterCreated event when the browser is fully
  // initialized and ready to receive commands.

  // GlobalCEFApp.GlobalContextInitialized has to be TRUE before creating any browser
  // If it's not initialized yet, we use a simple timer to create the browser later.
  if not(ChromiumWindow1.CreateBrowser) then Timer1.Enabled := True;
  if not(ChromiumWindow2.CreateBrowser) then Timer1.Enabled := True;
  if not(ChromiumWindow3.CreateBrowser) then Timer1.Enabled := True;
end;

procedure TForm1.ChromiumWindow1BeforeClose(Sender: TObject);
begin
  FCanClose := True;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TForm1.ChromiumWindow1Close(Sender: TObject);
begin
  // DestroyChildWindow will destroy the child window created by CEF at the top of the Z order.
  if not(ChromiumWindow1.DestroyChildWindow) then
    begin
      FCanClose := True;
      PostMessage(Handle, WM_CLOSE, 0, 0);
    end;

    if not(ChromiumWindow2.DestroyChildWindow) then
    begin
      FCanClose := True;
      PostMessage(Handle, WM_CLOSE, 0, 0);
    end;

    if not(ChromiumWindow3.DestroyChildWindow) then
    begin
      FCanClose := True;
      PostMessage(Handle, WM_CLOSE, 0, 0);
    end;

end;

procedure TForm1.Chromium_OnBeforePopup(      Sender             : TObject;
                                        const browser            : ICefBrowser;
                                        const frame              : ICefFrame;
                                        const targetUrl          : ustring;
                                        const targetFrameName    : ustring;
                                              targetDisposition  : TCefWindowOpenDisposition;
                                              userGesture        : Boolean;
                                        const popupFeatures      : TCefPopupFeatures;
                                        var   windowInfo         : TCefWindowInfo;
                                        var   client             : ICefClient;
                                        var   settings           : TCefBrowserSettings;
                                        var   extra_info         : ICefDictionaryValue;
                                        var   noJavascriptAccess : Boolean;
                                        var   Result             : Boolean);
begin
  // For simplicity, this demo blocks all popup windows and new tabs
  Result := (targetDisposition in [WOD_NEW_FOREGROUND_TAB, WOD_NEW_BACKGROUND_TAB, WOD_NEW_POPUP, WOD_NEW_WINDOW]);
end;

procedure TForm1.ComboBox1KeyPress(Sender: TObject; var Key: Char);
begin
   if Key=#13 then
  begin
    ComboBox1.Items.Add(Trim(ComboBox1.Text));
    if (Pos('://',ComboBox1.Text)>0) or
       (Pos('www.',ComboBox1.Text)>0) or
       (Pos('.gov',ComboBox1.Text)>0) or
       (Pos('.com',ComboBox1.Text)>0) or
       (Pos('.edu',ComboBox1.Text)>0) or
       (Pos('.ru',ComboBox1.Text)>0) then
    begin
      TabSheet1.Caption:=Copy(Trim(ComboBox1.Text),1,16)+'...';
      TabSheet1.TabVisible:=True;
      TabSheet2.Caption:='None';
      TabSheet2.TabVisible:=False;
      TabSheet3.Caption:='None';
      TabSheet3.TabVisible:=False;
      ChromiumWindow1.LoadURL(ComboBox1.Text);
    end
    else
    begin
      TabSheet1.Caption:=Copy(Trim(ComboBox1.Text),1,16)+'...';
      TabSheet1.TabVisible:=True;
      ChromiumWindow1.LoadURL(GetDuckDuck(ComboBox1.Text));
      TabSheet2.Caption:=Copy(Trim(ComboBox1.Text),1,16)+'...';
      TabSheet2.TabVisible:=True;
      ChromiumWindow2.LoadURL(GetYandex(ComboBox1.Text));
      TabSheet3.Caption:=Copy(Trim(ComboBox1.Text),1,16)+'...';
      TabSheet3.TabVisible:=True;
      ChromiumWindow3.LoadURL(GetQwant(ComboBox1.Text));
    end;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  ChromiumWindow1.LoadURL('https://google.com/');
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  ChromiumWindow1.LoadURL('https://yandex.ru/');
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  ChromiumWindow1.LoadURL('https://yahoo.com/');
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  ChromiumWindow2.LoadURL('https://google.com/');
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  ChromiumWindow2.LoadURL('https://yandex.ru/');
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  ChromiumWindow2.LoadURL('https://yahoo.com/');
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  ChromiumWindow1.LoadURL(YAHOO_SEARCH1+YAHOO_SEARCH2);
  //ChromiumWindow2.LoadURL(YANDEX_SEARCH1);
  ChromiumWindow2.LoadURL(DUCKDUCK_SEARCH);
end;

procedure TForm1.Button8Click(Sender: TObject);
begin
  ChromiumWindow1.LoadURL('https://duckduckgo.com/');
end;

procedure TForm1.Button9Click(Sender: TObject);
begin
  ChromiumWindow2.LoadURL('https://duckduckgo.com/');
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  if not(ChromiumWindow1.CreateBrowser) and not(ChromiumWindow1.Initialized) then Timer1.Enabled := True;
  if not(ChromiumWindow2.CreateBrowser) and not(ChromiumWindow2.Initialized) then Timer1.Enabled := True;
  if not(ChromiumWindow3.CreateBrowser) and not(ChromiumWindow3.Initialized) then Timer1.Enabled := True;
end;

procedure TForm1.WMMove(var aMessage : TWMMove);
begin
  inherited;
  if (ChromiumWindow1 <> nil) then ChromiumWindow1.NotifyMoveOrResizeStarted;
  if (ChromiumWindow2 <> nil) then ChromiumWindow2.NotifyMoveOrResizeStarted;
  if (ChromiumWindow3 <> nil) then ChromiumWindow3.NotifyMoveOrResizeStarted;
end;

procedure TForm1.WMMoving(var aMessage : TMessage);
begin
  inherited;
  if (ChromiumWindow1 <> nil) then ChromiumWindow1.NotifyMoveOrResizeStarted;
  if (ChromiumWindow2 <> nil) then ChromiumWindow2.NotifyMoveOrResizeStarted;
  if (ChromiumWindow3 <> nil) then ChromiumWindow3.NotifyMoveOrResizeStarted;
end;

procedure TForm1.WMEnterMenuLoop(var aMessage: TMessage);
begin
  inherited;

  if (aMessage.wParam = 0) and (GlobalCEFApp <> nil) then GlobalCEFApp.OsmodalLoop := True;
end;

procedure TForm1.WMExitMenuLoop(var aMessage: TMessage);
begin
  inherited;

  if (aMessage.wParam = 0) and (GlobalCEFApp <> nil) then GlobalCEFApp.OsmodalLoop := False;
end;

end.
