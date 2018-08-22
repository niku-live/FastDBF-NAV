codeunit 50112 Lib_DbfColumn
{
    // /// <summary>
    // /// This class represents a DBF Column.
    // /// </summary>
    // ///
    // /// <remarks>
    // /// Note that certain properties can not be modified after creation of the object.
    // /// This is because we are locking the header object after creation of a data row,
    // /// and columns are part of the header so either we have to have a lock field for each column,
    // /// or make it so that certain properties such as length can only be set during creation of a column.
    // /// Otherwise a user of this object could modify a column that belongs to a locked header and thus corrupt the DBF file.
    // /// </remarks>


    trigger OnRun();
    begin
    end;

    var
        _name : Text;
        _type : Integer;
        _dataAddress : Integer;
        _length : Integer;
        _decimalCount : Integer;
        DbfColumnType : Codeunit Lib_DbfColumnType;

    local procedure InitValues();
    begin
        /// <summary>
        /// Column (field) name
        /// </summary>
        CLEAR(_name);


        /// <summary>
        /// Field Type (Char, number, boolean, date, memo, binary)
        /// </summary>
        CLEAR(_type);


        /// <summary>
        /// Offset from the start of the record
        /// </summary>
        CLEAR(_dataAddress);


        /// <summary>
        /// Length of the data in bytes; some rules apply which are in the spec (read more above).
        /// </summary>
        CLEAR(_length);


        /// <summary>
        /// Decimal precision count, or number of digits afer decimal point. This applies to Number types only.
        /// </summary>
        CLEAR(_decimalCount);
    end;

    [Scope('Personalization')]
    procedure DbfColumn(sName : Code[11];type : Integer;nLength : Integer;nDecimals : Integer);
    begin
        /// <summary>
        /// Full spec constructor sets all relevant fields.
        /// </summary>
        /// <param name="sName"></param>
        /// <param name="type"></param>
        /// <param name="nLength"></param>
        /// <param name="nDecimals"></param>
        InitValues;
        SetName(sName);
        _type := type;
        _length := nLength;

        IF (type = DbfColumnType.Number) OR (type = DbfColumnType.Float) THEN
          _decimalCount := nDecimals
        ELSE
          _decimalCount := 0;



        //perform some simple integrity checks...
        //-------------------------------------------

        //decimal precision:
        //we could also fix the length property with a statement like this: mLength = mDecimalCount + 2;
        IF (_decimalCount > 0) AND (_length - _decimalCount <= 1) THEN
          ERROR('Exception: Decimal precision can not be larger than the length of the field.');

        IF _type = DbfColumnType.Integer THEN
          _length := 4;

        IF _type = DbfColumnType.Binary THEN
          _length := 1;

        IF _type = DbfColumnType.Date THEN
          _length := 8;  //Dates are exactly yyyyMMdd

        IF _type = DbfColumnType.Memo THEN
          _length := 10;  //Length: 10 Pointer to ASCII text field in memo file. pointer to a DBT block.

        IF _type = DbfColumnType.Boolean THEN
          _length := 1;

        //field length:
        IF _length <= 0 THEN
          ERROR('Exception: Invalid field length specified. Field length can not be zero or less than zero.')
        ELSE IF (type <> DbfColumnType.Character) AND (type <> DbfColumnType.Binary) AND (_length > 255) THEN
          ERROR('Exception: Invalid field length specified. For numbers it should be within 20 digits, but we allow up to 255. For Char and binary types, length up to 65,535 is allowed. For maximum compatibility use up to 255.')
        ELSE IF ((type = DbfColumnType.Character) OR (type = DbfColumnType.Binary)) AND (_length > 65535) THEN
          ERROR('Exception: Invalid field length specified. For Char and binary types, length up to 65535 is supported. For maximum compatibility use up to 255.');
    end;

    [Scope('Internal')]
    procedure DbfColumnWithDataAddress(sName : Code[11];type : Integer;nLength : Integer;nDecimals : Integer;nDataAddress : Integer);
    begin
        /// <summary>
        /// Create a new column fully specifying all properties.
        /// </summary>
        /// <param name="sName"></param>
        /// <param name="type"></param>
        /// <param name="nLength"></param>
        /// <param name="nDecimals"></param>
        /// <param name="nDataAddress">offset from start of record</param>
        DbfColumn(sName, type, nLength, nDecimals);
        _dataAddress := nDataAddress;
    end;

    [Scope('Personalization')]
    procedure DbfColumnSimple(sName : Code[11];type : Integer);
    begin
        DbfColumn(sName, type, 0, 0);
        IF (type = DbfColumnType.Number) OR (type = DbfColumnType.Float) OR (type = DbfColumnType.Character) THEN
          ERROR('Exception: For number and character field types you must specify Length and Decimal Precision.');
    end;

    [Scope('Personalization')]
    procedure Name() : Text;
    begin
        /// <summary>
        /// Field Name.
        /// </summary>
        EXIT(_name);
    end;

    [Scope('Personalization')]
    procedure SetName(value : Text);
    begin
        //name:
        IF value = '' THEN
          ERROR('Exception: Field names must be at least one char long and can not be null.');

        IF STRLEN(value) > 11 THEN
          ERROR('Exception: Field names can not be longer than 11 chars.');

        _name := value;
    end;

    [Scope('Personalization')]
    procedure ColumnType() : Integer;
    begin
        /// <summary>
        /// Field Type (C N L D or M).
        /// </summary>
        EXIT(_type);
    end;

    [Scope('Personalization')]
    procedure ColumnTypeChar() : Char;
    begin
        /// <summary>
        /// Returns column type as a char, (as written in the DBF column header)
        /// N=number, C=char, B=binary, L=boolean, D=date, I=integer, M=memo
        /// </summary>
        CASE _type OF
          DbfColumnType.Number:
            EXIT('N');

          DbfColumnType.Character:
            EXIT('C');

          DbfColumnType.Binary:
            EXIT('B');

          DbfColumnType.Boolean:
            EXIT('L');

          DbfColumnType.Date:
            EXIT('D');

          DbfColumnType.Integer:
            EXIT('I');

          DbfColumnType.Memo:
            EXIT('M');

          DbfColumnType.Float:
            EXIT('F');
        ELSE

          ERROR('Exception: Unrecognized field type!');
        END;
    end;

    [Scope('Personalization')]
    procedure DataAddress() : Integer;
    begin
        /// <summary>
        /// Field Data Address offset from the start of the record.
        /// </summary>
        EXIT(_dataAddress);
    end;

    [Scope('Personalization')]
    procedure SetDataAddress(value : Integer);
    begin
        _dataAddress := value;
    end;

    [Scope('Personalization')]
    procedure Length() : Integer;
    begin
        /// <summary>
        /// Length of the data in bytes.
        /// </summary>
        EXIT(_length);
    end;

    [Scope('Personalization')]
    procedure DecimalCount() : Integer;
    begin
        /// <summary>
        /// Field decimal count in Binary, indicating where the decimal is.
        /// </summary>
        EXIT(_decimalCount);
    end;

    [Scope('Personalization')]
    procedure GetDbaseTypeFromVariant(type : Variant) : Integer;
    begin
        /// <summary>
        /// Returns corresponding dbf field type given a variant.
        /// </summary>
        /// <param name="type"></param>
        /// <returns></returns>
        IF type.ISTEXT THEN
          EXIT(DbfColumnType.Character)
        ELSE IF type.ISDECIMAL THEN
          EXIT(DbfColumnType.Number)
        ELSE IF type.ISBOOLEAN THEN
          EXIT(DbfColumnType.Boolean)
        ELSE IF type.ISDATE OR type.ISDATETIME OR type.ISTIME THEN
          EXIT(DbfColumnType.Date);

        ERROR('NotSupportedException: ' + STRSUBSTNO('%1 does not have a corresponding dbase type.', FORMAT(type)));
    end;

    [Scope('Personalization')]
    procedure GetDbaseTypeFromChar(c : Char) : Integer;
    begin
        CASE UPPERCASE(FORMAT(c)) OF
          'C': EXIT(DbfColumnType.Character);
          'N': EXIT(DbfColumnType.Number);
          'B': EXIT(DbfColumnType.Binary);
          'L': EXIT(DbfColumnType.Boolean);
          'D': EXIT(DbfColumnType.Date);
          'I': EXIT(DbfColumnType.Integer);
          'M': EXIT(DbfColumnType.Memo);
          'F': EXIT(DbfColumnType.Float);
        ELSE
          ERROR('NotSupportedException: ' + STRSUBSTNO('%1 does not have a corresponding dbase type.', c));
        END;
    end;

    [Scope('Personalization')]
    procedure ShapeField(var NewField : Codeunit Lib_DbfColumn);
    begin
        /// <summary>
        /// Returns shp file Shape Field.
        /// </summary>
        /// <returns></returns>
        NewField.DbfColumnSimple('Geometry', DbfColumnType.Binary);
    end;

    [Scope('Personalization')]
    procedure IdField(var NewField : Codeunit Lib_DbfColumn);
    begin
        /// <summary>
        /// Returns Shp file ID field.
        /// </summary>
        /// <returns></returns>
        NewField.DbfColumnSimple('Row', DbfColumnType.Integer);
    end;
}

