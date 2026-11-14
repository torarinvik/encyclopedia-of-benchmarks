from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("tsvc_s257_column_coupled_update")
fn tsvc_s257_column_coupled_update(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 12 or length > 138: return -1
    let n0 = input[0]
    let passes = input[1]
    if n0 < 2 or n0 > 8 or passes < 1 or passes > 4: return -1
    let n = Int(n0)
    let cells = n * n
    if length != c_size_t(2 + n + 2 * cells): return -1
    for i in range(2, 2 + n + 2 * cells):
        if input[i] < -1 or input[i] > 1: return -1
    var a = List[Int64](length=n, fill=0)
    var aa = List[Int64](length=cells, fill=0)
    for i in range(n):
        a[i] = input[2 + i]
    for i in range(cells):
        aa[i] = input[2 + n + i]
    for _ in range(Int(passes)):
        for col in range(1, n):
            for row in range(n):
                let cell = row * n + col
                a[col] = aa[cell] - a[col - 1]
                aa[cell] = a[col] + input[2 + n + cells + cell]
    var result: Int64 = 0
    for i in range(n): result += a[i]
    for i in range(cells): result += aa[i]
    return result
