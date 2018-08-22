codeunit 50116 Lib_DbfColumnNameDictionary
{

    trigger OnRun();
    begin
    end;

    var
        Dictionary : Codeunit Lib_Dictionary;

    procedure Create("Count" : Integer);
    begin
        Dictionary.CreateDictionary;
    end;

    procedure Length() : Integer;
    begin
        EXIT(Dictionary.Count);
    end;

    procedure "Count"() : Integer;
    begin
        EXIT(Dictionary.Count);
    end;

    procedure Add("Key" : Text;Value : Integer);
    var
        "Object" : Variant;
    begin
        Object := Value;
        Dictionary.Add(Key, Object);
    end;

    procedure TryGetValue("Key" : Text;var Value : Integer) : Boolean;
    var
        "Object" : Variant;
    begin
        IF NOT Dictionary.TryGetValue(Key, Object) THEN
          EXIT(FALSE);
        Value := Object;
        EXIT(TRUE);
    end;

    procedure RemoveAt(Index : Integer);
    begin
        Dictionary.RemoveAt(Index);
    end;

    procedure IsNull() : Boolean;
    begin
        EXIT(Dictionary.IsNull);
    end;

    procedure ContainsKey("Key" : Text) : Boolean;
    begin
        EXIT(Dictionary.ContainsKey(Key));
    end;

    procedure Item("Key" : Text) : Integer;
    var
        "Object" : Variant;
    begin
        Dictionary.Item(Key, Object);
        EXIT(Object);
    end;
}

