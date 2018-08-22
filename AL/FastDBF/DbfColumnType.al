codeunit 50115 Lib_DbfColumnType
{
    // {
    //   (FoxPro/FoxBase) Double integer *NOT* a memo field
    //   G General (dBASE V: like Memo) OLE Objects in MS Windows versions
    //   P Picture (FoxPro) Like Memo fields, but not for text processing.
    //   Y Currency (FoxPro)
    //   T DateTime (FoxPro)
    //   I Integer Length: 4 byte little endian integer (FoxPro)
    // }
    // 
    // /// <summary>
    // ///  Great information on DBF located here:
    // ///  http://www.clicketyclick.dk/databases/xbase/format/data_types.html
    // ///  http://www.clicketyclick.dk/databases/xbase/format/dbf.html
    // ///
    // /// also take a look at this: http://www.dbase.com/Knowledgebase/INT/db7_file_fmt.htm
    // /// </summary>


    trigger OnRun();
    begin
    end;

    var
        NumberValue : Integer;

    [Scope('Personalization')]
    procedure Character() : Integer;
    begin
        /// <summary>
        /// C Character   All OEM code page characters - padded with blanks to the width of the field.
        /// Character  less than 254 length
        /// ASCII text less than 254 characters long in dBASE.
        ///
        /// Character fields can be up to 32 KB long (in Clipper and FoxPro) using decimal
        /// count as high byte in field length. It's possible to use up to 64KB long fields
        /// by reading length as unsigned.
        ///
        /// </summary>
        EXIT(0);
    end;

    [Scope('Personalization')]
    procedure Number() : Integer;
    begin
        /// <summary>
        /// Number Length: less than 18
        ///   ASCII text up till 18 characters long (include sign and decimal point).
        ///
        /// Valid characters:
        ///    "0" - "9" and "-". Number fields can be up to 20 characters long in FoxPro and Clipper.
        /// </summary>
        /// <remarks>
        /// We are not enforcing this 18 char limit.
        /// </remarks>
        EXIT(1);
    end;

    [Scope('Personalization')]
    procedure Boolean() : Integer;
    begin
        /// <summary>
        ///  L  Logical  Length: 1    Boolean/byte (8 bit)
        ///
        ///  Legal values:
        ///   ? Not initialised (default)
        ///   Y,y Yes
        ///   N,n No
        ///   F,f False
        ///   T,t True
        ///   Logical fields are always displayed using T/F/?. Some sources claims
        ///   that space (ASCII 20h) is valid for not initialised. Space may occur, but is not defined.
        /// </summary>
        EXIT(2);
    end;

    [Scope('Personalization')]
    procedure Date() : Integer;
    begin
        /// <summary>
        /// D Date Length: 8  Date in format YYYYMMDD. A date like 0000-00- 00 is *NOT* valid.
        /// </summary>
        EXIT(3);
    end;

    [Scope('Personalization')]
    procedure Memo() : Integer;
    begin
        /// <summary>
        /// M Memo Length: 10 Pointer to ASCII text field in memo file 10 digits representing a pointer to a DBT block (default is blanks).
        /// </summary>
        EXIT(4);
    end;

    [Scope('Personalization')]
    procedure Binary() : Integer;
    begin
        /// <summary>
        /// B Binary  (dBASE V) Like Memo fields, but not for text processing.
        /// </summary>
        EXIT(5);
    end;

    [Scope('Personalization')]
    procedure "Integer"() : Integer;
    begin
        /// <summary>
        /// I Integer Length: 4 byte little endian integer (FoxPro)
        /// </summary>
        EXIT(6);
    end;

    [Scope('Personalization')]
    procedure Float() : Integer;
    begin
        /// <summary>
        /// FFloatNumber stored as a string, right justified, and padded with blanks to the width of the field.
        /// example:
        /// value = " 2.40000000000e+001" Length=19  Decimal_Count=11
        ///
        /// This type was added in DBF V4.
        /// </summary>
        EXIT(7);
    end;

    [Scope('Personalization')]
    procedure Double() : Integer;
    begin
        /// <summary>
        /// O       Double         8 bytes - no conversions, stored as a double.
        /// </summary>
        EXIT(8);
    end;

    [Scope('Personalization')]
    procedure SetValue(Value : Integer);
    begin
        NumberValue := Value;
    end;

    [Scope('Personalization')]
    procedure GetValue() : Integer;
    begin
        EXIT(NumberValue);
    end;
}

