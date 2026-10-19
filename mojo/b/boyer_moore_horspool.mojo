from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("boyer_moore_horspool")
fn boyer_moore_horspool(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 512: return -1
    let nv = input[0]; let mv = input[1]
    if nv < 0 or nv > 255 or mv < 0 or mv > 255 or length != c_size_t(2 + nv + mv): return -1
    let n = Int(nv); let m = Int(mv); let p = 2 + n
    for i in range(n + m):
        if input[2 + i] < 0 or input[2 + i] > 127: return -1
    var shifts = List[Int](capacity=128); for _ in range(128): shifts.append(m if m > 0 else 1)
    for i in range(max(0, m - 1)): shifts[Int(input[p + i])] = m - 1 - i
    var positions = List[UInt8](capacity=256)
    if m == 0:
        for i in range(n + 1): positions.append(UInt8(i))
    elif m <= n:
        var start = 0
        while start <= n - m:
            var k = m - 1
            while k >= 0 and input[p + k] == input[2 + start + k]: k -= 1
            if k < 0: positions.append(UInt8(start)); start += 1
            else: start += shifts[Int(input[2 + start + m - 1])]
    if len(positions) > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(positions))): return -2
    for i in range(len(positions)): output[i] = positions[i]
    return Int64(len(positions))
