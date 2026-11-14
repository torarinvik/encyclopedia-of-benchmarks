from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s114_transposed_lower_triangle_update")
fn tsvc_s114_transposed_lower_triangle_update(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 9 or length > 513: return -1
    let n0 = input[0]
    if n0 < 2 or n0 > 16: return -1
    let n = Int(n0); let cells = n * n
    if length != c_size_t(1 + 2 * cells): return -1
    var a = List[Int64](length=cells, fill=0)
    for i in range(cells):
        let av = input[1 + i]; let bv = input[1 + cells + i]
        if av < -1_000_000 or av > 1_000_000 or bv < -1_000_000 or bv > 1_000_000: return -1
        a[i] = av
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * cells): return -2
    for i in range(n):
        for j in range(i): a[i * n + j] = a[j * n + i] + input[1 + cells + i * n + j]
    for i in range(cells):
        for byte in range(8): output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
    return Int64(cells)
