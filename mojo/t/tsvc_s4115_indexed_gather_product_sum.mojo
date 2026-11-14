from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("tsvc_s4115_indexed_gather_product_sum")
fn tsvc_s4115_indexed_gather_product_sum(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 193: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 64 or length != c_size_t(1 + 3 * n0): return -1
    let n = Int(n0)
    for i in range(n):
        let index = input[1 + i]; let a = input[1 + n + i]; let b = input[1 + 2 * n + i]
        if index < 0 or index >= n0 or a < 0 or a > 1_000_000 or b < 0 or b > 1_000_000: return -1
    var total = Int64(0)
    for i in range(n):
        total += input[1 + n + i] * input[1 + 2 * n + Int(input[1 + i])]
    return total
