from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("boyer_moore")
fn boyer_moore(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 8194: return -1
    let nv = input[0]; let mv = input[1]
    if nv < 0 or nv > 4096 or mv < 0 or mv > 4096 or length != c_size_t(2 + nv + mv): return -1
    let n = Int(nv); let m = Int(mv)
    for i in range(n + m):
        if input[2 + i] < 0 or input[2 + i] > 126: return -1
    if m == 0: return 0
    if m > n: return -1
    var last = List[Int](capacity=127); for _ in range(127): last.append(-1)
    for i in range(m): last[Int(input[2 + n + i])] = i
    var shift = List[Int](capacity=m + 1); var border = List[Int](capacity=m + 1)
    for _ in range(m + 1): shift.append(0); border.append(0)
    var i = m; var j = m + 1; border[i] = j
    while i > 0:
        while j <= m and input[2 + n + i - 1] != input[2 + n + j - 1]:
            if shift[j] == 0: shift[j] = j - i
            j = border[j]
        i -= 1; j -= 1; border[i] = j
    j = border[0]
    for i in range(m + 1):
        if shift[i] == 0: shift[i] = j
        if i == j: j = border[j]
    var align = 0
    while align <= n - m:
        var k = m - 1
        while k >= 0 and input[2 + n + k] == input[2 + align + k]: k -= 1
        if k < 0: return Int64(align)
        let bad = max(1, k - last[Int(input[2 + align + k])])
        align += max(bad, shift[k + 1])
    return -1
