from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("backward_nondeterministic_dawg_match")
fn backward_nondeterministic_dawg_match(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 4161: return -2
    let nv = input[0]
    let mv = input[1]
    if nv < 0 or nv > 4096 or mv < 0 or mv > 63 or length != c_size_t(2 + nv + mv): return -2
    let n = Int(nv)
    let m = Int(mv)
    for i in range(n + m):
        if input[2 + i] < 97 or input[2 + i] > 122: return -2
    if m == 0: return 0
    if m > n: return -1
    var masks = List[UInt64](capacity=26)
    for _ in range(26): masks.append(UInt64(0))
    for i in range(m):
        let letter = Int(input[2 + n + i] - 97)
        masks[letter] = masks[letter] | (UInt64(1) << (m - 1 - i))
    var start = 0
    while start <= n - m:
        var remaining = m
        var shift = m
        var states = ~UInt64(0)
        while remaining > 0 and states != 0:
            remaining -= 1
            states = states & masks[Int(input[2 + start + remaining] - 97)]
            if states != 0:
                if remaining == 0: return Int64(start)
                shift = remaining
            states = states << 1
        start += shift
    return -1
