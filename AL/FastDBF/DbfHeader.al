codeunit 50111 Lib_DbfHeader
{
    // 
    // /// <summary>
    // /// This class represents a DBF IV file header.
    // /// </summary>
    // ///
    // /// <remarks>
    // /// DBF files are really wasteful on space but this legacy format lives on because it's really really simple.
    // /// It lacks much in features though.
    // ///
    // ///
    // /// Thanks to Erik Bachmann for providing the DBF file structure information!!
    // /// http://www.clicketyclick.dk/databases/xbase/format/dbf.html
    // ///
    // ///           _______________________  _______
    // /// 00h /   0| Version number      *1|  ^
    // ///          |-----------------------|  |
    // /// 01h /   1| Date of last update   |  |
    // /// 02h /   2|      YYMMDD        *21|  |
    // /// 03h /   3|                    *14|  |
    // ///          |-----------------------|  |
    // /// 04h /   4| Number of records     | Record
    // /// 05h /   5| in data file          | header
    // /// 06h /   6| ( 32 bits )        *14|  |
    // /// 07h /   7|                       |  |
    // ///          |-----------------------|  |
    // /// 08h /   8| Length of header   *14|  |
    // /// 09h /   9| structure ( 16 bits ) |  |
    // ///          |-----------------------|  |
    // /// 0Ah /  10| Length of each record |  |
    // /// 0Bh /  11| ( 16 bits )     *2 *14|  |
    // ///          |-----------------------|  |
    // /// 0Ch /  12| ( Reserved )        *3|  |
    // /// 0Dh /  13|                       |  |
    // ///          |-----------------------|  |
    // /// 0Eh /  14| Incomplete transac.*12|  |
    // ///          |-----------------------|  |
    // /// 0Fh /  15| Encryption flag    *13|  |
    // ///          |-----------------------|  |
    // /// 10h /  16| Free record thread    |  |
    // /// 11h /  17| (reserved for LAN     |  |
    // /// 12h /  18|  only )               |  |
    // /// 13h /  19|                       |  |
    // ///          |-----------------------|  |
    // /// 14h /  20| ( Reserved for        |  |            _        |=======================| ______
    // ///          |   multi-user dBASE )  |  |           / 00h /  0| Field name in ASCII   |  ^
    // ///          : ( dBASE III+ - )      :  |          /          : (terminated by 00h)   :  |
    // ///          :                       :  |         |           |                       |  |
    // /// 1Bh /  27|                       |  |         |   0Ah / 10|                       |  |
    // ///          |-----------------------|  |         |           |-----------------------| For
    // /// 1Ch /  28| MDX flag (dBASE IV)*14|  |         |   0Bh / 11| Field type (ASCII) *20| each
    // ///          |-----------------------|  |         |           |-----------------------| field
    // /// 1Dh /  29| Language driver     *5|  |        /    0Ch / 12| Field data address    |  |
    // ///          |-----------------------|  |       /             |                     *6|  |
    // /// 1Eh /  30| ( Reserved )          |  |      /              | (in memory !!!)       |  |
    // /// 1Fh /  31|                     *3|  |     /       0Fh / 15| (dBASE III+)          |  |
    // ///          |=======================|__|____/                |-----------------------|  |  -
    // /// 20h /  32|                       |  |  ^          10h / 16| Field length       *22|  |   |
    // ///          |- - - - - - - - - - - -|  |  |                  |-----------------------|  |   | *7
    // ///          |                    *19|  |  |          11h / 17| Decimal count      *23|  |   |
    // ///          |- - - - - - - - - - - -|  |  Field              |-----------------------|  |  -
    // ///          |                       |  | Descriptor  12h / 18| ( Reserved for        |  |
    // ///          :. . . . . . . . . . . .:  |  |array     13h / 19|   multi-user dBASE)*18|  |
    // ///          :                       :  |  |                  |-----------------------|  |
    // ///       n  |                       |__|__v_         14h / 20| Work area ID       *16|  |
    // ///          |-----------------------|  |    \                |-----------------------|  |
    // ///       n+1| Terminator (0Dh)      |  |     \       15h / 21| ( Reserved for        |  |
    // ///          |=======================|  |      \      16h / 22|   multi-user dBASE )  |  |
    // ///       m  | Database Container    |  |       \             |-----------------------|  |
    // ///          :                    *15:  |        \    17h / 23| Flag for SET FIELDS   |  |
    // ///          :                       :  |         |           |-----------------------|  |
    // ///     / m+263                      |  |         |   18h / 24| ( Reserved )          |  |
    // ///          |=======================|__v_ ___    |           :                       :  |
    // ///          :                       :    ^       |           :                       :  |
    // ///          :                       :    |       |           :                       :  |
    // ///          :                       :    |       |   1Eh / 30|                       |  |
    // ///          | Record structure      |    |       |           |-----------------------|  |
    // ///          |                       |    |        \  1Fh / 31| Index field flag    *8|  |
    // ///          |                       |    |         \_        |=======================| _v_____
    // ///          |                       | Records
    // ///          |-----------------------|    |
    // ///          |                       |    |          _        |=======================| _______
    // ///          |                       |    |         / 00h /  0| Record deleted flag *9|  ^
    // ///          |                       |    |        /          |-----------------------|  |
    // ///          |                       |    |       /           | Data               *10|  One
    // ///          |                       |    |      /            : (ASCII)            *17: record
    // ///          |                       |____|_____/             |                       |  |
    // ///          :                       :    |                   |                       | _v_____
    // ///          :                       :____|_____              |=======================|
    // ///          :                       :    |
    // ///          |                       |    |
    // ///          |                       |    |
    // ///          |                       |    |
    // ///          |                       |    |
    // ///          |                       |    |
    // ///          |=======================|    |
    // ///          |__End_of_File__________| ___v____  End of file ( 1Ah )  *11
    // ///
    // /// </remarks>


    trigger OnRun();
    begin
    end;

    var
        FileDescriptorSize : Integer;
        ColumnDescriptorSize : Integer;
        _fileType : Integer;
        _updateDate : DateTime;
        _numRecords : Integer;
        _headerLength : Integer;
        _recordLength : Integer;
        _fields : Codeunit Lib_DbfColumnList;
        _locked : Boolean;
        _columnNameIndex : Codeunit Lib_DbfColumnNameDictionary;
        _isDirty : Boolean;
        _emptyRecord : Codeunit DotNet_Array;
        _encoding : Codeunit DotNet_Encoding;

    local procedure InitValues();
    begin
        /// <summary>
        /// Header file descriptor size is 33 bytes (32 bytes + 1 terminator byte), followed by column metadata which is 32 bytes each.
        /// </summary>
        FileDescriptorSize := 33;


        /// <summary>
        /// Field or DBF Column descriptor is 32 bytes long.
        /// </summary>
        ColumnDescriptorSize := 32;


        //type of the file, must be 03h
        _fileType := 3;

        //Date the file was last updated.
        CLEAR(_updateDate);

        //Number of records in the datafile, 32bit little-endian, unsigned
        _numRecords := 0;

        //Length of the header structure
        _headerLength := FileDescriptorSize;  //empty header is 33 bytes long. Each column adds 32 bytes.

        //Length of the records, ushort - unsigned 16 bit integer
        _recordLength := 1;  //start with 1 because the first byte is a delete flag

        //DBF fields/columns
        CLEAR(_fields);


        //indicates whether header columns can be modified!
        _locked := FALSE;

        //keeps column name index for the header, must clear when header columns change.
        //TODO:Dictionary<string, int> _columnNameIndex = null;

        /// <summary>
        /// When object is modified dirty flag is set.
        /// </summary>
        _isDirty := FALSE;


        /// <summary>
        /// mEmptyRecord is an array used to clear record data in CDbf4Record.
        /// This is shared by all record objects, used to speed up clearing fields or entire record.
        /// <seealso cref="EmptyDataRecord"/>
        /// </summary>
        //TODO:byte[] _emptyRecord = null;


        _encoding.ASCII;
    end;

    [Scope('Personalization')]
    procedure DbfHeader(var encoding : Codeunit DotNet_Encoding);
    begin
        InitValues;
        _encoding := encoding;
    end;

    [Scope('Personalization')]
    procedure HeaderLength() : Integer;
    begin
        /// <summary>
        /// Gets header length.
        /// </summary>
        EXIT(_headerLength);
    end;

    [Scope('Personalization')]
    procedure AddColumn(var oNewCol : Codeunit Lib_DbfColumn);
    begin
        /// <summary>
        /// Add a new column to the DBF header.
        /// </summary>
        /// <param name="oNewCol"></param>

        //throw exception if the header is locked
        IF _locked THEN
          ERROR('InvalidOperationException: This header is locked and can not be modified. Modifying the header would result in a corrupt DBF file. You can unlock the header by calling UnLock() method.');

        //since we are breaking the spec rules about max number of fields, we should at least
        //check that the record length stays within a number that can be recorded in the header!
        //we have 2 unsigned bytes for record length for a maximum of 65535.
        IF _recordLength + oNewCol.Length > 65535 THEN
          ERROR('ArgumentOutOfRangeException: oNewCol; Unable to add new column. Adding this column puts the record length over the maximum (which is 65535 bytes).');


        //add the column
        _fields.Add(oNewCol);

        //update offset bits, record and header lengths
        oNewCol.SetDataAddress(_recordLength);
        _recordLength += oNewCol.Length;
        _headerLength += ColumnDescriptorSize;

        //clear empty record
        CLEAR(_emptyRecord);

        //set dirty bit
        _isDirty := TRUE;
        CLEAR(_columnNameIndex);
    end;

    [Scope('Personalization')]
    procedure AddColumnByNameAndType(sName : Text;type : Integer);
    var
        DbfColumn : Codeunit Lib_DbfColumn;
    begin
        /// <summary>
        /// Create and add a new column with specified name and type.
        /// </summary>
        /// <param name="sName"></param>
        /// <param name="type"></param>
        DbfColumn.DbfColumnSimple(sName, type);
        AddColumn(DbfColumn);
    end;

    [Scope('Personalization')]
    procedure AddColumnByParams(sName : Text;type : Integer;nLength : Integer;nDecimals : Integer);
    var
        DbfColumn : Codeunit Lib_DbfColumn;
    begin
        /// <summary>
        /// Create and add a new column with specified name, type, length, and decimal precision.
        /// </summary>
        /// <param name="sName">Field name. Uniqueness is not enforced.</param>
        /// <param name="type"></param>
        /// <param name="nLength">Length of the field including decimal point and decimal numbers</param>
        /// <param name="nDecimals">Number of decimal places to keep.</param>
        DbfColumn.DbfColumn(sName, type, nLength, nDecimals);
        AddColumn(DbfColumn);
    end;

    [Scope('Personalization')]
    procedure RemoveColumn(nIndex : Integer);
    var
        oColRemove : Codeunit Lib_DbfColumn;
        "field" : Codeunit Lib_DbfColumn;
        nRemovedColLen : Integer;
        i : Integer;
    begin
        /// <summary>
        /// Remove column from header definition.
        /// </summary>
        /// <param name="nIndex"></param>

        //throw exception if the header is locked
        IF _locked THEN
          ERROR('InvalidOperationException: This header is locked and can not be modified. Modifying the header would result in a corrupt DBF file. You can unlock the header by calling UnLock() method.');

        _fields.Get(nIndex, oColRemove);
        _fields.RemoveAt(nIndex);

        oColRemove.SetDataAddress(0);
        _recordLength -= oColRemove.Length;
        _headerLength -= ColumnDescriptorSize;

        //if you remove a column offset shift for each of the columns
        //following the one removed, we need to update those offsets.
        nRemovedColLen := oColRemove.Length;
        FOR i := nIndex TO _fields.Count - 1 DO
          BEGIN
            _fields.Get(i, field);
            field.SetDataAddress(field.DataAddress - nRemovedColLen);
          END;

        //clear the empty record
        CLEAR(_emptyRecord);

        //set dirty bit
        _isDirty := TRUE;
        CLEAR(_columnNameIndex);
    end;

    [Scope('Personalization')]
    procedure ItemByName(sName : Text;var col : Codeunit Lib_DbfColumn);
    var
        colIndex : Integer;
    begin
        /// <summary>
        /// Look up a column index by name. NOT Case Sensitive. This is a change from previous behaviour!
        /// </summary>
        /// <param name="sName"></param>

        colIndex := FindColumn(sName);
        CLEAR(col);
        IF colIndex > -1 THEN
          _fields.Get(colIndex, col);

    end;

    [Scope('Personalization')]
    procedure ItemByIndex(nIndex : Integer;var col : Codeunit Lib_DbfColumn);
    begin
        /// <summary>
        /// Returns column at specified index. Index is 0 based.
        /// </summary>
        /// <param name="nIndex">Zero based index.</param>
        /// <returns></returns>

        _fields.Get(nIndex, col);
    end;

    [Scope('Personalization')]
    procedure FindColumn(sName : Text) : Integer;
    var
        i : Integer;
        "field" : Codeunit Lib_DbfColumn;
        columnIndex : Integer;
    begin
        /// <summary>
        /// Finds a column index by using a fast dictionary lookup-- creates column dictionary on first use. Returns -1 if not found. CHANGE: not case sensitive any longer!
        /// </summary>
        /// <param name="sName">Column name (case insensitive comparison)</param>
        /// <returns>column index (0 based) or -1 if not found.</returns>

        IF _columnNameIndex.IsNull THEN
          BEGIN
            _columnNameIndex.Create(_fields.Count);

            //create a new index
            FOR i := 0 TO _fields.Count - 1 DO
              BEGIN
                _fields.Get(i, field);
                _columnNameIndex.Add(UPPERCASE(field.Name), i);
              END;
          END;

        columnIndex := 0;
        IF _columnNameIndex.TryGetValue(UPPERCASE(sName), columnIndex) THEN
          EXIT(columnIndex);

        EXIT(-1);
    end;

    [Scope('Personalization')]
    procedure EmptyDataRecord(var value : Codeunit DotNet_Array);
    var
        string : Codeunit DotNet_String;
        charArray : Codeunit DotNet_Array;
    begin
        /// <summary>
        /// Returns an empty data record. This is used to clear columns
        /// </summary>
        /// <remarks>
        /// The reason we put this in the header class is because it allows us to use the CDbf4Record class in two ways.
        /// 1. we can create one instance of the record and reuse it to write many records quickly clearing the data array by bitblting to it.
        /// 2. we can create many instances of the record (a collection of records) and have only one copy of this empty dataset for all of them.
        ///    If we had put it in the Record class then we would be taking up twice as much space unnecessarily. The empty record also fits the model
        ///    and everything is neatly encapsulated and safe.
        ///
        /// </remarks>

        IF _emptyRecord.IsDotNetNull THEN
          BEGIN
            string.Set('');
            string.PadRight(_recordLength, ' ', string);
            string.ToCharArray(0, string.Length, charArray);
            _encoding.GetBytes(charArray, 0, charArray.Length, _emptyRecord);
          END;
        value := _emptyRecord;
    end;

    [Scope('Personalization')]
    procedure ColumnCount() : Integer;
    begin
        /// <summary>
        /// Returns Number of columns in this dbf header.
        /// </summary>
        EXIT(_fields.Count);
    end;

    [Scope('Personalization')]
    procedure RecordLength() : Integer;
    begin
        /// <summary>
        /// Size of one record in bytes. All fields + 1 byte delete flag.
        /// </summary>
        EXIT(_recordLength);
    end;

    [Scope('Personalization')]
    procedure RecordCount() : Integer;
    begin
        /// <summary>
        /// Get/Set number of records in the DBF.
        /// </summary>
        /// <remarks>
        /// The reason we allow client to set RecordCount is beause in certain streams
        /// like internet streams we can not update record count as we write out records, we have to set it in advance,
        /// so client has to be able to modify this property.
        /// </remarks>
        EXIT(_numRecords);
    end;

    [Scope('Personalization')]
    procedure SetRecordCount(value : Integer);
    begin
        _numRecords := value;

        //set the dirty bit
        _isDirty := TRUE;
    end;

    [Scope('Internal')]
    procedure Locked() : Boolean;
    begin
        /// <summary>
        /// Get/set whether this header is read only or can be modified. When you create a CDbfRecord
        /// object and pass a header to it, CDbfRecord locks the header so that it can not be modified any longer.
        /// in order to preserve DBF integrity.
        /// </summary>
        EXIT(_locked);
    end;

    [Scope('Internal')]
    procedure SetLocked(value : Boolean);
    begin
        _locked := value;
    end;

    [Scope('Personalization')]
    procedure Unlock();
    begin
        /// <summary>
        /// Use this method with caution. Headers are locked for a reason, to prevent DBF from becoming corrupt.
        /// </summary>
        _locked := FALSE;
    end;

    [Scope('Personalization')]
    procedure IsDirty() : Boolean;
    begin
        /// <summary>
        /// Returns true when this object is modified after read or write.
        /// </summary>
        EXIT(_isDirty);
    end;

    [Scope('Personalization')]
    procedure SetIsDirty(value : Boolean);
    begin
        _isDirty := value;
    end;

    [Scope('Personalization')]
    procedure Write(var writer : Codeunit DotNet_BinaryWriter) : Boolean;
    var
        updateDatePart : Date;
        i : Integer;
        "field" : Codeunit Lib_DbfColumn;
        cname : Codeunit DotNet_Array;
        fieldName : Codeunit DotNet_String;
        byteReserved : Codeunit DotNet_Array;
        DbfColumnType : Codeunit Lib_DbfColumnType;
    begin
        /// <summary>
        /// Encoding must be ASCII for this binary writer.
        /// </summary>
        /// <param name="writer"></param>
        /// <remarks>
        /// See class remarks for DBF file structure.
        /// </remarks>

        //write the header
        // write the output file type.
        writer.WriteByte(_fileType);

        //Update date format is YYMMDD, which is different from the column Date type (YYYYDDMM)
        updateDatePart := DT2DATE(_updateDate);
        writer.WriteByte(DATE2DMY(updateDatePart, 3) - 1900);
        writer.WriteByte(DATE2DMY(updateDatePart, 2));
        writer.WriteByte(DATE2DMY(updateDatePart, 1));

        // write the number of records in the datafile. (32 bit number, little-endian unsigned)
        writer.WriteUInt32(_numRecords);

        // write the length of the header structure.
        writer.WriteUInt16(_headerLength);

        // write the length of a record
        writer.WriteUInt16(_recordLength);

        // write the reserved bytes in the header
        FOR i := 0 TO 20 - 1 DO
          writer.WriteByte(0);

        // write all of the header records
        byteReserved.ByteArray(14); //these are initialized to 0 by default.

        FOR i := 0 TO _fields.Count - 1 DO
          BEGIN
            _fields.Get(i, field);
            fieldName.Set(field.Name);
            fieldName.PadRight(11, 0, fieldName);
            fieldName.ToCharArray(0, fieldName.Length, cname);
            writer.WriteArray(cname);

            // write the field type
            writer.WriteChar(field.ColumnTypeChar);

            // write the field data address, offset from the start of the record.
            writer.WriteInt32(field.DataAddress);


            // write the length of the field.
            // if char field is longer than 255 bytes, then we use the decimal field as part of the field length.
            IF (field.ColumnType = DbfColumnType.Character) AND (field.Length > 255) THEN
              //treat decimal count as high byte of field length, this extends char field max to 65535
              writer.WriteUInt16(field.Length)
            ELSE
              BEGIN
                // write the length of the field.
                writer.WriteByte(field.Length);

                // write the decimal count.
                writer.WriteByte(field.DecimalCount);
              END;

            // write the reserved bytes.
            writer.WriteArray(byteReserved);

          END;

        // write the end of the field definitions marker
        writer.WriteByte(13); //0x0D
        writer.Flush();

        //clear dirty bit
        _isDirty := FALSE;


        //lock the header so it can not be modified any longer,
        //we could actually postpond this until first record is written!
        _locked := TRUE;
    end;

    [Scope('Personalization')]
    procedure Read(var reader : Codeunit DotNet_BinaryReader) : Boolean;
    var
        nFileType : Integer;
        year : Integer;
        month : Integer;
        day : Integer;
        tempArray : Codeunit DotNet_Array;
        nNumFields : Integer;
        nDataOffset : Integer;
        i : Integer;
        buffer : Codeunit DotNet_Array;
        sFieldName : Codeunit DotNet_String;
        nullPoint : Integer;
        cDbaseType : Char;
        nFieldDataAddress : Integer;
        nFieldLength : Integer;
        nDecimals : Integer;
        dbfColumn : Codeunit Lib_DbfColumn;
        nExtraReadBytes : Integer;
        readerBaseStream : Codeunit DotNet_Stream;
    begin
        /// <summary>
        /// Read header data, make sure the stream is positioned at the start of the file to read the header otherwise you will get an exception.
        /// When this function is done the position will be the first record.
        /// </summary>
        /// <param name="reader"></param>

        // type of reader.
        nFileType := reader.ReadByte();

        IF nFileType <> 3 THEN
          ERROR('NotSupportedException: Unsupported DBF reader Type ' + FORMAT(nFileType));

        // parse the update date information.
        year := reader.ReadByte();
        month := reader.ReadByte();
        day := reader.ReadByte();
        _updateDate := CREATEDATETIME(DMY2DATE(day, month, year + 1900), 0T);

        // read the number of records.
        _numRecords := reader.ReadUInt32();

        // read the length of the header structure.
        _headerLength := reader.ReadUInt16();

        // read the length of a record
        _recordLength := reader.ReadInt16();

        // skip the reserved bytes in the header.
        tempArray.ByteArray(20);
        reader.ReadBytes(20, tempArray);

        // calculate the number of Fields in the header
        nNumFields := (_headerLength - FileDescriptorSize) DIV ColumnDescriptorSize;

        //offset from start of record, start at 1 because that's the delete flag.
        nDataOffset := 1;

        // read all of the header records
        _fields.Create(nNumFields);
        FOR i := 0 TO nNumFields - 1 DO
          BEGIN

            // read the field name
            buffer.CharArray(11);
            reader.ReadChars(11, buffer);
            sFieldName.FromCharArray(buffer);
            nullPoint := sFieldName.IndexOfChar(0, 0);
            IF nullPoint <> -1 THEN
              sFieldName.Substring(0, nullPoint, sFieldName);


            //read the field type
            cDbaseType := reader.ReadByte();

            // read the field data address, offset from the start of the record.
            nFieldDataAddress := reader.ReadInt32();


            //read the field length in bytes
            //if field type is char, then read FieldLength and Decimal count as one number to allow char fields to be
            //longer than 256 bytes (ASCII char). This is the way Clipper and FoxPro do it, and there is really no downside
            //since for char fields decimal count should be zero for other versions that do not support this extended functionality.
            //-----------------------------------------------------------------------------------------------------------------------
            nFieldLength := 0;
            nDecimals := 0;
            IF (cDbaseType = 'C') OR (cDbaseType = 'c') THEN
              //treat decimal count as high byte
              nFieldLength := reader.ReadUInt16()
            ELSE
              BEGIN
                //read field length as an unsigned byte.
                nFieldLength := reader.ReadByte();

                //read decimal count as one byte
                nDecimals := reader.ReadByte();

              END;


            //read the reserved bytes.
            tempArray.ByteArray(14);
            reader.ReadBytes(14, tempArray);

            //Create and add field to collection

            dbfColumn.DbfColumnWithDataAddress(sFieldName.ToString(), dbfColumn.GetDbaseTypeFromChar(cDbaseType), nFieldLength, nDecimals, nDataOffset);
            _fields.Add(dbfColumn);

            // add up address information, you can not trust the address recorded in the DBF file...
            nDataOffset += nFieldLength;

          END;

        // Last byte is a marker for the end of the field definitions.
        tempArray.ByteArray(1);
        reader.ReadBytes(1, tempArray);


        //read any extra header bytes...move to first record
        //equivalent to reader.BaseStream.Seek(mHeaderLength, SeekOrigin.Begin) except that we are not using the seek function since
        //we need to support streams that can not seek like web connections.
        nExtraReadBytes := _headerLength - (FileDescriptorSize + (ColumnDescriptorSize * _fields.Count));
        IF nExtraReadBytes > 0 THEN
          BEGIN
            tempArray.ByteArray(nExtraReadBytes);
            reader.ReadBytes(nExtraReadBytes, tempArray);
          END;


        //if the stream is not forward-only, calculate number of records using file size,
        //sometimes the header does not contain the correct record count
        //if we are reading the file from the web, we have to use ReadNext() functions anyway so
        //Number of records is not so important and we can trust the DBF to have it stored correctly.
        reader.BaseStream(readerBaseStream);
        IF (readerBaseStream.CanSeek AND (_numRecords = 0)) THEN
          //notice here that we subtract file end byte which is supposed to be 0x1A,
          //but some DBF files are incorrectly written without this byte, so we round off to nearest integer.
          //that gives a correct result with or without ending byte.
          IF _recordLength > 0 THEN
            _numRecords := ROUND((readerBaseStream.Length - _headerLength - 1) / _recordLength, 1);

        //lock header since it was read from a file. we don't want it modified because that would corrupt the file.
        //user can override this lock if really necessary by calling UnLock() method.
        _locked := TRUE;

        //clear dirty bit
        _isDirty := FALSE;
    end;

    [Scope('Internal')]
    procedure Equals(var DotNet_DbfHeader : Codeunit Lib_DbfHeader) : Boolean;
    begin
        IF DotNet_DbfHeader.ColumnCount <> ColumnCount THEN
          EXIT(FALSE);

        IF DotNet_DbfHeader.HeaderLength <> HeaderLength THEN
          EXIT(FALSE);

        IF DotNet_DbfHeader.RecordLength <> RecordLength THEN
          EXIT(FALSE);

        IF DotNet_DbfHeader.RecordCount <> RecordCount THEN
          EXIT(FALSE);

        EXIT(TRUE);
    end;

    [Scope('Internal')]
    procedure Encoding(var encoding : Codeunit DotNet_Encoding);
    begin
        encoding := _encoding;
    end;

    [Scope('Internal')]
    procedure "Fields"(var dbfColumnList : Codeunit Lib_DbfColumnList);
    begin
        dbfColumnList := _fields;
    end;
}

