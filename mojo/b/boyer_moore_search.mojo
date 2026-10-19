from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("boyer_moore_search")
fn boyer_moore_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 8194: return -1
    let nv = input[0]; let mv = input[1]
    if nv < 0 or nv > 4096 or mv < 0 or mv > 4096 or length != c_size_t(2 + nv + mv): return -1
    let n = Int(nv); let m = Int(mv); let p = 2 + n
    for i in range(n + m):
        if input[2 + i] < 0 or input[2 + i] > 127: return -1
    if m == 0: return 0
    if m > n: return -1
    var last = List[Int](capacity=128); for _ in range(128): last.append(-1)
    for i in range(m): last[Int(input[p + i])] = i
    var start = 0
    while start <= n - m:
        var k = m
        while k > 0 and input[p + k - 1] == input[2 + start + k - 1]: k -= 1
        if k == 0: return Int64(start)
        let byte = Int(input[2 + start + k - 1]); start += max(1, k - 1 - last[byte])
    return -1
