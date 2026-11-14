# Bounded BitBench encoding profile; see the package license notices.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("uuencode")
fn uuencode(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length > 4096: return -1
    let n = Int(length)
    var bytes = InlineArray[UInt8, 4096](fill=0)
    for i in range(n):
        let value = input[i]
        if value < 0 or value > 255: return -1
        bytes[i] = UInt8(value)
    let required = 22 + 4 * ((n + 2) // 3) + 2 * ((n + 44) // 45) + 5
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var header = InlineArray[UInt8, 22](fill=0)
    header[0]=98; header[1]=101; header[2]=103; header[3]=105; header[4]=110; header[5]=32
    header[6]=54; header[7]=52; header[8]=48; header[9]=32; header[10]=117; header[11]=117
    header[12]=101; header[13]=110; header[14]=99; header[15]=111; header[16]=100; header[17]=101
    header[18]=46; header[19]=99; header[20]=32; header[21]=10
    for i in range(22): output[i] = header[i]
    var cursor = 22
    var start = 0
    while start < n:
        let line_length = min(45, n - start)
        let end = start + line_length
        output[cursor] = UInt8(32 + line_length)
        cursor += 1
        var i = start
        while i < end:
            let a = Int(bytes[i])
            let b = if i + 1 < end: Int(bytes[i + 1]) else: 0
            let c = if i + 2 < end: Int(bytes[i + 2]) else: 0
            output[cursor] = UInt8(32 + ((a >> 2) & 63))
            output[cursor + 1] = UInt8(32 + (((a << 4) | (b >> 4)) & 63))
            output[cursor + 2] = if i + 1 < end: UInt8(32 + (((b << 2) | (c >> 6)) & 63)) else: UInt8(61)
            output[cursor + 3] = if i + 2 < end: UInt8(32 + (c & 63)) else: UInt8(61)
            cursor += 4
            i += 3
        output[cursor] = 10
        cursor += 1
        start = end
    output[cursor] = 32; output[cursor + 1] = 10; output[cursor + 2] = 101
    output[cursor + 3] = 110; output[cursor + 4] = 100
    return Int64(cursor + 5)
