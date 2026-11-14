from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("backward_oracle_match")
fn backward_oracle_match(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
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
    var next = List[Int](capacity=1664)
    var suffix = List[Int](capacity=64)
    for _ in range(1664): next.append(-1)
    for _ in range(64):
        suffix.append(-1)
    for i in range(m):
        let letter = Int(input[2 + n + m - 1 - i] - 97)
        next[i * 26 + letter] = i + 1
        var k = suffix[i]
        while k >= 0 and next[k * 26 + letter] < 0:
            next[k * 26 + letter] = i + 1
            k = suffix[k]
        if k < 0: suffix[i + 1] = 0
        else: suffix[i + 1] = next[k * 26 + letter]
    var start = 0
    while start <= n - m:
        var state = 0
        var remaining = m
        var shift = m
        while remaining > 0:
            remaining -= 1
            let letter = Int(input[2 + start + remaining] - 97)
            state = next[state * 26 + letter]
            if state < 0:
                shift = remaining + 1
                break
            if remaining == 0: return Int64(start)
        start += shift
    return -1
