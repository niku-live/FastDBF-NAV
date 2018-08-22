codeunit 50113 Lib_DbfRecord
{
    // /// <summary>
    // /// Use this class to create a record and write it to a dbf file. You can use one record object to write all records!!
    // /// It was designed for this kind of use. You can do this by clearing the record of all data
    // /// (call Clear() method) or setting values to all fields again, then write to dbf file.
    // /// This eliminates creating and destroying objects and optimizes memory use.
    // ///
    // /// Once you create a record the header can no longer be modified, since modifying the header would make a corrupt DBF file.
    // /// </summary>


    trigger OnRun();
    begin
    end;

    var
        _header : Codeunit Lib_DbfHeader;
        _data : Codeunit DotNet_Array;
        _recordIndex : Integer;
        _emptyRecord : Codeunit DotNet_Array;
        _allowStringTruncate : Boolean;
        _allowDecimalTruncate : Boolean;
        _allowIntegerTruncate : Boolean;
        _decimalClear : Codeunit DotNet_Array;
        _tempIntVal : Codeunit DotNet_Array;
        _encoding : Codeunit DotNet_Encoding;
        _colNameToIdx : Codeunit Lib_DbfColumnNameDictionary;
        DbfColumnType : Codeunit Lib_DbfColumnType;

    local procedure InitValues();
    var
        i : Integer;
    begin
        /// <summary>
        /// Header provides information on all field types, sizes, precision and other useful information about the DBF.
        /// </summary>
        CLEAR(_header);

        /// <summary>
        /// Dbf data are a mix of ASCII characters and binary, which neatly fit in a byte array.
        /// BinaryWriter would esentially perform the same conversion using the same Encoding class.
        /// </summary>
        CLEAR(_data);

        /// <summary>
        /// Zero based record index. -1 when not set, new records for example.
        /// </summary>
        _recordIndex := -1;

        /// <summary>
        /// Empty Record array reference used to clear fields quickly (or entire record).
        /// </summary>
        CLEAR(_emptyRecord);


        /// <summary>
        /// Specifies whether we allow strings to be truncated. If false and string is longer than we can fit in the field, an exception is thrown.
        /// </summary>
        _allowStringTruncate := TRUE;

        /// <summary>
        /// Specifies whether we allow the decimal portion of numbers to be truncated.
        /// If false and decimal digits overflow the field, an exception is thrown.
        /// </summary>
        _allowDecimalTruncate := FALSE;

        /// <summary>
        /// Specifies whether we allow the integer portion of numbers to be truncated.
        /// If false and integer digits overflow the field, an exception is thrown.
        /// </summary>
        _allowIntegerTruncate := FALSE;


        //array used to clear decimals, we can clear up to 40 decimals which is much more than is allowed under DBF spec anyway.
        //Note: 48 is ASCII code for 0.
        _decimalClear.ByteArray(45);
        FOR i := 0 TO 44 DO
          _decimalClear.SetByteValue(i, 48);

        //Warning: do not make this one static because that would not be thread safe!! The reason I have
        //placed this here is to skip small memory allocation/deallocation which fragments memory in .net.
        _tempIntVal.Int32Array(1);
        _tempIntVal.SetInt32Value(0, 0);

        //encoder
        _encoding.Encoding(1252);

        /// <summary>
        /// Column Name to Column Index map
        /// </summary>
        _colNameToIdx.Create(0);
    end;

    [Scope('Personalization')]
    procedure DbfRecord(var oHeader : Codeunit Lib_DbfHeader);
    var
        i : Integer;
        oHeaderFields : Codeunit Lib_DbfColumnList;
        "field" : Codeunit Lib_DbfColumn;
    begin
        /// <summary>
        ///
        /// </summary>
        /// <param name="oHeader">Dbf Header will be locked once a record is created
        /// since the record size is fixed and if the header was modified it would corrupt the DBF file.</param>
        InitValues;
        _header := oHeader;
        _header.SetLocked(TRUE);

        //create a buffer to hold all record data. We will reuse this buffer to write all data to the file.
        _data.ByteArray(_header.RecordLength);

        // Make sure mData[0] correctly represents 'not deleted'
        SetIsDeleted(FALSE);

        _header.EmptyDataRecord(_emptyRecord);
        oHeader.Encoding(_encoding);

        oHeader.Fields(oHeaderFields);
        FOR i := 0 TO oHeaderFields.Count - 1 DO
          BEGIN
            oHeaderFields.Get(i, field);
            _colNameToIdx.Add(field.Name, i);
          END;
    end;

    [Scope('Personalization')]
    procedure SetItemByIndex(nColIndex : Integer;value : Text);
    var
        ocol : Codeunit Lib_DbfColumn;
        ocolType : Integer;
        Buffer : Codeunit DotNet_Buffer;
        charArray : Codeunit DotNet_Array;
        string : Codeunit DotNet_String;
        len : Integer;
        nNumLen : Integer;
        nidxDecimal : Integer;
        cDec : Codeunit DotNet_Array;
        cNum : Codeunit DotNet_Array;
        nLen : Integer;
        c : Char;
        parsed_value : Decimal;
        valueAsCharArray : Codeunit DotNet_Array;
        parsed_int : Integer;
        dateval : DateTime;
    begin
        /// <summary>
        /// Set string data to a column, if the string is longer than specified column length it will be truncated!
        /// If dbf column type is not a string, input will be treated as dbf column
        /// type and if longer than length an exception will be thrown.
        /// </summary>
        /// <param name="nColIndex"></param>
        /// <returns></returns>

        _header.ItemByIndex(nColIndex, ocol);
        ocolType := ocol.ColumnType;


        //
        //if an empty value is passed, we just clear the data, and leave it blank.
        //note: test have shown that testing for null and checking length is faster than comparing to "" empty str :)
        //------------------------------------------------------------------------------------------------------------
        IF (value = '') THEN
          BEGIN
            //this is like NULL data, set it to empty. i looked at SAS DBF output when a null value exists
            //and empty data are output. we get the same result, so this looks good.
            Buffer.BlockCopy(_emptyRecord, ocol.DataAddress, _data, ocol.DataAddress, ocol.Length);

          END
        ELSE
          BEGIN

            //set values according to data type:
            //-------------------------------------------------------------
            IF (ocolType = DbfColumnType.Character) THEN
              BEGIN
                IF NOT _allowStringTruncate AND (STRLEN(value) > ocol.Length) THEN
                  ERROR('DbfDataTruncateException: Value not set. String truncation would occur and AllowStringTruncate flag is set to false. To supress this exception change AllowStringTruncate to true.');

                //BlockCopy copies bytes.  First clear the previous value, then set the new one.
                Buffer.BlockCopy(_emptyRecord, ocol.DataAddress, _data, ocol.DataAddress, ocol.Length);
                string.Set(value);
                string.ToCharArray(0, string.Length, charArray);
                IF STRLEN(value) > ocol.Length THEN
                  len := ocol.Length
                ELSE
                  len := STRLEN(value);
                _encoding.GetBytesWithOffset(charArray, 0, len, _data, ocol.DataAddress);

              END
            ELSE IF (ocolType = DbfColumnType.Number) THEN
              BEGIN

                IF (ocol.DecimalCount = 0) THEN
                  BEGIN

                    //integers
                    //----------------------------------

                    //throw an exception if integer overflow would occur
                    IF NOT _allowIntegerTruncate AND (STRLEN(value) > ocol.Length) THEN
                      ERROR('DbfDataTruncateException: Value not set. Integer does not fit and would be truncated. AllowIntegerTruncate is set to false. To supress this exception set AllowIntegerTruncate to true, although that is not recomended.');


                    //clear all numbers, set to [space].
                    //-----------------------------------------------------
                    Buffer.BlockCopy(_emptyRecord, 0, _data, ocol.DataAddress, ocol.Length);


                    //set integer part, CAREFUL not to overflow buffer! (truncate instead)
                    //-----------------------------------------------------------------------
                    IF STRLEN(value) > ocol.Length THEN
                      nNumLen := ocol.Length
                    ELSE
                      nNumLen := STRLEN(value);
                    string.Set(value);
                    string.ToCharArray(0, string.Length, charArray);
                    _encoding.GetBytesWithOffset(charArray, 0, nNumLen, _data, (ocol.DataAddress + ocol.Length - nNumLen));

                  END
                ELSE
                  BEGIN

                    ///TODO: we can improve perfomance here by not using temp char arrays cDec and cNum,
                    ///simply directly copy from source string using encoding!


                    //break value down into integer and decimal portions
                    //--------------------------------------------------------------------------
                    string.Set(value);
                    nidxDecimal := string.IndexOfChar('.', 0); //index where the decimal point occurs
                    CLEAR(cDec); //decimal portion of the number
                    CLEAR(cNum); //integer portion

                    IF nidxDecimal > -1 THEN
                      BEGIN
                        string.Set(value);
                        string.Substring(nidxDecimal + 1, string.Length - nidxDecimal, string);
                        string.Trim(string);
                        string.ToCharArray(0, string.Length, cDec);
                        string.Set(value);
                        string.Substring(0, nidxDecimal, string);
                        string.ToCharArray(0, string.Length, cNum);

                        //throw an exception if decimal overflow would occur
                        IF NOT _allowDecimalTruncate AND (cDec.Length > ocol.DecimalCount) THEN
                          ERROR('DbfDataTruncateException: Value not set. Decimal does not fit and would be truncated. AllowDecimalTruncate is set to false. To supress this exception set AllowDecimalTruncate to true.');

                     END
                    ELSE
                      string.ToCharArray(0, string.Length, cNum);


                    //throw an exception if integer overflow would occur
                    IF NOT _allowIntegerTruncate AND (cNum.Length > ocol.Length - ocol.DecimalCount - 1) THEN
                      ERROR('DbfDataTruncateException: Value not set. Integer does not fit and would be truncated. AllowIntegerTruncate is set to false. To supress this exception set AllowIntegerTruncate to true, although that is not recomended.');


                    //------------------------------------------------------------------------------------------------------------------
                    // NUMERIC TYPE
                    //------------------------------------------------------------------------------------------------------------------

                    //clear all decimals, set to 0.
                    //-----------------------------------------------------
                    Buffer.BlockCopy(_decimalClear, 0, _data, (ocol.DataAddress + ocol.Length - ocol.DecimalCount), ocol.DecimalCount);

                    //clear all numbers, set to [space].
                    Buffer.BlockCopy(_emptyRecord, 0, _data, ocol.DataAddress, (ocol.Length - ocol.DecimalCount));



                    //set decimal numbers, CAREFUL not to overflow buffer! (truncate instead)
                    //-----------------------------------------------------------------------
                    IF (nidxDecimal > -1) THEN
                      BEGIN
                        IF cDec.Length > ocol.DecimalCount THEN
                          nLen := ocol.DecimalCount
                        ELSE
                          nLen := cDec.Length;
                        _encoding.GetBytesWithOffset(cDec, 0, nLen, _data, (ocol.DataAddress + ocol.Length - ocol.DecimalCount));
                      END;

                    //set integer part, CAREFUL not to overflow buffer! (truncate instead)
                    //-----------------------------------------------------------------------
                    IF cNum.Length > ocol.Length - ocol.DecimalCount - 1 THEN
                      nNumLen := (ocol.Length - ocol.DecimalCount - 1)
                    ELSE
                      nNumLen := cNum.Length;
                    _encoding.GetBytesWithOffset(cNum, 0, nNumLen, _data, ocol.DataAddress + ocol.Length - ocol.DecimalCount - nNumLen - 1);


                    //set decimal point
                    //-----------------------------------------------------------------------
                    c := '.';
                    _data.SetByteValue(ocol.DataAddress + ocol.Length - ocol.DecimalCount - 1, c);

                END;


              END
            ELSE IF (ocolType = DbfColumnType.Float) THEN
              BEGIN
                //------------------------------------------------------------------------------------------------------------------
                // FLOAT TYPE
                // example:   value=" 2.40000000000e+001"  Length=19   Decimal-Count=11
                //------------------------------------------------------------------------------------------------------------------


                // check size, throw exception if value won't fit:
                IF (STRLEN(value) > ocol.Length) THEN
                  ERROR('DbfDataTruncateException: Value not set. Float value does not fit and would be truncated.');


                CLEAR(parsed_value);
                IF (NOT EVALUATE(parsed_value, value)) THEN
                  BEGIN
                    //value did not parse, input is not correct.
                    ERROR('DbfDataTruncateException: Value not set. Float value format is bad: "' + value + '"   expected format: " 2.40000000000e+001"');
                  END;

                //clear value that was present previously
                Buffer.BlockCopy(_decimalClear, 0, _data, ocol.DataAddress, ocol.Length);

                //copy new value at location
                string.Set(value);
                string.ToCharArray(0, string.Length, valueAsCharArray);
                _encoding.GetBytesWithOffset(valueAsCharArray, 0, valueAsCharArray.Length, _data, ocol.DataAddress);

              END
            ELSE IF (ocolType = DbfColumnType.Integer) THEN
              BEGIN
                //note this is a binary Integer type!
                //----------------------------------------------

                ///TODO: maybe there is a better way to copy 4 bytes from int to byte array. Some memory function or something.
                EVALUATE(parsed_int, value);
                _tempIntVal.SetInt32Value(0, parsed_int);
                Buffer.BlockCopy(_tempIntVal, 0, _data, ocol.DataAddress, 4);

              END
            ELSE IF (ocolType = DbfColumnType.Memo) THEN
              BEGIN
                //copy 10 digits...
                ///TODO: implement MEMO

                ERROR('NotImplementedException: Memo data type functionality not implemented yet!');

              END
            ELSE IF (ocolType = DbfColumnType.Boolean) THEN
              BEGIN
                value := LOWERCASE(value);
                IF ((value = 'true') OR (value = '1') OR
                    (value = 'T') OR (value = 'yes') OR
                    (value = 'Y')) THEN
                  c := 'T'
                ELSE IF (value = ' ') OR (value = '?') THEN
                  c := '?'
                ELSE
                  c := 'F';
                _data.SetByteValue(ocol.DataAddress, c);
              END
            ELSE IF (ocolType = DbfColumnType.Date) THEN
              BEGIN
                //try to parse out date value using Date.Parse() function, then set the value
                CLEAR(dateval);
                IF (EVALUATE(dateval, value)) THEN
                  BEGIN
                    SetDateValue(nColIndex, dateval);
                  END
                ELSE
                   ERROR('InvalidOperationException: Date could not be parsed from source string! Please parse the Date and set the value (you can try using DateTime.Parse() or DateTime.TryParse() functions).');

              END
            ELSE IF (ocolType = DbfColumnType.Binary) THEN
              ERROR('InvalidOperationException: Can not use string source to set binary data. Use SetBinaryValue() and GetBinaryValue() functions instead.')

            ELSE
              ERROR('InvalidDataException: Unrecognized data type: ' + FORMAT(ocolType));

          END;
    end;

    [Scope('Personalization')]
    procedure ItemByIndex(nColIndex : Integer) : Text;
    var
        ocol : Codeunit Lib_DbfColumn;
        charArray : Codeunit DotNet_Array;
        string : Codeunit DotNet_String;
    begin
        _header.ItemByIndex(nColIndex, ocol);
        _encoding.GetChars(_data, ocol.DataAddress, ocol.Length, charArray);
        string.FromCharArray(charArray);
        EXIT(string.ToString());
    end;

    [Scope('Personalization')]
    procedure ItemByName(nColName : Text) : Text;
    begin
        /// <summary>
        /// Set string data to a column, if the string is longer than specified column length it will be truncated!
        /// If dbf column type is not a string, input will be treated as dbf column
        /// type and if longer than length an exception will be thrown.
        /// </summary>
        /// <param name="nColName"></param>
        /// <returns></returns>
        IF (_colNameToIdx.ContainsKey(nColName)) THEN
          EXIT(ItemByIndex(_colNameToIdx.Item(nColName)));
        ERROR('InvalidOperationException:' + STRSUBSTNO('There''s no column with name "%1"', nColName));
    end;

    [Scope('Personalization')]
    procedure SetItemByName(nColName : Text;value : Text);
    begin
        IF (_colNameToIdx.ContainsKey(nColName)) THEN
          SetItemByIndex(_colNameToIdx.Item(nColName), value)
        ELSE
          ERROR('InvalidOperationException:' + STRSUBSTNO('There''s no column with name "%1"', nColName));
    end;

    [Scope('Personalization')]
    procedure GetDateValue(nColIndex : Integer) : DateTime;
    var
        ocol : Codeunit Lib_DbfColumn;
        sDateVal : Text;
        TypeHelper : Codeunit "Type Helper";
        temp : Variant;
    begin
        /// <summary>
        /// Get date value.
        /// </summary>
        /// <param name="nColIndex"></param>
        /// <returns></returns>

        _header.ItemByIndex(nColIndex, ocol);

        IF (ocol.ColumnType = DbfColumnType.Date) THEN
          BEGIN
            sDateVal := _encoding.GetString(_data, ocol.DataAddress, ocol.Length);
            TypeHelper.Evaluate(temp, sDateVal, 'yyyyMMdd', 'en-US');
            EXIT(temp);
          END
        ELSE
          ERROR('Exception: Invalid data type. Column "' + ocol.Name + '" is not a date column.');
    end;

    [Scope('Personalization')]
    procedure SetDateValue(nColIndex : Integer;value : DateTime);
    var
        ocol : Codeunit Lib_DbfColumn;
        string : Codeunit DotNet_String;
        ocolType : Integer;
        charArray : Codeunit DotNet_Array;
    begin
        /// <summary>
        /// Get date value.
        /// </summary>
        /// <param name="nColIndex"></param>
        /// <returns></returns>

        _header.ItemByIndex(nColIndex, ocol);
        ocolType := ocol.ColumnType;


        IF (ocolType = DbfColumnType.Date) THEN
          BEGIN

            //Format date and set value, date format is like this: yyyyMMdd
            //-------------------------------------------------------------
            string.Set(FORMAT(value, 0, '<Year4><Month,2><Day,2>'));
            string.ToCharArray(0, string.Length, charArray);
            _encoding.GetBytesWithOffset(charArray, 0, ocol.Length, _data, ocol.DataAddress);

          END
        ELSE
          ERROR('Exception: Invalid data type. Column is of "' + FORMAT(ocol.ColumnType) + '" type, not date.');
    end;

    [Scope('Personalization')]
    procedure ClearRecord();
    var
        Buffer : Codeunit DotNet_Buffer;
    begin
        /// <summary>
        /// Clears all data in the record.
        /// </summary>

        Buffer.BlockCopy(_emptyRecord, 0, _data, 0, _emptyRecord.Length);
        _recordIndex := -1;
    end;

    [Scope('Personalization')]
    procedure ToString() : Text;
    var
        string : Codeunit DotNet_String;
        charArray : Codeunit DotNet_Array;
    begin
        /// <summary>
        /// returns a string representation of this record.
        /// </summary>
        /// <returns></returns>
        _encoding.GetChars(_data, 0, _data.Length, charArray);
        string.FromCharArray(charArray);
        EXIT(string.ToString());
    end;

    [Scope('Personalization')]
    procedure RecordIndex() : Integer;
    begin
        /// <summary>
        /// Gets/sets a zero based record index. This information is not directly stored in DBF.
        /// It is the location of this record within the DBF.
        /// </summary>
        /// <remarks>
        /// This property is managed from outside this object,
        /// CDbfFile object updates it when records are read. The reason we don't set it in the Read()
        /// function within this object is that the stream can be forward-only so the Position property
        /// is not available and there is no way to figure out what index the record was unless you
        /// count how many records were read, and that's exactly what CDbfFile does.
        /// </remarks>
        EXIT(_recordIndex);
    end;

    [Scope('Personalization')]
    procedure SetRecordIndex(value : Integer);
    begin
        _recordIndex := value;
    end;

    [Scope('Personalization')]
    procedure IsDeleted() : Boolean;
    var
        c : Char;
    begin
        /// <summary>
        /// Returns/sets flag indicating whether this record was tagged deleted.
        /// </summary>
        /// <remarks>Use CDbf4File.Compress() function to rewrite dbf removing records flagged as deleted.</remarks>
        /// <seealso cref="CDbf4File.Compress() function"/>

        c := '*';
        EXIT(_data.GetValueAsInteger(0) = c);
    end;

    [Scope('Personalization')]
    procedure SetIsDeleted(value : Boolean);
    var
        c : Char;
    begin
        IF value THEN
          c := '*'
        ELSE
          c := ' ';
        _data.SetByteValue(0, c);
    end;

    [Scope('Personalization')]
    procedure AllowStringTurncate() : Boolean;
    begin
        /// <summary>
        /// Specifies whether strings can be truncated. If false and string is longer than can fit in the field, an exception is thrown.
        /// Default is True.
        /// </summary>
        EXIT(_allowStringTruncate);
    end;

    [Scope('Personalization')]
    procedure SetAllowStringTurncate(value : Boolean);
    begin
        _allowStringTruncate := value;
    end;

    [Scope('Personalization')]
    procedure AllowDecimalTruncate() : Boolean;
    begin
        /// <summary>
        /// Specifies whether to allow the decimal portion of numbers to be truncated.
        /// If false and decimal digits overflow the field, an exception is thrown. Default is false.
        /// </summary>
        EXIT(_allowDecimalTruncate);
    end;

    [Scope('Personalization')]
    procedure SetAllowDecimalTruncate(value : Boolean);
    begin
        _allowDecimalTruncate := value;
    end;

    [Scope('Personalization')]
    procedure AllowIntegerTruncate() : Boolean;
    begin
        /// <summary>
        /// Specifies whether integer portion of numbers can be truncated.
        /// If false and integer digits overflow the field, an exception is thrown.
        /// Default is False.
        /// </summary>
        EXIT(_allowIntegerTruncate);
    end;

    [Scope('Personalization')]
    procedure SetAllowIntegerTruncate(value : Boolean);
    begin
        _allowIntegerTruncate := value;
    end;

    [Scope('Personalization')]
    procedure Header(var value : Codeunit Lib_DbfHeader);
    begin
        /// <summary>
        /// Returns header object associated with this record.
        /// </summary>
        value := _header;
    end;

    [Scope('Personalization')]
    procedure ColumnByIndex(index : Integer;var value : Codeunit Lib_DbfColumn);
    begin
        /// <summary>
        /// Get column by index.
        /// </summary>
        /// <param name="index"></param>
        /// <returns></returns>
        _header.ItemByIndex(index, value);
    end;

    [Scope('Personalization')]
    procedure ColumnByName(sName : Text;var value : Codeunit Lib_DbfColumn);
    begin
        /// <summary>
        /// Get column by name.
        /// </summary>
        /// <param name="index"></param>
        /// <returns></returns>
        _header.ItemByName(sName, value);
    end;

    [Scope('Personalization')]
    procedure ColumnCount() : Integer;
    begin
        /// <summary>
        /// Gets column count from header.
        /// </summary>
        EXIT(_header.ColumnCount);
    end;

    [Scope('Personalization')]
    procedure FindColumn(sName : Text) : Integer;
    begin
        /// <summary>
        /// Finds a column index by searching sequentially through the list. Case is ignored. Returns -1 if not found.
        /// </summary>
        /// <param name="sName">Column name.</param>
        /// <returns>Column index (0 based) or -1 if not found.</returns>
        EXIT(_header.FindColumn(sName));
    end;

    [Scope('Internal')]
    procedure Write(var obw : Codeunit DotNet_Stream;bClearRecordAfterWrite : Boolean);
    begin
        /// <summary>
        /// Writes data to stream. Make sure stream is positioned correctly because we simply write out data to it, and clear the record.
        /// </summary>
        /// <param name="osw"></param>
        obw.Write(_data, 0, _data.Length);

        IF (bClearRecordAfterWrite) THEN
          ClearRecord();
    end;

    [Scope('Internal')]
    procedure Read(var obr : Codeunit DotNet_Stream) : Boolean;
    begin
        /// <summary>
        /// Read record from stream. Returns true if record read completely, otherwise returns false.
        /// </summary>
        /// <param name="obr"></param>
        /// <returns></returns>

        EXIT(obr.Read(_data, 0, _data.Length) >= _data.Length);
    end;

    [Scope('Internal')]
    procedure ReadValue(var obr : Codeunit DotNet_Stream;colIndex : Integer) : Text;
    var
        ocol : Codeunit Lib_DbfColumn;
        string : Codeunit DotNet_String;
        charArray : Codeunit DotNet_Array;
    begin
        _header.ItemByIndex(colIndex, ocol);

        _encoding.GetChars(_data, ocol.DataAddress, ocol.Length, charArray);
        string.FromCharArray(charArray);
        EXIT(string.ToString());
    end;
}

