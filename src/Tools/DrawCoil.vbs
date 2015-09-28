'                                                                                                                 '
' @file               DrawCoil.vbs
' @author             Kyb Sledge <i.kyb@ya.ru>
' @created            2015-09-20
' @last-modified      2015-09-20
' @brief              Script draws a coil made from tracks.
'                     Ability to specify the number of edges, track width, rotation, e.t.c.
' @details
'                     See README.rst in repo root dir for more info.

' Forces us to explicitly define all variables before using them
Option Explicit

' @brief       Used to store board object.
Private Board


' To be used as tool on toolbar to create coil
'
Sub PlaceCoil_tool
    'dim board
    ' Load current board
    If PCBServer Is Nothing Then
        ShowMessage("Not a PCB or footprint editor activated.")
    End If

    Set Board = PCBServer.GetCurrentPCBBoard
    If Board Is Nothing Then
        ShowMessage("Not a PCB or footprint loaded.")
        Exit Sub
    End If

    ' Get user to choose where the centre of the coil is going to go
    Dim xm, ym
    Call Board.ChooseLocation(xm, ym, "Select the centre of the coil")
    Dim LineThicknessMm
    LineThicknessMm = 0.3

    Dim Layer
     ' Convert the string to a valid Altium layer
     Layer = String2Layer("Top Layer")
     If Layer = 0 Then
        ' Show error msg, close "DrawCoil" form and exit
        ShowMessage("ERROR: '" + EditDrawLayer.Text + "' in 'Draw Layer' box is not a valid layer!")
        'FormDrawCoil.Close
        Exit Sub
     End If
     'ShowMessage("Layer = " + CStr(Layer))Dim Layer


    ' Initialise systems
    Call PCBServer.PreProcess
    'dim last_drawen
    'last_drawen = DrawCoilByCoordinates( xm, ym, LineThicknessMm, Layer )
    Call DrawCoilByCoordinates( xm, ym, LineThicknessMm, Layer )

    ' Refresh the PCB screen
    Call Client.SendMessage("PCB:Zoom", "Action=Redraw" , 255, Client.CurrentView)

    ' Update the undo System in DXP that a new vIa object has been added to the board
    'Call PCBServer.SendMessageToRobots(Board.I_ObjectAddress, c_Broadcast, PCBM_BoardRegisteration, last_drawen.I_ObjectAddress)

    ' Initialise systems
    Call PCBServer.PostProcess
End Sub


' @param     DummyVar     Dummy variable to stop function appearing in the Altium "Run Script" dialogue.
Sub DrawCoil(DummyVar)

    ' Load current board
    If PCBServer Is Nothing Then
        ShowMessage("Not a PCB or footprint editor activated.")
    End If

    Set Board = PCBServer.GetCurrentPCBBoard
    If Board Is Nothing Then
        ShowMessage("Not a PCB or footprint loaded.")
        Exit Sub
    End If

    ' Get the current PCB layer and populate field on UI
    EditDrawLayer.Text = Layer2String(Board.CurrentLayer)

    'todo List of Layers by name

    ' Display form
    FormDrawCoil.Show
End Sub

