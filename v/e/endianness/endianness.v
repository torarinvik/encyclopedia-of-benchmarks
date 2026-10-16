module endianness

const i64_max_u = u64(0x7fffffffffffffff)

fn signed_u64(bits u64) i64 {
    if bits <= i64_max_u { return i64(bits) }
    return -1 - i64(u64(0xffffffffffffffff) - bits)
}

fn swap_bytes(bits_input u64, count int) u64 {
    mut bits := bits_input
    mut reversed := u64(0)
    for _ in 0 .. count {
        reversed = (reversed << 8) | (bits & u64(0xff))
        bits >>= 8
    }
    return reversed
}

@[export: 'endianness']
pub fn endianness(input &i64, length usize) i64 {
    if input == nil || length == 0 { return -1 }
    operation := unsafe { input[0] }
    if operation >= 0 && operation <= 2 {
        if length != 2 { return -1 }
        value := unsafe { input[1] }
        if operation == 0 {
            if value < 0 || value > 65535 { return -1 }
            return i64(swap_bytes(u64(value), 2))
        }
        if operation == 1 {
            if value < 0 || u64(value) > u64(0xffffffff) { return -1 }
            return i64(swap_bytes(u64(value), 4))
        }
        return signed_u64(swap_bytes(u64(value), 8))
    }
    if operation == 3 || operation == 4 {
        count := unsafe { input[1] }
        if length < 3 || count < 1 || count > 8 || length != usize(count + 2) { return -1 }
        mut result := u64(0)
        for index in 0 .. int(count) {
            byte := unsafe { input[index + 2] }
            if byte < 0 || byte > 255 { return -1 }
            shift := if operation == 3 { 8 * index } else { 8 * (int(count) - 1 - index) }
            result |= u64(byte) << shift
        }
        return signed_u64(result)
    }
    if operation == 5 || operation == 6 {
        if length != 3 { return -1 }
        value_signed := unsafe { input[1] }
        count := unsafe { input[2] }
        if count < 1 || count > 8 { return -1 }
        value := u64(value_signed)
        if count < 8 && (value_signed < 0 || value >> (8 * int(count)) != 0) { return -1 }
        return signed_u64(if operation == 5 { value } else { swap_bytes(value, int(count)) })
    }
    return -1
}
