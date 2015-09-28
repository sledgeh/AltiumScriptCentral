{
@author: Kyb SledgeHammer







}


(*type
    TPoint Record
        x : double;
        y : double;
    end;
    TPolarPoint Record
        r : double;
        f : double; // in radians
    end;
*)
const
    PI = 3.1415926;
    PI2 = 2*PI;

Function degree2rad(degree);
begin
     result := degree*PI/180;
end;


{
  r(fi) = a + b*fi
}
Function DrawCoilArchimedTriangulated( x_in, y_in, LineThicknessMm, Layer, f_beg, f_end, aa, bb );
const
    //minDiam = 2;
    //maxDiam = 20;
    //coil_turns = 7;
    //rotation = 0;   // in radians
    A_default = 0;            // rotation factor in mm
    B_default = 0.2;          // step factor in xz
    F_BEG_default = PI;          // begin in radians
    F_END_default = 3*2*PI;  // end in radians
var
    Board : IPCB_Board;
    f : Double;
    fi_end : Double;
    a : Double;
    b : Double;
    track;//prev_track;
    prev_x; prev_y : Double;
    r;
begin
    if f_beg <> nil then f := f_beg
    else f := F_BEG_default;

    if f_end <> nil then fi_end := f_end
    else fi_end := F_END_default;

    if aa <> nil then a := aa
    else a:=A_default;

    if bb <> nil then b:=bb
    else b:=B_default;

    // Initialise undo-redo systems
    PCBServer.PreProcess;
    Board := PCBServer.GetCurrentPCBBoard;

    // Create coil turns
    prev_x := x_in;
    prev_y := y_in;
    While f <= fi_end Do Begin
        track := PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default);
        track.x1 := prev_x;
        track.y1 := prev_y;
        r := a + b * f;
        track.x2 := track.x1 + MMsToCoord(r * cos(f));
        track.y2 := track.y1 + MMsToCoord(r * sin(f));
        prev_x:= track.x2;
        prev_y:= track.y2;
        track.Width := MMsToCoord(LineThicknessMm);
        track.Layer := Layer;
        Board.AddPCBObject(track);
        PCBServer.SendMessageToRobots(PCBServer.GetCurrentPCBBoard.I_ObjectAddress,
                c_Broadcast, PCBM_BoardRegisteration, track.I_ObjectAddress);

        (*Client.SendMessage('PCB:Zoom', 'Action=Redraw' , 255, Client.CurrentView);
        ShowMessage( 'track.x1 = ' + FloatToStr(track.x1)
                + ' track.y1 = ' + FloatToStr(track.y1)
                + ' track.x2 = ' + FloatToStr(track.x2)
                + ' track.y2 = ' + FloatToStr(track.y2) );*)
        f := f + 2*PI/12;
    End;
    // Initialise undo-redo systems
    PCBServer.PostProcess;
End;


{ Places Coil - Archimed's Spiral
  To be used as tool on toolbar to create coil
}
procedure PlaceCoilArchimed;
var
    board : IPCB_Board;
    p : TPoint;
    pp : TPolarPoint;
    xm;
    ym;
    LineThicknessMm : double;
    Layer : IPCB_LayerObject;
    //coordinate : IPCB_Coordinate;
begin
    // Load current board
    If PCBServer = Nil Then Exit;
    Board := PCBServer.GetCurrentPCBBoard;
    If Board = Nil then exit;

    // Get user to choose where the centre of the coil is going to go
    if Board.ChooseLocation(xm, ym, 'Select the centre of the coil') = false
        then exit;

    LineThicknessMm := 0.3;

    // Convert the string to a valid Altium layer
    Layer := String2Layer('Top Layer');
    If Layer = 0 Then Begin
       // Show error msg, close "DrawCoil" form and exit
       //ShowMessage("ERROR: '" + EditDrawLayer.Text + "' in 'Draw Layer' box is not a valid layer!")
       //FormDrawCoil.Close
       exit
    End;
    //ShowMessage("Layer = " + CStr(Layer))Dim Layer

    DrawCoilArchimedTriangulated( xm, ym, LineThicknessMm, Layer, 0, 7*pi*2, 0, 0.02 );

    // Refresh the PCB screen
    Client.SendMessage('PCB:Zoom', 'Action=Redraw' , 255, Client.CurrentView);

end;



{

}
Function DrawCoilType1( xm, ym, LineThicknessMm, Layer );
const
    minDiam = 2;
    maxDiam = 20;
    coil_turns = 7;
    rotation = 0;
