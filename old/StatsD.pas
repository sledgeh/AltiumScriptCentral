//
// @file               StatsD.pas
// @author             Geoffrey Hunter <gbmhunter@gmail.com> (www.mbedded.ninja)
// @created            2014-11-03
// @last-modified      2014-11-26
// @brief              Code for showing PCB statistics.
// @details
//                     See README.rst in repo root dir for more info.

function CountVias(board : IPCB_Board) : Integer;
var
   count : Integer;
   iterator: IPCB_BoardIterator;
   compDes;
begin

    iterator := board.BoardIterator_Create;
    iterator.AddFilter_ObjectSet(MkSet(eViaObject));
    iterator.AddFilter_LayerSet(AllLayers);
    iterator.AddFilter_Method(eProcessAll);

    compDes := iterator.FirstPCBObject;

    count := 0;

    // Iterate through all objects
    While CompDes <> Nil Do
    Begin
        Inc(count);

        CompDes := Iterator.NextPCBObject;
    End;

    board.BoardIterator_Destroy(Iterator);

    //LabelNumOfVias.Caption = count
    Result := count;

end;

function CountNumPadsWithHoles(board : IPCB_Board) : Integer;
var
   iterator : IPCB_BoardIterator;
   padObj : IPCB_Primitive;
   count : Integer;
begin

    iterator := Board.BoardIterator_Create;
    iterator.AddFilter_ObjectSet(MkSet(ePadObject));
    iterator.AddFilter_LayerSet(AllLayers);
    iterator.AddFilter_Method(eProcessAll);

    padObj := iterator.FirstPCBObject;

    count := 0;

    // Iterate through all pads
    while padObj <> Nil do
    begin
       // Note that unlike vias, not all pads will have holes in them, we have to find this out now...
       if padObj.HoleSize > 0 then
       begin
          // We have found a pad with a hole in it!
          Inc(Count);
       end;

       if padObj.Plated = True Then
       begin
            //ShowMessage('Pad is plated!');
       end;

       padObj := iterator.NextPCBObject;
    end;

    board.BoardIterator_Destroy(Iterator);

    Result := count;

end;

function CountNumDiffHoleSizes(board : IPCB_Board) : Integer;
var
   //holeSizeList : System.Collections.ArrayList;
   holeSizeList : Tlist;
   iterator : IPCB_Iterator;
   viaPad : IPCB_Primitive;
begin

   // Create an ArrayList to store the unique hole sizes present on the PCB
   //holeSizeList := CreateObject('System.Collections.ArrayList');
   holeSizeList := TList.Create;

   // Create an iterator to iterate over all vias and pads on the PCBs
   iterator := board.BoardIterator_Create;
   iterator.AddFilter_ObjectSet(MkSet(eViaObject, ePadObject));
   iterator.AddFilter_LayerSet(AllLayers);
   iterator.AddFilter_Method(eProcessAll);

   viaPad := iterator.FirstPCBObject;
          TList.
   // Iterate through all objects
   while viaPad <> Nil do
   begin
      // Check that hole size is not 0 (i.e. no hole) and hole is not already in list
      if (viaPad.HoleSize <> 0) And (holeSizeList(viaPad.HoleSize) = False) Then
      begin
         // Hole size was not found in the list, and was greater than 0mm, so lets
         // add it to our list of unique hole sizes
         holeSizeList.Add(viaPad.HoleSize);
      end;

      viaPad := Iterator.NextPCBObject;
   end;

   board.BoardIterator_Destroy(Iterator);

   // Return the number of different hole sizes
   Result := holeSizeList.Count;

end;

procedure TFormStatsD.FormStatsDShow(Sender: TObject);
var
   board : IPCB_Board;
begin

    //ShowMessage('Displaying PCB stats...');

    // Get the current PCB board, which we will pass to all
    // the child functions

    board := PCBServer.GetCurrentPCBBoard;
    If board = Nil Then
    begin
        ShowMessage('Could not find a PCB board, please make sure PCB file you want to use it currently open.');
        Exit;
    end;

    // Count the number of holes on PCB
    LabelNumOfVias.Caption := CountVias(board);

    LabelNumOfPadsWithHoles.Caption := CountNumPadsWithHoles(board);
    LabelTotalNumOfHoles.Caption := StrToInt(LabelNumOfVias.Caption) + StrToInt(LabelNumOfPadsWithHoles.Caption);

    // Get the number of different hole sizes
    LabelNumDiffHoleSizes.Caption := CountNumDiffHoleSizes(board);
      {
    // Minimum widths
    LabelMinAnnularRingMm.Caption = CStr(FindMinAnnularRingMm(board))
    LabelMinTrackWidthMm.Caption = CStr(FindMinTrackWidthMm(board))

    ' Number copper layers on PCB
    LabelNumCopperLayers.Caption = CountNumCopperLayers(board)

    ' Get board height and width
    dimensions = GetPcbBoundingRectangleDimensions(board)
    LabelBoardWidthMm.Caption = dimensions(0)
    LabelBoardHeightMm.Caption = dimensions(1)
    LabelBoardAreaMm.Caption = dimensions(2)

    ' Now that everything has been calculated, show the form, in non-modal fashion
    'FormStats.Show

    'StdOut("Finished displaying PCB stats." + VbCr + VbLf)
    }
end;




