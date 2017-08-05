import parsecsv, streams, strutils
proc readTestData*(filename: string): seq[seq[string]] =
    #echo "reading test data..."
    var s = newFileStream(filename)
    if s == nil:
        echo "can't open file ", filename
        quit(1)
    var x = CsvParser()
    var data: seq[seq[string]]
    data = @[]
    open(x, s, filename)
    while readRow(x):
        var myrow: seq[string] = @[]
        for item in x.row:
            myrow.add(item)
        data.add(myrow)
    close(x)    
    return data
