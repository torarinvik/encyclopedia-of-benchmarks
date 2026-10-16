package endianness

import "core:c"

signed_u64 :: proc(bits: u64) -> i64 {
    if bits <= u64(0x7fffffffffffffff) do return i64(bits)
    return -1 - i64(u64(0xffffffffffffffff) - bits)
}

swap_bytes :: proc(bits_input: u64, count: int) -> u64 {
    bits := bits_input
    reversed: u64 = 0
    for _ in 0 ..< count {
        reversed = (reversed << 8) | (bits & 0xff)
        bits >>= 8
    }
    return reversed
}

@(export)
endianness :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 do return -1
    operation := input[0]
    if operation >= 0 && operation <= 2 {
        if length != 2 do return -1
        value := input[1]
        if operation == 0 {
            if value < 0 || value > 65535 do return -1
            return i64(swap_bytes(u64(value), 2))
        }
        if operation == 1 {
            if value < 0 || u64(value) > 0xffffffff do return -1
            return i64(swap_bytes(u64(value), 4))
        }
        return signed_u64(swap_bytes(u64(value), 8))
    }
    if operation == 3 || operation == 4 {
        if length < 3 || input[1] < 1 || input[1] > 8 || length != c.size_t(input[1] + 2) do return -1
        count := int(input[1])
        result: u64 = 0
        for index in 0 ..< count {
            byte := input[index + 2]
            if byte < 0 || byte > 255 do return -1
            shift := if operation == 3 do 8 * index else 8 * (count - 1 - index)
            result |= u64(byte) << shift
        }
        return signed_u64(result)
    }
    if operation == 5 || operation == 6 {
        if length != 3 || input[2] < 1 || input[2] > 8 do return -1
        count := int(input[2])
        value := u64(input[1])
        if count < 8 && (input[1] < 0 || (value >> (8 * count)) != 0) do return -1
        return signed_u64(if operation == 5 do value else swap_bytes(value, count))
    }
    return -1
}
