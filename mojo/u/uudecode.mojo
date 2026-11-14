# Bounded BitBench decoding profile; see the package license notices.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("uudecode")
fn uudecode(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length > 4096 or length < 29: return -1
    let n = Int(length)
    var encoded = InlineArray[Int64, 4096](fill=0)
    for i in range(n):
        let value = input[i]
        if value < 0 or value > 255: return -1
        encoded[i] = value
    var header = InlineArray[Int64, 24](fill=0)
    header[0]=98; header[1]=101; header[2]=103; header[3]=105; header[4]=110; header[5]=32
    header[6]=55; header[7]=53; header[8]=53; header[9]=32; header[10]=117; header[11]=117
    header[12]=115; header[13]=116; header[14]=97; header[15]=114; header[16]=116; header[17]=46
    header[18]=102; header[19]=105; header[20]=108; header[21]=101; header[22]=32; header[23]=10
    for i in range(24):
        if encoded[i] != header[i]: return -1
    var result = InlineArray[UInt8, 2949](fill=0)
    var cursor = 24
    var written = 0
    var finished = False
    while cursor < n:
        let marker = encoded[cursor]
        cursor += 1
        if marker == 32:
            if cursor + 4 != n or encoded[cursor] != 10 or encoded[cursor + 1] != 101 or encoded[cursor + 2] != 110 or encoded[cursor + 3] != 100: return -1
            finished = True
            break
        let count = marker - 32
        if count < 1 or count > 45: return -1
        let body = 4 * ((Int(count) + 2) // 3)
        if cursor + body >= n or encoded[cursor + body] != 10 or written + Int(count) > 2949: return -1
        for i in range(body):
            if encoded[cursor + i] < 32 or encoded[cursor + i] > 95: return -1
        var emitted = 0
        while emitted < Int(count):
            let a = encoded[cursor] - 32; let b = encoded[cursor + 1] - 32
            let c = encoded[cursor + 2] - 32; let d = encoded[cursor + 3] - 32
            cursor += 4
            result[written] = UInt8(((a << 2) | (b >> 4)) & 255)
            written += 1; emitted += 1
            if emitted < Int(count):
                result[written] = UInt8(((b << 4) | (c >> 2)) & 255)
                written += 1; emitted += 1
            if emitted < Int(count):
                result[written] = UInt8(((c << 6) | d) & 255)
                written += 1; emitted += 1
        cursor += 1
    if not finished: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(written): return -2
    for i in range(written): output[i] = result[i]
    return Int64(written)