Sub ButtonDrawOnPcbClick(Sender)

     '======================================================'
     '========== RETRIEVE AND VALIDATE USER INPUT =========='
     '======================================================'

     Dim NumEdges
     NumEdges = EditNumEdges.Text
     ' Validate
     If Not IsInt(NumEdges) Then
          ShowMessage("ERROR: 'Num. Edges' input must be an integer")
          Exit Sub
     End If

     If NumEdges < 3 Then
         ShowMessage("ERROR: 'Num. Edges' input must be equal to or greater than 3.")
         Exit Sub
     End If

     Dim VertexRadiusSelected, EdgeRadiusSelected, EdgeLengthSelected

     ' Get values of radio buttons, only one of these should be checked
     VertexRadiusSelected = RadioButtonVertexRadiusMm.Checked
     EdgeRadiusSelected = RadioButtonEdgeRadiusMm.Checked
     EdgeLengthSelected = RadioButtonEdgeLengthMm.Checked

     If VertexRadiusSelected Then
        If Not IsPerfectlyNumeric(EditVertexRadiusMm.Text) Then
            ShowMessage("ERROR: 'Vertex Radius (mm)' input must be a valid number.")
            Exit Sub
        End If
        If CDbl(EditVertexRadiusMm.Text) <= 0 Then
            ShowMessage("ERROR: 'Vertex Radius (mm)' input must be greater than 0.")
            Exit Sub
        End If
     ElseIf EdgeRadiusSelected Then
        If Not IsPerfectlyNumeric(EditEdgeRadiusMm.Text) Then
            ShowMessage("ERROR: 'Edge Radius (mm)' input must be a valid number.")
            Exit Sub
        End If
        If CDbl(EditEdgeRadiusMm.Text) <= 0 Then
            ShowMessage("ERROR: 'Edge Radius (mm)' input must be greater than 0.")
            Exit Sub
        End If
     ElseIf EdgeLengthSelected Then
        If Not IsPerfectlyNumeric(EditEdgeLengthMm.Text) Then
            ShowMessage("ERROR: 'Edge Length (mm)' input must be a valid number.")
            Exit Sub
        End If
        If CDbl(EditEdgeLengthMm.Text) <= 0 Then
            ShowMessage("ERROR: 'Edge Length (mm)' input must be greater than 0.")
            Exit Sub
        End If
     End If

     ' Rotation
     If Not IsPerfectlyNumeric(EditRotationDeg.Text) Then
         ShowMessage("ERROR: 'Rotation' input must be a valid number.")
         Exit Sub
     End If
     Dim RotationDeg
     RotationDeg = StrToFloat(EditRotationDeg.Text)

     ' Line thickness
     ' check locale
     EditLineThicknessMm.Text = LocalizeNumberStr(EditLineThicknessMm.Text)
     If Not IsPerfectlyNumeric(EditLineThicknessMm.Text) Then
         ShowMessage("ERROR: 'Line Thickness (mm)' input must be a valid number.")
         Exit Sub
     End If
     Dim LineThicknessMm
     LineThicknessMm = StrToFloat(EditLineThicknessMm.Text)
     If LineThicknessMm < 0 Then
         ShowMessage("ERROR: 'Line Thickness (mm)' input must be greater than 0.")
         Exit Sub
     End If

     Dim Layer
     ' Convert the string to a valid Altium layer
     Layer = String2Layer(EditDrawLayer.Text)
     If Layer = 0 Then
          ' Show error msg, close "DrawCoil" form and exit
          ShowMessage("ERROR: '" + EditDrawLayer.Text + "' in 'Draw Layer' box is not a valid layer!")
          'FormDrawCoil.Close
          Exit Sub
     End If
     'ShowMessage("Layer = " + CStr(Layer))

     ' Get the Pi constant, note that VB script has no built-in constant
     ' so this is one of the best ways to do it.
     Dim Pi
     Pi = 4 * Atn(1)

     ' Get user to choose where the centre of the hexeagon is going to go
     Dim xm, ym
     Call Board.ChooseLocation(xm, ym, "Select the centre of the coil")

     ' Initialise systems
     Call PCBServer.PreProcess

     ' Calculate the sector angle. This is the angle a single sector of the coil encompasses, as
     ' measured around the origin of the coil.
     Dim SectorAngle
     SectorAngle = 360.0/NumEdges

     ' Get first points, this depends on the method choosen to define the
     ' coil's size
     Dim VertexRadiusMm, EdgeRadiusMm, EdgeLengthMm
     Dim x1, y1, x2, y2
     If VertexRadiusSelected Then
        VertexRadiusMm = CDbl(EditVertexRadiusMm.Text)
        x1 = -VertexRadiusMm * sin((SectorAngle/2)*Pi/180)
        y1 = VertexRadiusMm * cos((SectorAngle/2)*Pi/180)

        x2 = VertexRadiusMm * sin((SectorAngle/2)*Pi/180)
        y2 = VertexRadiusMm * cos((SectorAngle/2)*Pi/180)
     ElseIf EdgeRadiusSelected Then
        EdgeRadiusMm = CDbl(EditEdgeRadiusMm.Text)
        x1 = -EdgeRadiusMm * tan((SectorAngle/2)*Pi/180)
        y1 = EdgeRadiusMm

        x2 = EdgeRadiusMm * tan((SectorAngle/2)*Pi/180)
        y2 = EdgeRadiusMm
     ElseIf EdgeLengthSelected Then
        EdgeLengthMm = CDbl(EditEdgeLengthMm.Text)
        x1 = -EdgeLengthMm/2
        y1 = EdgeLengthMm/(2*tan((SectorAngle/2)*Pi/180))

        x2 = EdgeLengthMm/2
        y2 = EdgeLengthMm/(2*tan((SectorAngle/2)*Pi/180))
     End If

     ' Perform initial rotation as user specified
     Dim newX1, newY1, newX2, newY2
     newX1 = x1*cos(RotationDeg*Pi/180) + y1*sin(RotationDeg*Pi/180)
     newY1 = -x1*sin(RotationDeg*Pi/180) + y1*cos(RotationDeg*Pi/180)

     newX2 = x2*cos(RotationDeg*Pi/180) + y2*sin(RotationDeg*Pi/180)
     newY2 = -x2*sin(RotationDeg*Pi/180) + y2*cos(RotationDeg*Pi/180)

     x1 = newX1
     y1 = newY1
     x2 = newX2
     y2 = newY2


     Call DrawCoilByCoordinates(xm, ym, LineThicknessMm, Layer)
     ' Create each track seperately
