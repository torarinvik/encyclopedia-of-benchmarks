from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("tsvc_s312_array_product")
fn tsvc_s312_array_product(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 49: return -1
    let n = input[0]
    if n < 0 or n > 48 or length != c_size_t(n + 1): return -1
    var product = Int64(1)
    for i in range(Int(n)):
        let value = input[i + 1]
        if value < 0 or value > 2: return -1
        product *= value
    return product
