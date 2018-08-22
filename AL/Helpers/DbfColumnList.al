codeunit 50114 Lib_DbfColumnList
{

    trigger OnRun();
    begin
    end;

    var
        List : Codeunit Lib_LinkedList;

    procedure Create(FieldCount : Integer);
    begin
        CLEAR(List);
    end;

    procedure Length() : Integer;
    begin
        EXIT(List.Count);
    end;

    procedure "Count"() : Integer;
    begin
        EXIT(List.Count);
    end;

    procedure Add(var DotNet_DbfColumn : Codeunit Lib_DbfColumn);
    var
        "Object" : Variant;
    begin
        Object := DotNet_DbfColumn;
        List.AddLast(Object);
    end;

    procedure Get(Index : Integer;var DotNet_DbfColumn : Codeunit Lib_DbfColumn);
    var
        "Object" : Variant;
    begin
        List.ValueAt(Index, Object);
        DotNet_DbfColumn := Object;
    end;

    procedure RemoveAt(Index : Integer);
    begin
        List.RemoveAt(Index);
    end;
}

