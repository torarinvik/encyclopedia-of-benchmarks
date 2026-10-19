from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("boyer_moore_ag")
fn boyer_moore_ag(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 512: return -1
    let nv = input[0]; let mv = input[1]
    if nv < 0 or nv > 255 or mv < 1 or mv > 255 or length != c_size_t(2 + nv + mv): return -1
    let n = Int(nv); let m = Int(mv); let p = 2 + n
    for i in range(n + m):
        if input[2 + i] < 0 or input[2 + i] > 127: return -1
    var shifts = List[Int](capacity=128); var present = List[Bool](capacity=128); var suffix = List[Int](capacity=256)
    for _ in range(128): shifts.append(0); present.append(False)
    for _ in range(256): suffix.append(0)
    for i in range(m - 1):
        let ch = Int(input[p + i]); shifts[ch] = m - i - 1; present[ch] = True
    for ch in range(128):
        if not present[ch]: continue
        let jump = shifts[ch]; var matched = 0
        while matched < m - jump and input[p + m - 1 - matched] == input[p + m - 1 - jump - matched]: matched += 1
        suffix[jump] = matched
    var positions = List[UInt8](capacity=255); var start = 0; var jump = m
    while start <= n - m:
        let skip = suffix[jump]; var idx = m - 1; var mismatch = False
        while idx >= 0:
            let off = idx
            if input[2 + start + off] != input[p + off]:
                let byte = Int(input[2 + start + off]); jump = shifts[byte] if present[byte] else m; start += jump; mismatch = True; break
            if off == m - jump: idx -= skip
            if idx == 0:
                positions.append(UInt8(start)); jump = 1; start += 1; mismatch = True; break
            idx -= 1
        if not mismatch: break
    if len(positions) > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(positions))): return -2
    for i in range(len(positions)): output[i] = positions[i]
    return Int64(len(positions))
