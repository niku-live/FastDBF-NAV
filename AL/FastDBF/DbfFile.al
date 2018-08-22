codeunit 50110 Lib_DbfFile
{
    // /// <summary>
    // /// This class represents a DBF file. You can create new, open, update and save DBF files using this class and supporting classes.
    // /// Also, this class supports reading/writing from/to an internet forward only type of stream!
    // /// </summary>
    // /// <remarks>
    // /// TODO: add end of file byte '0x1A' !!!
    // /// We don't relly on that byte at all, and everything works with or without that byte, but it should be there by spec.
    // /// </remarks>


    trigger OnRun();
    begin
    end;

    var
        _header : Codeunit Lib_DbfHeader;
        _headerWritten : Boolean;
        _dbfFile : Codeunit DotNet_Stream;
        _dbfFileReader : Codeunit DotNet_BinaryReader;
        _dbfFileWriter : Codeunit DotNet_BinaryWriter;
        _encoding : Codeunit DotNet_Encoding;
        _fileName : Text;
        _recordsReadCount : BigInteger;
        _isForwardOnly : Boolean;
        _isReadOnly : Boolean;

    local procedure InitValues();
    begin
        /// <summary>
        /// Helps read/write dbf file header information.
        /// </summary>
        CLEAR(_header);


        /// <summary>
        /// flag that indicates whether the header was written or not...
        /// </summary>
        _headerWritten := FALSE;


        /// <summary>
        /// Streams to read and write to the DBF file.
        /// </summary>
        CLEAR(_dbfFile);
        CLEAR(_dbfFileReader);
        CLEAR(_dbfFileWriter);

        /// <summary>
        /// By default use windows 1252 code page encoding.
        /// </summary>
        _encoding.Encoding(1252);

        /// <summary>
        /// File that was opened, if one was opened at all.
        /// </summary>
        _fileName := '';


        /// <summary>
        /// Number of records read using ReadNext() methods only. This applies only when we are using a forward-only stream.
        /// mRecordsReadCount is used to keep track of record index. With a seek enabled stream,
        /// we can always calculate index using stream position.
        /// </summary>
        _recordsReadCount := 0;


        /// <summary>
        /// keep these values handy so we don't call functions on every read.
        /// </summary>
        _isForwardOnly := FALSE;
        _isReadOnly := FALSE;
    end;

    [Scope('Personalization')]
    procedure DbfFile(var encoding : Codeunit DotNet_Encoding);
    begin
        InitValues;
        _encoding := encoding;
        _header.DbfHeader(encoding);
    end;

    [Scope('Personalization')]
    procedure Open(var ofs : Codeunit DotNet_Stream);
    begin
        /// <summary>
        /// Open a DBF from a FileStream. This can be a file or an internet connection stream. Make sure that it is positioned at start of DBF file.
        /// Reading a DBF over the internet we can not determine size of the file, so we support HasMore(), ReadNext() interface.
        /// RecordCount information in header can not be trusted always, since some packages store 0 there.
        /// </summary>
        /// <param name="ofs"></param>
        IF NOT _dbfFile.IsDotNetNull THEN
          Close();

        _dbfFile := ofs;
        CLEAR(_dbfFileReader);
        CLEAR(_dbfFileWriter);

        IF _dbfFile.CanRead THEN
          _dbfFileReader.BinaryReaderWithEncoding(_dbfFile, _encoding);

        IF _dbfFile.CanWrite THEN
          _dbfFileWriter.BinaryWriterWithEncoding(_dbfFile, _encoding);

        //reset position
        _recordsReadCount := 0;

        //assume header is not written
        _headerWritten := FALSE;

        //read the header
        IF ofs.CanRead THEN
          //try to read the header...
          IF _header.Read(_dbfFileReader) THEN
            _headerWritten := TRUE
          ELSE
            BEGIN
              //could not read header, file is empty
              _header.DbfHeader(_encoding);
              _headerWritten := FALSE;
            END;

        IF NOT _dbfFile.IsDotNetNull THEN
          BEGIN
            _isReadOnly := NOT _dbfFile.CanWrite;
            _isForwardOnly := NOT _dbfFile.CanSeek;
          END;
    end;

    [Scope('Personalization')]
    procedure Close();
    begin
        /// <summary>
        /// Update header info, flush buffers and close streams. You should always call this method when you are done with a DBF file.
        /// </summary>
        //try to update the header if it has changed
        //------------------------------------------
        IF _header.IsDirty THEN
          WriteHeader();

        //Empty header...
        //--------------------------------
        _header.DbfHeader(_encoding);
        _headerWritten := FALSE;


        //reset current record index
        //--------------------------------
        _recordsReadCount := 0;


        //Close streams...
        //--------------------------------
        IF NOT _dbfFileWriter.IsDotNetNull THEN
          BEGIN
            _dbfFileWriter.Flush();
            _dbfFileWriter.Close();
          END;

        IF NOT _dbfFileReader.IsDotNetNull THEN
          _dbfFileReader.Close();

        IF NOT _dbfFile.IsDotNetNull THEN
          BEGIN
            _dbfFile.Close();
            _dbfFile.Dispose();
          END;

        //set streams to null
        //--------------------------------
        CLEAR(_dbfFileReader);
        CLEAR(_dbfFileWriter);
        CLEAR(_dbfFile);

        _fileName := '';
    end;

    [Scope('Personalization')]
    procedure IsReadOnly() : Boolean;
    begin
        EXIT(_isReadOnly);
    end;

    [Scope('Personalization')]
    procedure IsForwardOnly() : Boolean;
    begin
        EXIT(_isForwardOnly);
    end;

    [Scope('Personalization')]
    procedure FileName() : Text;
    begin
        EXIT(_fileName);
    end;

    [Scope('Personalization')]
    procedure ReadNext(var oFillRecord : Codeunit Lib_DbfRecord) : Boolean;
    var
        oFillRecordHeader : Codeunit Lib_DbfHeader;
        bRead : Boolean;
    begin
        /// <summary>
        /// Read next record and fill data into parameter oFillRecord. Returns true if a record was read, otherwise false.
        /// </summary>
        /// <param name="oFillRecord"></param>
        /// <returns></returns>


        //check if we can fill this record with data. it must match record size specified by header and number of columns.
        //we are not checking whether it comes from another DBF file or not, we just need the same structure. Allow flexibility but be safe.
        oFillRecord.Header(oFillRecordHeader);
        IF NOT oFillRecordHeader.Equals(_header) AND ((oFillRecordHeader.ColumnCount <> _header.ColumnCount) OR (oFillRecordHeader.RecordLength <> _header.RecordLength)) THEN
          ERROR('Exception: Record parameter does not have the same size and number of columns as the ' +
                'header specifies, so we are unable to read a record into oFillRecord. ' +
                'This is a programming error, have you mixed up DBF file objects?');

        //DBF file reader can be null if stream is not readable...
        IF _dbfFileReader.IsDotNetNull THEN
          ERROR('Exception: Read stream is null, either you have opened a stream that can not be ' +
                'read from (a write-only stream) or you have not opened a stream at all.');

        //read next record...
        bRead := oFillRecord.Read(_dbfFile);

        IF bRead THEN
          IF _isForwardOnly THEN
            BEGIN
              //zero based index! set before incrementing count.
              oFillRecord.SetRecordIndex(_recordsReadCount);
              _recordsReadCount+=1;
            END
          ELSE
              oFillRecord.SetRecordIndex(((_dbfFile.Position - _header.HeaderLength) DIV _header.RecordLength) - 1);


        EXIT(bRead);
    end;

    [Scope('Personalization')]
    procedure Read(index : BigInteger;var oFillRecord : Codeunit Lib_DbfRecord) : Boolean;
    var
        oFillRecordHeader : Codeunit Lib_DbfHeader;
        bRead : Boolean;
        nSeekToPosition : BigInteger;
    begin
        /// <summary>
        /// Reads a record specified by index into oFillRecord object. You can use this method
        /// to read in and process records without creating and discarding record objects.
        /// Note that you should check that your stream is not forward-only! If you have a forward only stream, use ReadNext() functions.
        /// </summary>
        /// <param name="index">Zero based record index.</param>
        /// <param name="oFillRecord">Record object to fill, must have same size and number of fields as thid DBF file header!</param>
        /// <remarks>
        /// <returns>True if read a record was read, otherwise false. If you read end of file false will be returned and oFillRecord will NOT be modified!</returns>
        /// The parameter record (oFillRecord) must match record size specified by the header and number of columns as well.
        /// It does not have to come from the same header, but it must match the structure. We are not going as far as to check size of each field.
        /// The idea is to be flexible but safe. It's a fine balance, these two are almost always at odds.
        /// </remarks>

        //check if we can fill this record with data. it must match record size specified by header and number of columns.
        //we are not checking whether it comes from another DBF file or not, we just need the same structure. Allow flexibility but be safe.


        oFillRecord.Header(oFillRecordHeader);
        IF NOT oFillRecordHeader.Equals(_header) AND ((oFillRecordHeader.ColumnCount <> _header.ColumnCount) OR (oFillRecordHeader.RecordLength <> _header.RecordLength)) THEN
          ERROR('Exception: Record parameter does not have the same size and number of columns as the ' +
                'header specifies, so we are unable to read a record into oFillRecord. ' +
                'This is a programming error, have you mixed up DBF file objects?');

        //DBF file reader can be null if stream is not readable...
        IF _dbfFileReader.IsDotNetNull THEN
          ERROR('Exception: Read stream is null, either you have opened a stream that can not be ' +
                'read from (a write-only stream) or you have not opened a stream at all.');

        //move to the specified record, note that an exception will be thrown is stream is not seekable!
        //This is ok, since we provide a function to check whether the stream is seekable.
        nSeekToPosition := _header.HeaderLength + (index * _header.RecordLength);

        //check whether requested record exists. Subtract 1 from file length (there is a terminating character 1A at the end of the file)
        //so if we hit end of file, there are no more records, so return false;
        IF (index < 0) OR (_dbfFile.Length - 1 <= nSeekToPosition) THEN
          EXIT(FALSE);

        //move to record and read
        _dbfFile.Seek(nSeekToPosition, 0); //SeekOrigin.Begin

        //read the record
        bRead := oFillRecord.Read(_dbfFile);
        IF bRead THEN
          oFillRecord.SetRecordIndex(index);

        EXIT(bRead);
    end;

    [Scope('Personalization')]
    procedure ReadValue(rowIndex : Integer;columnIndex : Integer;var result : Text) : Boolean;
    var
        ocol : Codeunit Lib_DbfColumn;
        nSeekToPosition : BigInteger;
        data : Codeunit DotNet_Array;
        dotNetResult : Codeunit DotNet_String;
        charsArray : Codeunit DotNet_Array;
    begin
        CLEAR(result);

        _header.ItemByIndex(columnIndex, ocol);

        //move to the specified record, note that an exception will be thrown is stream is not seekable!
        //This is ok, since we provide a function to check whether the stream is seekable.
        nSeekToPosition := _header.HeaderLength + (rowIndex * _header.RecordLength) + ocol.DataAddress;

        //check whether requested record exists. Subtract 1 from file length (there is a terminating character 1A at the end of the file)
        //so if we hit end of file, there are no more records, so return false;
        IF (rowIndex < 0) OR (_dbfFile.Length - 1 <= nSeekToPosition) THEN
          EXIT(FALSE);

        //move to position and read
        _dbfFile.Seek(nSeekToPosition, 0);//SeekOrigin.Begin;

        //read the value
        data.ByteArray(ocol.Length);
        _dbfFile.Read(data, 0, ocol.Length);
        _encoding.GetChars(data, 0, ocol.Length, charsArray);
        dotNetResult.FromCharArray(data);
        result := dotNetResult.ToString();

        EXIT(TRUE);
    end;

    [Scope('Personalization')]
    procedure Write(var orec : Codeunit Lib_DbfRecord;bClearRecordAfterWrite : Boolean);
    var
        nNumRecords : Integer;
        _dbfFileWriterBaseStream : Codeunit DotNet_Stream;
    begin
        /// <summary>
        /// Write a record to file. If RecordIndex is present, record will be updated, otherwise a new record will be written.
        /// Header will be output first if this is the first record being writen to file.
        /// This method does not require stream seek capability to add a new record.
        /// </summary>
        /// <param name="orec"></param>

        //if header was never written, write it first, then output the record
        IF NOT _headerWritten THEN
          WriteHeader();

        //if this is a new record (RecordIndex should be -1 in that case)
        IF orec.RecordIndex < 0 THEN
          BEGIN
            _dbfFileWriter.BaseStream(_dbfFileWriterBaseStream);
            IF _dbfFileWriterBaseStream.CanSeek THEN
              BEGIN
                //calculate number of records in file. do not rely on header's RecordCount property since client can change that value.
                //also note that some DBF files do not have ending 0x1A byte, so we subtract 1 and round off
                //instead of just cast since cast would just drop decimals.
                nNumRecords := ROUND(((_dbfFile.Length - _header.HeaderLength - 1) / _header.RecordLength), 1);
                IF nNumRecords < 0 THEN
                  nNumRecords := 0;

                orec.SetRecordIndex(nNumRecords);
                Update(orec);
                _header.SetRecordCount(_header.RecordCount + 1);
              END
            ELSE
              BEGIN
                //we can not position this stream, just write out the new record.
                orec.Write(_dbfFile, FALSE);
                _header.SetRecordCount(_header.RecordCount + 1);
              END;
          END
        ELSE
          Update(orec);

        IF bClearRecordAfterWrite THEN
          CLEAR(orec);
    end;

    [Scope('Personalization')]
    procedure Update(var orec : Codeunit Lib_DbfRecord);
    var
        orecHeader : Codeunit Lib_DbfHeader;
        nSeekToPosition : BigInteger;
    begin
        /// <summary>
        /// Update a record. RecordIndex (zero based index) must be more than -1, otherwise an exception is thrown.
        /// You can also use Write method which updates a record if it has RecordIndex or adds a new one if RecordIndex == -1.
        /// RecordIndex is set automatically when you call any Read() methods on this class.
        /// </summary>
        /// <param name="orec"></param>

        //if header was never written, write it first, then output the record
        IF NOT _headerWritten THEN
          WriteHeader();


        //Check if record has an index
        IF orec.RecordIndex < 0 THEN
          ERROR('Exception: RecordIndex is not set, unable to update record. Set RecordIndex or call Write() method to add a new record to file.');


        //Check if this record matches record size specified by header and number of columns.
        orec.Header(orecHeader);
        //Client can pass a record from another DBF that is incompatible with this one and that would corrupt the file.
        IF (NOT orecHeader.Equals(_header) AND ((orecHeader.ColumnCount <> _header.ColumnCount) OR (orecHeader.RecordLength <> _header.RecordLength))) THEN
          ERROR('Record parameter does not have the same size and number of columns as the ' +
                'header specifies. Writing this record would corrupt the DBF file. ' +
                'This is a programming error, have you mixed up DBF file objects?');

        //DBF file writer can be null if stream is not writable to...
        IF _dbfFileWriter.IsDotNetNull THEN
          ERROR('Write stream is null. Either you have opened a stream that can not be ' +
                'writen to (a read-only stream) or you have not opened a stream at all.');


        //move to the specified record, note that an exception will be thrown if stream is not seekable!
        //This is ok, since we provide a function to check whether the stream is seekable.
        nSeekToPosition := _header.HeaderLength + (orec.RecordIndex * _header.RecordLength);

        //check whether we can seek to this position. Subtract 1 from file length (there is a terminating character 1A at the end of the file)
        //so if we hit end of file, there are no more records, so return false;
        IF _dbfFile.Length < nSeekToPosition THEN
          ERROR('Invalid record position. Unable to save record.');

        //move to record start
        _dbfFileWriter.Seek(nSeekToPosition, 0); //SeekOrigin.Begin

        //write
        orec.Write(_dbfFile, FALSE);
    end;

    [Scope('Personalization')]
    procedure WriteHeader() : Boolean;
    var
        _dbfFileWriterBaseStream : Codeunit DotNet_Stream;
    begin
        /// <summary>
        /// Save header to file. Normally, you do not have to call this method, header is saved
        /// automatically and updated when you close the file (if it changed).
        /// </summary>

        //update header if possible
        //--------------------------------
        IF NOT _dbfFileWriter.IsDotNetNull THEN
          BEGIN
            _dbfFileWriter.BaseStream(_dbfFileWriterBaseStream);
            IF _dbfFileWriterBaseStream.CanSeek THEN
              BEGIN
                _dbfFileWriter.Seek(0, 0); //SeekOrigin.Begin
                _header.Write(_dbfFileWriter);
                _headerWritten := TRUE;
                EXIT(TRUE);
              END
            ELSE
              BEGIN
                //if stream can not seek, then just write it out and that's it.
                IF NOT _headerWritten THEN
                  _header.Write(_dbfFileWriter);

                _headerWritten := TRUE;

              END;
          END;

        EXIT(FALSE);
    end;

    [Scope('Personalization')]
    procedure Header(var DotNet_DbfHeader : Codeunit Lib_DbfHeader);
    begin
        /// <summary>
        /// Access DBF header with information on columns. Use this object for faster access to header.
        /// Remove one layer of function calls by saving header reference and using it directly to access columns.
        /// </summary>
        DotNet_DbfHeader := _header;
    end;
}

