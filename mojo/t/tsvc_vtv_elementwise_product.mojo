# Independent bounded TSVC vtv profile; see package rights note.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_vtv_elementwise_product")
fn tsvc_vtv_elementwise_product(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 66: return -1
    let count = input[0]
    let passes = input[1]
    if count < 1 or count > 32 or passes < 1 or passes > 8 or length != c_size_t(2 + 2 * count): return -1
    let n = Int(count)
    var a = InlineArray[Float64, 32](fill=0.0)
    var b = InlineArray[Float64, 32](fill=0.0)
    for i in range(n):
        let av = input[2 + i]
        let bv = input[2 + n + i]
        if av < -2 or av > 2 or bv < -2 or bv > 2: return -1
        a[i] = Float64(av)
        b[i] = Float64(bv)
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for _ in range(Int(passes)):
        for i in range(n): a[i] *= b[i]
    for i in range(n):
        var bits = bitcast[UInt64](Int64(a[i]))
        for byte in range(8):
            output[8 * i + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
