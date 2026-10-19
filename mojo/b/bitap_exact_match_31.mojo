from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("bitap_exact_match_31")
fn bitap_exact_match_31(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 4129: return -2
    let tv = input[0]; let pv = input[1]
    if tv < 0 or tv > 4096 or pv < 0 or pv > 31 or length != c_size_t(2 + tv + pv): return -2
    let text_len = Int(tv); let pattern_len = Int(pv)
    for i in range(text_len + pattern_len):
        let ch = input[2 + i]
        if ch < 97 or ch > 122: return -2
    if pattern_len == 0: return 0
    if pattern_len > text_len: return -1
    var masks = List[UInt32](capacity=26)
    for _ in range(26): masks.append(UInt32(0xffffffff))
    for i in range(pattern_len):
        let ch = Int(input[2 + text_len + i] - 97)
        masks[ch] = masks[ch] & ~(UInt32(1) << i)
    var state = ~UInt32(1)
    for i in range(text_len):
        state = (state | masks[Int(input[2 + i] - 97)]) << 1
        if (state & (UInt32(1) << pattern_len)) == 0: return Int64(i - pattern_len + 1)
    return -1
