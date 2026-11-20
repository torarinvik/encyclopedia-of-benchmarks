from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("raita_search")
fn raita_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
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
        var shifts = InlineArray[Int, 128]()
        for byte in range(128):
            shifts[byte] = m
        for i in range(m - 1):
            shifts[Int(input[2 + n + i])] = m - i - 1
        let middle = m // 2
        var alignment = 0
        while alignment <= n - m:
            let last = Int(input[2 + alignment + m - 1])
            var matches = input[2 + n + m - 1] == Int64(last)
            if matches:
                matches = input[2 + n] == input[2 + alignment]
            if matches:
                matches = input[2 + n + middle] == input[2 + alignment + middle]
            if matches:
                var index = 1
                while index + 1 < m and matches:
                    if input[2 + n + index] != input[2 + alignment + index]:
                        matches = False
                    index += 1
                if matches:
                    positions[match_count] = Int64(alignment)
                    match_count += 1
            alignment += shifts[last]

    let output_bytes = match_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(output_bytes):
        return -2
    for i in range(match_count):
        var bits = UInt64(positions[i])
        for byte in range(8):
            output[i * 8 + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(output_bytes)