'     Dim Index
'     For Index = 0 To (NumEdges - 1)
'
'          ' Create a new via object
'          Dim Track
'          Track = PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default)
'
'          'ShowMessage("x1 = " + CStr(x1) + ", y1 = " + CStr(y1))
'
'          ' Place track in correct position
'          Track.x1 = xm + MMsToCoord(x1)
'          Track.y1 = ym + MMsToCoord(y1)
'
'          Track.x2 = xm + MMsToCoord(x2)
'          Track.y2 = ym + MMsToCoord(y2)
'
'          Track.Width = MMsToCoord(LineThicknessMm)
'          Track.Layer = Layer
'
'          ' Add track to PCB
'          Board.AddPCBObject(Track)
'
'          ' Rotate points for next iteration of loop
'          newX1 = x1*cos(SectorAngle*Pi/180) + y1*sin(SectorAngle*Pi/180)
'          newY1 = -x1*sin(SectorAngle*Pi/180) + y1*cos(SectorAngle*Pi/180)
'
'          newX2 = x2*cos(SectorAngle*Pi/180) + y2*sin(SectorAngle*Pi/180)
'          newY2 = -x2*sin(SectorAngle*Pi/180) + y2*cos(SectorAngle*Pi/180)
'
'          x1 = newX1
'          y1 = newY1
'          x2 = newX2
'          y2 = newY2
'
'    Next

    dim minDiam
    minDiam = 10
    dim maxDiam
    maxDiam = 20
    dim coil_turns
    coil_turns = 7
    dim rotation
    rotation = 0
    dim radius_step
    radius_step = (maxDiam  - minDiam) / 2 / coil_turns

    ' Create coil turns
    Dim idx
    For idx = 0 To (coil_turns - 1)
        Dim arc
        arc = PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default)
        arc.XCenter = xm '+ MMsToCoord(x1)
        arc.YCenter = ym '+ MMsToCoord(y1)
        arc.Radius = MMsToCoord(minDiam) / 2 + idx * MMsToCoord(radius_step)
        arc.StartAngle = 0 '+ rotation
        arc.EndAngle = 270 '+ rotation
        arc.LineWidth = MMsToCoord(LineThicknessMm)
        arc.Layer = Layer
        Board.AddPCBObject(arc)
        'showmessage "arc.Radius " + cstr(arc.Radius)

        dim track
        track = PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default)
        track.x1 = arc.XCenter + arc.Radius '* cos(arc.EndAngle)
        track.y1 = arc.YCenter + arc.Radius '* sin(arc.EndAngle)
        track.x2 = track.x1 + arc.Radius '* cos(rotation) '* 0.8
        track.y2 = track.y1 + arc.Radius '* sin(rotation) '* 0.8
        track.Width = MMsToCoord(LineThicknessMm)
        track.Layer = Layer
        Board.AddPCBObject(track)

        'dim prev_track
        'prev_track = track
        'track = PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default)
        'track.x1 = prev_track.x2
        'track.y1 = prev_track.y2
        'track.x2 = track.x1 + arc.Radius * cos(rotation+45) * 1.4
        'track.y2 = track.y1 + arc.Radius * sin(rotation+45) * 1.4
        'track.Width = MMsToCoord(LineThicknessMm)
        'track.Layer = Layer
        'Board.AddPCBObject(track)
    Next




    ' Refresh the PCB screen
    Call Client.SendMessage("PCB:Zoom", "Action=Redraw" , 255, Client.CurrentView)

    ' Update the undo System in DXP that a new vIa object has been added to the board
    'Call PCBServer.SendMessageToRobots(Board.I_ObjectAddress, c_Broadcast, PCBM_BoardRegisteration, arc.I_ObjectAddress)
    Call PCBServer.SendMessageToRobots(Board.I_ObjectAddress, c_Broadcast, PCBM_BoardRegisteration, Track.I_ObjectAddress)

    ' Initialise systems
    Call PCBServer.PostProcess

    ' Close "DrawHexagon" form
    FormDrawCoil.Close

