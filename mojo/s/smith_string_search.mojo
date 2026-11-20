from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("smith_string_search")
fn smith_string_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 322:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 0 or n_value > 255 or m_value < 1 or m_value > 64:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + n + m):
        return -1
    for i in range(n + m):
        if input[2 + i] < 0 or input[2 + i] > 127:
            return -1

    var positions = InlineArray[Int64, 255]()
    var match_count = 0
    if m <= n:
        var horspool = InlineArray[Int, 128]()
        var quick_search = InlineArray[Int, 128]()
        let pattern_start = 2 + n
        for byte in range(128):
            horspool[byte] = m
            quick_search[byte] = m + 1
        for i in range(m - 1):
            horspool[Int(input[pattern_start + i])] = m - i - 1
        for i in range(m):
            quick_search[Int(input[pattern_start + i])] = m - i

        var alignment = 0
        let last_alignment = n - m
        while alignment <= last_alignment:
            var matches = True
            for i in range(m):
                if input[pattern_start + i] != input[2 + alignment + i]:
                    matches = False
                    break
            if matches:
                positions[match_count] = Int64(alignment)
                match_count += 1
            let end_byte = Int(input[2 + alignment + m - 1])
            let lookahead = alignment + m
            var quick_shift = m + 1
            if lookahead < n:
                quick_shift = quick_search[Int(input[2 + lookahead])]
            let end_shift = horspool[end_byte]
            if end_shift > quick_shift:
                alignment += end_shift
            else:
                alignment += quick_shift

    let output_bytes = match_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(output_bytes):
        return -2
    for i in range(match_count):
        var bits = UInt64(positions[i])
        for byte in range(8):
            output[i * 8 + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(output_bytes)
