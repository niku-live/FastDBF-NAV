codeunit 50203 Lib_LinkedListEnumerator
{

    trigger OnRun();
    begin
    end;

    var
        Head : Codeunit Lib_CollectionNode;
        Node : Codeunit Lib_CollectionNode;
        Started : Boolean;

    [Scope('Internal')]
    procedure Init(var ListHead : Codeunit Lib_CollectionNode);
    begin
        Head := ListHead;
        Reset;
    end;

    [Scope('Personalization')]
    procedure Reset();
    begin
        Started := FALSE;
        Node := Head;
    end;

    [Scope('Personalization')]
    procedure MoveNext() : Boolean;
    begin
        IF NOT Started THEN
          Node := Head
        ELSE
          Node.Next(Node);

        Started := TRUE;
        EXIT(NOT Node.IsNull);
    end;

    [Scope('Personalization')]
    procedure Current(var Value : Variant);
    begin
        Node.Value(Value);
    end;
}

