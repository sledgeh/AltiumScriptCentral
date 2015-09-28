
Sub Test_IsPerfectlyNumeric
    'showmessage IsPerfectlyNumeric("1")
    'showmessage IsPerfectlyNumeric("1.2")
    'showmessage IsPerfectlyNumeric("1,2")
    'showmessage IsNumeric("1.2")
    dim unit
    showmessage String2Unit("1.2mm",unit) 'StrToMeasureUnit("1.2mm") 'UnitSufixString(25) 'UnitStrToSqrCoords_i(1,2) 'UnitToString(52.8855)
    showmessage unit
End Sub
