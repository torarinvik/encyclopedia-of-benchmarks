from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tuned_boyer_moore_search")
fn tuned_boyer_moore_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
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
        var padded = InlineArray[UInt8, 319]()
        var shifts = InlineArray[Int, 128]()
        let pattern_start = 2 + n
        let final_byte = Int(input[pattern_start + m - 1])
        for i in range(n): padded[i] = UInt8(input[2 + i])
        for i in range(m): padded[n + i] = UInt8(final_byte)
        for byte in range(128): shifts[byte] = m
        for i in range(m - 1): shifts[Int(input[pattern_start + i])] = m - i - 1
        let final_shift = shifts[final_byte]
        shifts[final_byte] = 0

        var alignment = 0
        while alignment < n:
            var skip = shifts[Int(padded[alignment + m - 1])]
            while skip != 0:
                alignment += skip
                skip = shifts[Int(padded[alignment + m - 1])]
                alignment += skip
                skip = shifts[Int(padded[alignment + m - 1])]
                alignment += skip
                skip = shifts[Int(padded[alignment + m - 1])]
            var prefix_matches = True
            var index = 0
            while index + 1 < m and prefix_matches:
                if Int64(padded[alignment + index]) != input[pattern_start + index]:
                    prefix_matches = False
                index += 1
            if prefix_matches and alignment < n:
                positions[match_count] = Int64(alignment)
                match_count += 1
            alignment += final_shift

    let output_bytes = match_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(output_bytes):
        return -2
    for i in range(match_count):
        var bits = UInt64(positions[i])
        for byte in range(8):
            output[i * 8 + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(output_bytes)
