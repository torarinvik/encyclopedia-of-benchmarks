from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for j in range(8):
        output[offset+j] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("lossy_counting_summary")
fn lossy_counting_summary(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                          output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66: return -1
    let wv = input[0]
    let nv = input[1]
    if wv < 2 or wv > 16 or nv < 0 or nv > 64: return -1
    let width = Int(wv)
    let n = Int(nv)
    if length != c_size_t(2+n): return -1
    for i in range(n):
        if input[2+i] < 0 or input[2+i] > 15: return -1
    var count = List[Int64](capacity=16)
    var error = List[Int64](capacity=16)
    for _ in range(16):
        count.append(0)
        error.append(0)
    for i in range(n):
        let item = Int(input[2+i])
        let bucket = Int64(i//width+1)
        if count[item] == 0: error[item] = bucket-1
        count[item] += 1
        if (i+1)%width == 0:
            for j in range(16):
                if count[j] != 0 and count[j]+error[j] <= bucket:
                    count[j] = 0
                    error[j] = 0
    var active = 0
    for i in range(16):
        if count[i] != 0: active += 1
    let bytes = 8+24*active
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    put_word(output, 0, Int64(active))
    var offset = 8
    for i in range(16):
        if count[i] != 0:
            put_word(output, offset, Int64(i))
            put_word(output, offset+8, count[i])
            put_word(output, offset+16, error[i])
            offset += 24
    return Int64(bytes)
