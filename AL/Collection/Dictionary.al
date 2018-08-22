codeunit 50202 Lib_Dictionary
{

    trigger OnRun();
    begin
    end;

    var
        IsCreated : Boolean;
        KeyList : Codeunit Lib_LinkedList;
        ValueList : Codeunit Lib_LinkedList;

    [Scope('Personalization')]
    procedure CreateDictionary();
    begin
        KeyList.CreateList;
        ValueList.CreateList;
    end;

    [Scope('Personalization')]
    procedure "Count"() : Integer;
    begin
        EXIT(KeyList.Count);
    end;

    [Scope('Personalization')]
    procedure Add("Key" : Text;var Value : Variant);
    var
        KeyVariant : Variant;
    begin
        IF ContainsKey(Key) THEN
          ERROR('');

        KeyVariant := Key;
        KeyList.AddLast(KeyVariant);
        ValueList.AddLast(Value);
    end;

    [Scope('Personalization')]
    procedure TryGetValue("Key" : Text;var Value : Variant) : Boolean;
    begin
        IF NOT ContainsKey(Key) THEN
          EXIT(FALSE);

        Item(Key, Value);
        EXIT(TRUE);
    end;

    [Scope('Personalization')]
    procedure RemoveAt(Index : Integer);
    begin
        KeyList.RemoveAt(Index);
        ValueList.RemoveAt(Index);
    end;

    [Scope('Personalization')]
    procedure IsNull() : Boolean;
    begin
        EXIT(NOT IsCreated);
    end;

    [Scope('Personalization')]
    procedure ContainsKey("Key" : Text) : Boolean;
    begin
        EXIT(KeyIndex(Key) >= 0);
    end;

    [Scope('Personalization')]
    procedure Item("Key" : Text;var Value : Variant);
    var
        Index : Integer;
    begin
        Index := KeyIndex(Key);
        IF Index < 0 THEN
          ERROR('');

        ValueList.ValueAt(Index, Value);
    end;

    [Scope('Personalization')]
    procedure "Keys"(var List : Codeunit Lib_LinkedList);
    begin
        List := KeyList;
    end;

    [Scope('Personalization')]
    procedure Values(var List : Codeunit Lib_LinkedList);
    begin
        List := ValueList;
    end;

    local procedure KeyIndex("Key" : Text) : Integer;
    var
        Enumerator : Codeunit Lib_LinkedListEnumerator;
        "Object" : Variant;
        CurrentKey : Text;
        Index : Integer;
    begin
        KeyList.GetEnumerator(Enumerator);
        Index := 0;
        WHILE Enumerator.MoveNext DO
          BEGIN
            Enumerator.Current(Object);
            CurrentKey := Object;
            IF CurrentKey = Key THEN
              EXIT(Index);
            Index += 1;
          END;
        EXIT(-1);
    end;
}

