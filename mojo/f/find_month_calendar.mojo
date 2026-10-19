from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn calendar_leap(year: Int64) -> Bool:
    return year % 400 == 0 or (year % 100 != 0 and year % 4 == 0)

fn calendar_month_length(year: Int64, month: Int64) -> Int64:
    if month == 2 and calendar_leap(year): return 29
    if month == 1 or month == 3 or month == 5 or month == 7 or month == 8 or month == 10 or month == 12: return 31
    return 30 if month == 4 or month == 6 or month == 9 or month == 11 else 28

fn calendar_offset(month: Int64, year: Int64) -> Int64:
    var difference: Int64 = 0
    if year >= 1900:
        for y in range(1900, year): difference += 366 if calendar_leap(y) else 365
        for m in range(1, month): difference += calendar_month_length(year, m)
        return difference % 7
    for y in range(year, 1900): difference += 366 if calendar_leap(y) else 365
    for m in range(1, month): difference -= calendar_month_length(1900, m)
    return (7 - difference % 7) % 7

@export("find_month_calendar")
fn find_month_calendar(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let month = values[0]
    let year = values[1]
    if month < 1 or month > 12 or year < 1899 or year > 2100: return -1
    let offset = calendar_offset(month, year)
    let cells = offset + calendar_month_length(year, month)
    let required = 27 + cells * 4 + (cells + 6) / 7
    if required > 181: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < required: return -2
    var stage = InlineArray[UInt8, 181](0)
    var header = InlineArray[UInt8, 27](0)
    header[0]=77; header[1]=32; header[2]=32; header[3]=32; header[4]=84; header[5]=32; header[6]=32; header[7]=32
    header[8]=87; header[9]=32; header[10]=32; header[11]=32; header[12]=84; header[13]=104; header[14]=32; header[15]=32
    header[16]=70; header[17]=32; header[18]=32; header[19]=32; header[20]=83; header[21]=32; header[22]=32; header[23]=32
    header[24]=83; header[25]=117; header[26]=10
    var written: Int64 = 27
    for i in range(27): stage[i] = header[i]
    var cursor: Int64 = 0
    while cursor < cells:
        var row_cells = cells - cursor
        if row_cells > 7: row_cells = 7
        for col in range(row_cells):
            let cell = cursor + col
            let day = 0 if cell < offset else cell - offset + 1
            if day == 0:
                for b in range(4): stage[written] = 32; written += 1
            elif day >= 10:
                stage[written]=UInt8(48 + day / 10); written += 1
                stage[written]=UInt8(48 + day % 10); written += 1
                stage[written]=32; written += 1
                stage[written]=32; written += 1
            else:
                stage[written]=UInt8(48 + day); written += 1
                stage[written]=32; written += 1
                stage[written]=32; written += 1
                stage[written]=32; written += 1
        stage[written] = 10
        written += 1
        cursor += row_cells
    for i in range(written): output[i] = stage[i]
    return written
