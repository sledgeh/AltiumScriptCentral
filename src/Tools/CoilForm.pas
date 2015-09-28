{..............................................................................


...............................................................................}

var
centerX : Double;
centerY : Double;
radius : Double;
rotation : Double;  // a
gain : Double;// b
// derivatives
clearance : Double;


Type

  TCoilArchimedForm = class(TForm)
    elblFormula : TEdit;
    elblFiBegin : TEdit;
    edFiBegin   : TEdit;
    elblFiEnd   : TEdit;
    edFiEnd     : TEdit;


    procedure FormCreate(Sender: TObject);
    procedure edFiBeginChange(Sender: TObject);
    function ParseFields() : CoilParameters;
  private
    //function ParseFields() : CoilParameters;
    (*procedure InitPlayGround(Dummy   : Integer);
    function  GamePlay      (xo_Move : Integer) : integer;
    function  CheckWin      (iPos    : TXOPosArray) : integer;*)
  end;

implementation
{$R *.DFM}

{..............................................................................}
Var
  CoilArchimedForm    : TCoilArchimedForm;
{..............................................................................}




{ calculate main params if some of them are NIL from derivatives }
function RecalculateCoilParams() : Boolean;
begin
    ;
end;



{..............................................................................}
Procedure RunPlaceCoilArchimedDialog;
var
    board : IPCB_Board;
begin
    // Load current board
    If PCBServer = Nil Then begin ShowMessage('Go to PCBdoc first'); Exit; end;
    Board := PCBServer.GetCurrentPCBBoard;
    If Board = Nil then begin ShowMessage('No board'); Exit; end;

    CoilArchimedForm.ShowModal;
End;
{..............................................................................}


{ Close the dialog windows with CANCEL button }
procedure TCoilArchimedForm.btCancelClick(Sender: TObject);
begin
    Close;
end;
{............................}



{procedure TCoilArchimedForm.edFiBeginChange(Sender: TObject);
var
    str;
begin
    edFiBeginChange.getText();
    if str = '2' then begin
        edFiBeginChange.setColor(clRed);
    end;
end;
}



function ParseFiled();
begin
    // check str contains number, optional fractional separator, optional units
    // if no units specified use from document
    //TCoilArchimedForm.
end;

{ Перечитать поля формы, проверить, и вернуть структуру с параметрами для вывода катушки }
function TCoilArchimedForm.ParseFields() : TCoilParameters;
var
    res : TCoilParameters;
begin
    res.centerX := 0.25;
    Result := res;
end;
{ .......................... }


procedure TCoilArchimedForm.btnOKClick(Sender: TObject);
var
    board : IPCB_Board;
    p : TPoint;
    pp : TPolarPoint;
    xm;
    ym;
    LineThicknessMm : double;
    Layer : IPCB_LayerObject;
    //coordinate : IPCB_Coordinate;
    cp : CoilParameters;
begin
    board := PCBServer.GetCurrentPCBBoard;

    // Get user to choose where the centre of the coil is going to go
    if board.ChooseLocation(xm, ym, 'Select the centre of the coil') = false
        then exit;

    //cp := ParseFields();
    LineThicknessMm := 0.3;

    // Convert the string to a valid Altium layer
    Layer := String2Layer('Top Layer');
    If Layer = 0 Then Begin
       exit
    End;
    //ShowMessage("Layer = " + CStr(Layer))Dim Layer

    DrawCoilArchimedTriangulated( xm, ym, LineThicknessMm, Layer, 0, 26*2*PI, 0, 0.05 );
    //DrawCoilArchimedTriangulated( xm, ym, LineThicknessMm, Layer, nil,nil, nil, nil);

    // Refresh the PCB screen
    Client.SendMessage('PCB:Zoom', 'Action=Redraw' , 255, Client.CurrentView);

    //PlaceCoilArchimed;
end;


procedure TCoilArchimedForm.edWidthExit(Sender: TObject);
var
    value : Double;
begin
    showinfo('edWidthExit');
    if not Str2Double( Sender.Text, value ) then
        sender.color := clRed
    else
        sender.color := clWindow;
    end;
    ShowInfo('he'+FloatToStr(value));
end;

procedure TCoilArchimedForm.edTriangulationExit(Sender: TObject);
var
    value : Double;
begin
    showinfo('edTriangulationExit');
    if not Str2Double( Sender.Text, value ) then
        sender.color := clRed
    else
        sender.color := clWindow;
    end;
    ShowInfo('he '+FloatToStr(value));
end;


end.