var
    Board : IPCB_Board;
    radius_step : double;
    idx : Integer;
    arc : IPCB_Arc;
    track;
    prev_track;
begin
    // Initialise undo-redo systems
    PCBServer.PreProcess;
    Board := PCBServer.GetCurrentPCBBoard;
    //Board.NewUndo;
    radius_step := (maxDiam  - minDiam) / 2 / coil_turns;

    // Create coil turns
    For idx := 0 To (coil_turns - 1) Do Begin
        arc := PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default);
        arc.XCenter := xm;
        arc.YCenter := ym;
        arc.Radius := MMsToCoord(minDiam) / 2 + idx * MMsToCoord(radius_step);
        arc.StartAngle := 0 + rotation;
        arc.EndAngle := 250 + rotation;
        arc.LineWidth := MMsToCoord(LineThicknessMm);
        arc.Layer := Layer;
        Board.AddPCBObject(arc);
        // Update the undo System in DXP that a new vIa object has been added to the board
        PCBServer.SendMessageToRobots(PCBServer.GetCurrentPCBBoard.I_ObjectAddress,
                c_Broadcast, PCBM_BoardRegisteration, arc.I_ObjectAddress);

        track := PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default);
        track.x1 := arc.XCenter + arc.Radius * cos(degree2rad(arc.EndAngle));
        track.y1 := arc.YCenter + arc.Radius * sin(degree2rad(arc.EndAngle));
        track.x2 := track.x1 + arc.Radius * cos(degree2rad(rotation)); //* 0.8
        track.y2 := track.y1 + arc.Radius * sin(degree2rad(rotation)); //* 0.8
        track.Width := MMsToCoord(LineThicknessMm);
        track.Layer := Layer;
        Board.AddPCBObject(track);
        PCBServer.SendMessageToRobots(PCBServer.GetCurrentPCBBoard.I_ObjectAddress,
                c_Broadcast, PCBM_BoardRegisteration, track.I_ObjectAddress);

        prev_track := track;
        track := PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default);
        track.x1 := prev_track.x2;
        track.y1 := prev_track.y2;
        track.x2 := arc.XCenter + (arc.Radius + MMsToCoord(radius_step)) * cos(degree2rad(arc.StartAngle));//track.x1 + arc.Radius * cos(degree2rad(rotation+45) * 1.4
        track.y2 := arc.YCenter + (arc.Radius + MMsToCoord(radius_step)) * sin(degree2rad(arc.StartAngle));//track.y1 + arc.Radius * sin(degree2rad(rotation+45) * 1.4
        track.Width := MMsToCoord(LineThicknessMm);
        track.Layer := Layer;
        Board.AddPCBObject(track);
        PCBServer.SendMessageToRobots(PCBServer.GetCurrentPCBBoard.I_ObjectAddress,
                c_Broadcast, PCBM_BoardRegisteration, track.I_ObjectAddress);

        Result := track;
    End;

    //Board.EndUndo;
    // Initialise undo-redo systems
    PCBServer.PostProcess;
End;


{ Places Coil - Archimed's Spiral
  To be used as tool on toolbar to create coil
}
procedure PlaceCoilType1;
var
    board;
    p : TPoint;
    pp : TPolarPoint;
    xm;
    ym;
    LineThicknessMm : double;
    Layer : IPCB_LayerObject;
begin
    // Load current board
    If PCBServer = Nil Then Exit;
    Board := PCBServer.GetCurrentPCBBoard;
    If Board = Nil then exit;

    // Get user to choose where the centre of the coil is going to go
    if Board.ChooseLocation(xm, ym, 'Select the centre of the coil') = false
        then exit;

    LineThicknessMm := 0.3;

    // Convert the string to a valid Altium layer
    Layer := String2Layer('Top Layer');
    If Layer = 0 Then Begin
       // Show error msg, close "DrawCoil" form and exit
       //ShowMessage("ERROR: '" + EditDrawLayer.Text + "' in 'Draw Layer' box is not a valid layer!")
       //FormDrawCoil.Close
       exit
    End;
    //ShowMessage("Layer = " + CStr(Layer))Dim Layer

    DrawCoilType1( xm, ym, LineThicknessMm, Layer );

    // Refresh the PCB screen
    Client.SendMessage('PCB:Zoom', 'Action=Redraw' , 255, Client.CurrentView);

end;



