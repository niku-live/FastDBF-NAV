codeunit 50201 Lib_LinkedList
{

    trigger OnRun();
    begin
    end;

    var
        Head : Codeunit Lib_CollectionNode;
        Tail : Codeunit Lib_CollectionNode;
        NodeCount : Integer;
        IsCreated : Boolean;

    [Scope('Personalization')]
    procedure CreateList();
    begin
        CLEAR(Head);
        CLEAR(Tail);
        NodeCount := 0;
        IsCreated := TRUE;
    end;

    [Scope('Personalization')]
    procedure AddLast(var Value : Variant);
    var
        NewNode : Codeunit Lib_CollectionNode;
    begin
        NewNode.SetValue(Value);
        NewNode.SetPrevious(Tail);
        Tail := NewNode;
        IF NodeCount = 0 THEN
          Head := NewNode;
        NodeCount += 1;
    end;

    [Scope('Personalization')]
    procedure AddFirst(var Value : Variant);
    var
        NewNode : Codeunit Lib_CollectionNode;
    begin
        NewNode.SetValue(Value);
        NewNode.SetNext(Head);
        Head := NewNode;
        IF NodeCount = 0 THEN
          Tail := NewNode;
        NodeCount += 1;
    end;

    [Scope('Personalization')]
    procedure InsertAt(Index : Integer;var Value : Variant);
    var
        Node : Codeunit Lib_CollectionNode;
        NewNode : Codeunit Lib_CollectionNode;
        PrevNode : Codeunit Lib_CollectionNode;
    begin
        IF (Index = 0) OR (Count = 0) THEN
          AddFirst(Value)
        ELSE IF Index >= Count THEN
          AddLast(Value)
        ELSE
          BEGIN
            NodeAt(Index, Node);
            Node.Previous(PrevNode);
            NewNode.SetValue(Value);
            NewNode.SetNext(Node);
            Node.SetPrevious(NewNode);
            NewNode.SetPrevious(PrevNode);
            NodeCount += 1;
          END;
    end;

    local procedure NodeAt(Index : Integer;var Node : Codeunit Lib_CollectionNode);
    var
        CurIndex : Integer;
    begin
        IF Index < 0 THEN
          ERROR('Ar');

        IF Index >= NodeCount THEN
          ERROR('');

        Node := Head;
        FOR CurIndex := 0 TO Index - 1 DO
          Node.Next(Node);
    end;

    [Scope('Personalization')]
    procedure ValueAt(Index : Integer;var NodeValue : Variant);
    var
        Node : Codeunit Lib_CollectionNode;
    begin
        NodeAt(Index, Node);
        Node.Value(NodeValue);
    end;

    [Scope('Personalization')]
    procedure RemoveLast();
    var
        Node : Codeunit Lib_CollectionNode;
    begin
        IF NodeCount = 0 THEN
          ERROR('');

        IF NodeCount = 1 THEN
          BEGIN
            CreateList;
            EXIT;
          END;

        IF NodeCount = 2 THEN
          BEGIN
            CLEAR(Tail);
            Head.SetNext(Tail);
            Tail := Head;
            NodeCount := 1;
            EXIT;
          END;

        Tail.Previous(Node);
        CLEAR(Tail);
        Node.SetNext(Tail);
        Tail := Node;
        NodeCount -= 1;
    end;

    [Scope('Personalization')]
    procedure RemoveFirst();
    var
        Node : Codeunit Lib_CollectionNode;
    begin
        IF NodeCount = 0 THEN
          ERROR('');

        IF NodeCount = 1 THEN
          BEGIN
            CreateList;
            EXIT;
          END;

        IF NodeCount = 2 THEN
          BEGIN
            CLEAR(Head);
            Tail.SetPrevious(Head);
            Head := Tail;
            NodeCount := 1;
            EXIT;
          END;

        Head.Next(Node);
        CLEAR(Head);
        Node.SetPrevious(Head);
        Head := Node;
        NodeCount -= 1;
    end;

    [Scope('Personalization')]
    procedure RemoveAt(Index : Integer);
    var
        Node : Codeunit Lib_CollectionNode;
        NextNode : Codeunit Lib_CollectionNode;
        PrevNode : Codeunit Lib_CollectionNode;
    begin
        IF (Index = 0) OR (NodeCount < 2) THEN
          RemoveFirst
        ELSE IF (Index = NodeCount - 1) THEN
          RemoveLast
        ELSE
          BEGIN
            NodeAt(Index, Node);
            Node.Previous(PrevNode);
            Node.Next(NextNode);
            CLEAR(Node);
            NextNode.SetPrevious(PrevNode);
            PrevNode.SetNext(NextNode);
            NodeCount -= 1;
          END;
    end;

    [Scope('Personalization')]
    procedure "Count"() : Integer;
    begin
        EXIT(NodeCount);
    end;

    [Scope('Personalization')]
    procedure Dispose();
    begin
        CLEARALL;
    end;

    [Scope('Personalization')]
    procedure IsNull() : Boolean;
    begin
        EXIT(NOT IsCreated);
    end;

    [Scope('Personalization')]
    procedure GetEnumerator(var Enumerator : Codeunit Lib_LinkedListEnumerator);
    begin
        Enumerator.Init(Head);
    end;
}

