from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for j in range(8):
        output[offset+j] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("approximate_tandem_squares")
fn approximate_tandem_squares(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 34: return -1
    let nv = input[0]
    let budget = input[1]
    if nv < 2 or nv > 32 or budget < 0 or budget > 8: return -1
    let n = Int(nv)
    if length != c_size_t(n+2): return -1
    for i in range(n):
        if input[2+i] < 0 or input[2+i] > 3: return -1
    var records = List[Int64](capacity=768)
    var count = 0
    for start in range(n):
        var period = 1
        while 2*period <= n-start:
            var mismatches = Int64(0)
            for i in range(period):
                if input[2+start+i] != input[2+start+period+i]: mismatches += 1
            if mismatches <= budget:
                records.append(Int64(start))
                records.append(Int64(period))
                records.append(mismatches)
                count += 1
            period += 1
    let bytes = 8*(1+3*count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    put_word(output, 0, Int64(count))
    for i in range(3*count): put_word(output, 8*(i+1), records[i])
    return Int64(bytes)
