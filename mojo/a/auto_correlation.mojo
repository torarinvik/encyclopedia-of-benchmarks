from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn auto_corr_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8):
        output[offset + b] = UInt8((bits >> UInt(8 * b)) & 255)

@export("auto_correlation")
fn auto_correlation(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 65:
        return -1
    let count = values[0]
    if count < 1 or count > 64 or length != c_size_t(count + 1):
        return -1
    for i in range(Int(count)):
        if values[i + 1] < -1000000 or values[i + 1] > 1000000:
            return -1
    let nout = Int(2 * count - 1)
    let bytes = nout * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2
    var y_start = Int(count)
    for index in range(nout):
        if index < Int(count): y_start -= 1
        var k_min = 0
        if index >= Int(count) - 1: k_min = index - Int(count) + 1
        var k_max = index
        if index >= Int(count): k_max = Int(count) - 1
        var offset = 0
        var sum: Int64 = 0
        for k in range(k_min, k_max + 1):
            sum += values[k + 1] * values[y_start + offset + 1]
            offset += 1
        auto_corr_store(output, index * 8, sum)
    return Int64(bytes)