{

Function FindMinAnnularRingMm(board)

    minAnnularRingMm = 0
    firstTime = True

    '===== CHECK VIAS ====='

    Set iterator = board.BoardIterator_Create
    iterator.AddFilter_ObjectSet(MkSet(eViaObject))
    iterator.AddFilter_LayerSet(AllLayers)
    iterator.AddFilter_Method(eProcessAll)

    Set via = iterator.FirstPCBObject

    ' Iterate through all objects
    Do While Not (via Is Nothing)
        annularRingMm =  CoordToMMs((via.Size - via.HoleSize)/2)

        If firstTime = True Then
           ' First time through we don't care if it's higher/lower
           ' than anything else
           minAnnularRingMm = annularRingMm
           firstTime = False
        Else
            If annularRingMm < minAnnularRingMm Then
               minAnnularRingMm = annularRingMm
            End If
        End If

        Set via = Iterator.NextPCBObject
    Loop

    board.BoardIterator_Destroy(Iterator)

    '===== CHECK PADS ====='

    Set iterator = board.BoardIterator_Create
    iterator.AddFilter_ObjectSet(MkSet(ePadObject))
    iterator.AddFilter_LayerSet(AllLayers)
    iterator.AddFilter_Method(eProcessAll)

    Dim pad
    Set pad = iterator.FirstPCBObject

    ' Iterate through all pads
    Do While Not (pad Is Nothing)
       ' Check annular ring in X direction
       annularRingXMm =  CoordToMMs((pad.X - pad.HoleSize)/2)

       If annularRingXMm < minAnnularRingMm Then
          minAnnularRingMm = annularRingXMm
       End If

       ' Check annular ring in Y direction
       annularRingYMm =  CoordToMMs((pad.Y - pad.HoleSize)/2)

       If annularRingYMm < minAnnularRingMm Then
          minAnnularRingMm = annularRingYMm
       End If

       Set pad = Iterator.NextPCBObject
    Loop

    board.BoardIterator_Destroy(Iterator)

    FindMinAnnularRingMm = minAnnularRingMm

End Function

Function FindMinTrackWidthMm(board)

    Set iterator = board.BoardIterator_Create
    iterator.AddFilter_ObjectSet(MkSet(eTrackObject))
    ' We only want to check copper layers for tracks
    iterator.AddFilter_LayerSet(MkSet(eTopLayer, eMidLayer1, eMidLayer2, eMidLayer3, eMidLayer4, eMidLayer5, eMidLayer6, eMidLayer7, eMidLayer8, eMidLayer9, eMidLayer10, eMidLayer11, eMidLayer12, eMidLayer13, eMidLayer14, eMidLayer15, eMidLayer16, eMidLayer17, eMidLayer18, eMidLayer19, eMidLayer20, eMidLayer21, eMidLayer22, eMidLayer23, eMidLayer24, eMidLayer25, eMidLayer26, eMidLayer27, eMidLayer28, eMidLayer29, eMidLayer30, eBottomLayer))
    iterator.AddFilter_Method(eProcessAll)

    Set track = iterator.FirstPCBObject

    minTrackWidthMm = 0
    firstTime = True

    ' Iterate through all objects
    Do While Not (track Is Nothing)
        trackWidthMm =  CoordToMMs(track.Width)

        'StdOut("Track width (mm) = " + CStr(trackWidthMm) + VbCr + VbLf)

        If firstTime = True Then
           ' First time through we don't care if it's higher/lower
           ' than anything else
           minTrackWidthMm = trackWidthMm
           firstTime = False
        Else
            If trackWidthMm < minTrackWidthMm Then
               minTrackWidthMm = trackWidthMm
            End If
        End If

        Set track = Iterator.NextPCBObject
    Loop

    board.BoardIterator_Destroy(Iterator)

    FindMinTrackWidthMm = minTrackWidthMm

End Function


Function CountNumCopperLayers(board)

  layerClass = eLayerClass_Electrical

  layerStack = board.LayerStack

  If layerStack Is Nothing Then
     Exit Function
  End If

  ' Get first layer of the class type.
  layerObj = layerStack.First(layerClass)

  ' Exit if layer type is not available in stack
  If layerObj Is Nothing Then
     Exit Function
  End If

  numCopperLayers = 1

  ' Iterate through layers and display each layer name
  Do
    'ShowMessage(layerObj.Name)
    layerObj = layerStack.Next(layerClass, layerObj)
    numCopperLayers = numCopperLayers + 1

    ' For some reason we cannot compare the layer objects directly,
    ' so as a workaround I will compare the names. This will be buggy
    ' if there are two layers with the same name (and one of them is the
    ' last layer)
  Loop Until layerObj.Name = layerStack.Last(layerClass).Name

  CountNumCopperLayers = numCopperLayers

End Function

Function GetPcbBoundingRectangleDimensions(board)

   Dim dimensions(3)

   boundingRectangle = board.BoardOutline.BoundingRectangle

   'StdOut("br.Width = " + CStr(CoordToMMs(board.BoardOutline.BoundingRectangle.Right - board.BoardOutline.BoundingRectangle.Left)) + VbCr + VbLf)
   'StdOut("br.Bottom = " + CStr(CoordToMMs(board.BoardOutline.BoundingRectangle.Top - board.BoardOutline.BoundingRectangle.Bottom)) + VbCr + VbLf)

   dimensions(0) = CoordToMMs(board.BoardOutline.BoundingRectangle.Right - board.BoardOutline.BoundingRectangle.Left)
   dimensions(1) = CoordToMMs(board.BoardOutline.BoundingRectangle.Top - board.BoardOutline.BoundingRectangle.Bottom)
   dimensions(2) = CStr(Round(dimensions(0)*dimensions(1), 0))

   GetPcbBoundingRectangleDimensions = dimensions

End Function



Sub FormStatsActivate(Sender)
ShowMessage("Form activated")
End Sub

Sub FormStatsCreate(Sender)
       ShowMessage("From created")
End Sub

Sub FormStatsContextPopup(Sender, MousePos, Handled)
       ShowMessage("Form stats")
End Sub

Sub FormStatsPaint(Sender)
     ShowMessage("Form painted")
End Sub

                       }

