from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
from std.collections import List

@export("ary3")
fn ary3(length: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length < 1 or length > 4096: return -1
    let n = Int(length)
    var x = List[Int32](capacity=4096)
    var y = List[Int32](capacity=4096)
    for i in range(n):
        x.append(Int32(i+1))
        y.append(0)
    for _ in range(1000):
        var i = n
        while i > 0:
            i -= 1
            y[i] += x[i]
    var first = Int(y[0])
    var last = Int(y[n-1])
    var first_digits = List[UInt8](capacity=10)
    var last_digits = List[UInt8](capacity=10)
    while first > 0:
        first_digits.append(UInt8(48+first%10))
        first //= 10
    while last > 0:
        last_digits.append(UInt8(48+last%10))
        last //= 10
    let required = len(first_digits)+len(last_digits)+2
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    for i in range(len(first_digits)):
        output[i] = first_digits[len(first_digits)-1-i]
    output[len(first_digits)] = UInt8(32)
    for i in range(len(last_digits)):
        output[len(first_digits)+1+i] = last_digits[len(last_digits)-1-i]
    output[required-1] = UInt8(10)
    return Int64(required)
