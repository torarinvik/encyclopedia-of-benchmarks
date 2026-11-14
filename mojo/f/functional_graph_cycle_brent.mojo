from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("functional_graph_cycle_brent")
fn functional_graph_cycle_brent(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 67: return -1
    let n = input[0]
    let start = input[1]
    if n < 1 or n > 64 or start < 0 or start >= n or length != c_size_t(n+2): return -1
    for i in range(n):
        if input[2+i] < 0 or input[2+i] >= n: return -1
    var checkpoint = start
    var moving = input[2+start]
    var power: Int64 = 1
    var period: Int64 = 1
    while checkpoint != moving:
        if power == period:
            checkpoint = moving
            power *= 2
            period = 0
        moving = input[2+moving]
        period += 1
    var left = start
    var right = start
    for _ in range(period): right = input[2+right]
    var tail: Int64 = 0
    while left != right:
        left = input[2+left]
        right = input[2+right]
        tail += 1
    return 65 * tail + period
