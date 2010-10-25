unit JEN_Display;

interface

uses
  XSystem;

type
  TDisplay = class
  protected
    var
      FValid : Boolean;
    function  GetFullScreen : Boolean; virtual; abstract;
    procedure SetActive(Value : Boolean); virtual; abstract;
    function  GetActive : Boolean; virtual; abstract;
    function  GetDC : HDC ; virtual; abstract;
    function  GetHandle : HWND; virtual; abstract;
    function  GetWidth : Cardinal; virtual; abstract;
    function  GetHeight : Cardinal; virtual; abstract;
  public
    property IsValid  : Boolean read FValid;
    property FullScreen : Boolean read GetFullScreen;
    property Active : Boolean read GetActive write SetActive;
    property Handle : HWND  read GetHandle;
    property DC : HDC read GetDC;
    property Width : Cardinal read GetWidth;
    property Height : Cardinal read GetHeight;

    procedure Swap;
    procedure Update; virtual; abstract;
  end;

implementation

uses
  JEN_MAIN;

procedure TDisplay.Swap;
begin
  SwapBuffers(DC);
end;

end.
