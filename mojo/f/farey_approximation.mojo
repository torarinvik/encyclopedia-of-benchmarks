from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("farey_approximation")
fn farey_approximation(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let scaled = values[0]
    let repeat = values[1]
    if scaled < 1 or scaled > 999999 or repeat < 1 or repeat > 20: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    let decimal = Float64(scaled) / 1000000.0
    var a: Int64 = 0
    var b: Int64 = 1
    var c: Int64 = 1
    var d: Int64 = 1
    var num: Int64 = 0
    var den: Int64 = 0
    for i in range(repeat):
        num = a + c
        den = b + d
        if decimal > Float64(num) / Float64(den):
            a = num
            b = den
        else:
            c = num
            d = den
    var stage = InlineArray[Int64, 2](0)
    stage[0] = num
    stage[1] = den
    for i in range(2):
        let bits = UInt64(stage[i])
        for j in range(8): output[i * 8 + j] = UInt8((bits >> (8 * j)) & 255)
    return 16
