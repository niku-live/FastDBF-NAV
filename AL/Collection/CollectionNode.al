codeunit 50200 Lib_CollectionNode
{

    trigger OnRun();
    begin
    end;

    var
        NodeValue : Variant;
        NextNode : Codeunit Lib_CollectionNode;
        PrevNode : Codeunit Lib_CollectionNode;
        HasValue : Boolean;

    [Scope('Internal')]
    procedure Value(var CurrentValue : Variant);
    begin
        CurrentValue := NodeValue;
    end;

    [Scope('Internal')]
    procedure SetValue(var NewValue : Variant);
    begin
        HasValue := TRUE;
        NodeValue := NewValue;
    end;

    [Scope('Internal')]
    procedure Next(var CurrentNextNode : Codeunit Lib_CollectionNode);
    begin
        CurrentNextNode := NextNode;
    end;

    [Scope('Internal')]
    procedure SetNext(var NewNextNode : Codeunit Lib_CollectionNode);
    begin
        NextNode := NewNextNode;
    end;

    [Scope('Internal')]
    procedure Previous(var CurrentPrevNode : Codeunit Lib_CollectionNode);
    begin
        CurrentPrevNode := PrevNode;
    end;

    [Scope('Internal')]
    procedure SetPrevious(var NewPrevNode : Codeunit Lib_CollectionNode);
    begin
        PrevNode := NewPrevNode;
    end;

    [Scope('Internal')]
    procedure IsNull() : Boolean;
    begin
        EXIT(NOT HasValue);
    end;
}