End Sub


'
'
'
Function DrawCoilByCoordinates( xm, ym, LineThicknessMm, Layer )
    dim minDiam
    minDiam = 2
    dim maxDiam
    maxDiam = 20
    dim coil_turns
    coil_turns = 7
    dim rotation
    rotation = 30
    dim radius_step
    radius_step = (maxDiam  - minDiam) / 2 / coil_turns

    ' Create coil turns
    Dim idx, last
    For idx = 0 To (coil_turns - 1)
        Dim arc
        arc = PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default)
        arc.XCenter = xm '+ MMsToCoord(x1)
        arc.YCenter = ym '+ MMsToCoord(y1)
        arc.Radius = MMsToCoord(minDiam) / 2 + idx * MMsToCoord(radius_step)
        arc.StartAngle = 0 + rotation
        arc.EndAngle = 250 + rotation
        arc.LineWidth = MMsToCoord(LineThicknessMm)
        arc.Layer = Layer
        Board.AddPCBObject(arc)
		' Update the undo System in DXP that a new vIa object has been added to the board
    	Call PCBServer.SendMessageToRobots(PCBServer.GetCurrentPCBBoard.I_ObjectAddress, _
        		c_Broadcast, PCBM_BoardRegisteration, arc.I_ObjectAddress)

        dim track
        track = PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default)
        'track.x1 = arc.XCenter + arc.Radius * sin(degree2rad(arc.EndAngle))
        'track.y1 = arc.YCenter + arc.Radius * cos(degree2rad(arc.EndAngle))
        'track.x1 = arc.XCenter + arc.Radius * cos(degree2rad(arc.EndAngle+270))
        'track.y1 = arc.YCenter + arc.Radius * sin(degree2rad(arc.EndAngle+270))
        track.x1 = arc.XCenter + arc.Radius * cos(degree2rad(arc.EndAngle))
        track.y1 = arc.YCenter + arc.Radius * sin(degree2rad(arc.EndAngle))
        track.x2 = track.x1 + arc.Radius * cos(degree2rad(rotation)) '* 0.8
        track.y2 = track.y1 + arc.Radius * sin(degree2rad(rotation)) '* 0.8
        track.Width = MMsToCoord(LineThicknessMm)
        track.Layer = Layer
        Board.AddPCBObject(track)
		Call PCBServer.SendMessageToRobots(PCBServer.GetCurrentPCBBoard.I_ObjectAddress, _
        		c_Broadcast, PCBM_BoardRegisteration, track.I_ObjectAddress)

        dim prev_track
        prev_track = track
        track = PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default)
        track.x1 = prev_track.x2
        track.y1 = prev_track.y2
        track.x2 = arc.XCenter + (arc.Radius + MMsToCoord(radius_step)) * cos(degree2rad(arc.StartAngle))'track.x1 + arc.Radius * cos(degree2rad(rotation+45) * 1.4
        track.y2 = arc.YCenter + (arc.Radius + MMsToCoord(radius_step)) * sin(degree2rad(arc.StartAngle))'track.y1 + arc.Radius * sin(degree2rad(rotation+45) * 1.4
        track.Width = MMsToCoord(LineThicknessMm)
        track.Layer = Layer
        Board.AddPCBObject(track)
		Call PCBServer.SendMessageToRobots(PCBServer.GetCurrentPCBBoard.I_ObjectAddress, _
        		c_Broadcast, PCBM_BoardRegisteration, track.I_ObjectAddress)

        last = track
    Next

    DrawCoilByCoordinates = last

End Function


'
'
Function degree2rad(degree)
     ' Get the Pi constant, note that VB script has no built-in constant
     ' so this is one of the best ways to do it.
     Dim Pi
     Pi = 4 * Atn(1)

     degree2rad = (degree*Pi/180)
End Function


Sub ButtonCancelClick(Sender)
    FormDrawCoil.Close
End Sub
