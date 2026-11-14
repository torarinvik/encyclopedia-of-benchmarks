from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("kmp_slp_jump_output")
fn kmp_slp_jump_output(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 8 or length > 53: return -1
    let plen_raw = input[0]
    if plen_raw < 1 or plen_raw > 6: return -1
    let plen = Int(plen_raw)
    if 1 + plen >= Int(length): return -1
    var pattern = InlineArray[Int64, 6](fill=0)
    for i in range(plen):
        pattern[i] = input[1 + i]
        if pattern[i] < 0 or pattern[i] > 3: return -1
    var cursor = 1 + plen
    let count_raw = input[cursor]
    cursor += 1
    if count_raw < 1 or count_raw > 12: return -1
    let count = Int(count_raw)
    if cursor + 3 * count + 1 > Int(length): return -1
    var kinds = InlineArray[Int, 12](fill=0)
    var left = InlineArray[Int, 12](fill=0)
    var right = InlineArray[Int, 12](fill=0)
    var symbols = InlineArray[Int64, 12](fill=0)
    var sizes = InlineArray[Int, 12](fill=0)
    for v in range(count):
        let kind = input[cursor]
        let a = input[cursor + 1]
        let b = input[cursor + 2]
        cursor += 3
        if kind == 0:
            if a < 0 or a > 3 or b != 0: return -1
            symbols[v] = a
            sizes[v] = 1
        elif kind == 1:
            if a < 0 or b < 0 or a >= Int64(v) or b >= Int64(v): return -1
            kinds[v] = 1
            left[v] = Int(a)
            right[v] = Int(b)
            sizes[v] = sizes[left[v]] + sizes[right[v]]
            if sizes[v] > 64: return -1
        else:
            return -1
    let factors_raw = input[cursor]
    cursor += 1
    if factors_raw < 1 or factors_raw > 8 or cursor + Int(factors_raw) != Int(length): return -1
    var factors = InlineArray[Int, 8](fill=0)
    var text_size = 0
    for i in range(Int(factors_raw)):
        let id = input[cursor + i]
        if id < 0 or id >= count_raw: return -1
        factors[i] = Int(id)
        text_size += sizes[factors[i]]
        if text_size > 64: return -1
    var failure = InlineArray[Int, 6](fill=0)
    var border = 0
    for i in range(1, plen):
        while border > 0 and pattern[i] != pattern[border]: border = failure[border - 1]
        if pattern[i] == pattern[border]: border += 1
        failure[i] = border
    var jump = InlineArray[Int, 72](fill=0)
    var masks = InlineArray[UInt64, 72](fill=0)
    for v in range(count):
        for state in range(plen):
            if kinds[v] == 0:
                var next = state
                while next > 0 and pattern[next] != symbols[v]: next = failure[next - 1]
                if pattern[next] == symbols[v]: next += 1
                if next == plen:
                    masks[v * 6 + state] = 1
                    next = failure[plen - 1]
                jump[v * 6 + state] = next
            else:
                let a = left[v]
                let b = right[v]
                let middle = jump[a * 6 + state]
                jump[v * 6 + state] = jump[b * 6 + middle]
                masks[v * 6 + state] = masks[a * 6 + state] | (masks[b * 6 + middle] << sizes[a])
    var state = 0
    var offset = 0
    var endings: UInt64 = 0
    for i in range(Int(factors_raw)):
        let v = factors[i]
        endings = endings | (masks[v * 6 + state] << offset)
        state = jump[v * 6 + state]
        offset += sizes[v]
    var words = InlineArray[Int64, 65](fill=0)
    var occurrences = 0
    for i in range(text_size):
        if ((endings >> i) & 1) != 0:
            if i + 1 < plen: return -1
            occurrences += 1
            words[occurrences] = Int64(i + 1 - plen)
    words[0] = Int64(occurrences)
    let bytes = 8 * (occurrences + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(occurrences + 1):
        for byte in range(8): output[8 * i + byte] = UInt8((words[i] >> (8 * byte)) & 255)
    return Int64(bytes)
