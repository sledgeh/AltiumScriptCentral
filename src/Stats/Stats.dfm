object FormStats: TFormStats
  Left = 0
  Top = 0
  Caption = 'PCB Stats'
  ClientHeight = 512
  ClientWidth = 579
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label2: TLabel
    Left = 26
    Top = 129
    Width = 76
    Height = 13
    Caption = 'Number of Vias:'
  end
  object LabelNumOfVias: TLabel
    Left = 154
    Top = 129
    Width = 6
    Height = 13
    Caption = '0'
  end
  object Label1: TLabel
    Left = 26
    Top = 145
    Width = 122
    Height = 13
    Caption = 'Num. of Pads With Holes:'
  end
  object LabelNumOfPadsWithHoles: TLabel
    Left = 154
    Top = 145
    Width = 6
    Height = 13
    Caption = '0'
  end
  object Label3: TLabel
    Left = 26
    Top = 169
    Width = 111
    Height = 13
    Caption = 'Total num. of Holes:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LabelTotalNumOfHoles: TLabel
    Left = 154
    Top = 169
    Width = 7
    Height = 13
    Caption = '0'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
end