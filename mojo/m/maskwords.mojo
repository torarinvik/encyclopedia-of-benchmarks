from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn maskwords_matches(v: UnsafePointer[Int64, ImmutAnyOrigin], start: Int, length: Int, word: Int) -> Bool:
    let expected_length = 5 if word == 0 else 6
    if length != expected_length: return False
    if word == 0:
        let lower = InlineArray[Int, 5](98,105,114,100,115)
        let title = InlineArray[Int, 5](66,105,114,100,115)
        let upper = InlineArray[Int, 5](66,73,82,68,83)
        for i in range(5):
            if v[start+i] != lower[i] and v[start+i] != title[i] and v[start+i] != upper[i]: return False
    elif word == 1:
        let lower = InlineArray[Int, 6](109,97,114,107,101,116)
        let title = InlineArray[Int, 6](77,97,114,107,101,116)
        let upper = InlineArray[Int, 6](77,65,82,75,69,84)
        for i in range(6):
            if v[start+i] != lower[i] and v[start+i] != title[i] and v[start+i] != upper[i]: return False
    else:
        let lower = InlineArray[Int, 6](115,116,114,101,101,116)
        let title = InlineArray[Int, 6](83,116,114,101,101,116)
        let upper = InlineArray[Int, 6](83,84,82,69,69,84)
        for i in range(6):
            if v[start+i] != lower[i] and v[start+i] != title[i] and v[start+i] != upper[i]: return False
    return True

@export("maskwords")
fn maskwords(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 531: return -1
    let text_len = v[0]
    if text_len < 0 or text_len > 512: return -1
    let mask_len_index = 1 + Int(text_len)
    if mask_len_index >= Int(n): return -1
    let mask_len = v[mask_len_index]
    if mask_len < 0 or mask_len > 16 or Int(n) != mask_len_index + 1 + Int(mask_len): return -1
    for i in range(Int(text_len)):
        if v[i+1] < 1 or v[i+1] > 127: return -1
    for i in range(Int(mask_len)):
        if v[mask_len_index+1+i] < 32 or v[mask_len_index+1+i] > 126 or v[mask_len_index+1+i] == 92: return -1
    var staged = InlineArray[UInt8, 1447](fill=0); var written = 0
    if text_len > 0:
        var token_count = 1
        for i in range(Int(text_len)-1):
            if v[1+i] == 32: token_count += 1
        if v[Int(text_len)] == 32: token_count -= 1
        var start = 0
        for token in range(token_count):
            var end = start
            while end < Int(text_len) and v[1+end] != 32: end += 1
            if token > 0: staged[written] = 32; written += 1
            var matched = False
            for word in range(3):
                if maskwords_matches(v, start+1, end-start, word):
                    for j in range(Int(mask_len)): staged[written] = UInt8(v[mask_len_index+1+j]); written += 1
                    matched = True; break
            if not matched:
                for j in range(start, end):
                    if v[1+j] != 10: staged[written] = UInt8(v[1+j]); written += 1
            start = end + 1
    if out == UnsafePointer[UInt8, MutAnyOrigin]() and written > 0: return -2
    if cap < c_size_t(written): return -2
    for i in range(written): out[i] = staged[i]
    return Int64(written)
