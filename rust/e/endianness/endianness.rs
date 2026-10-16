/// Dispatch the seven pinned Python endianness helpers.
fn signed_u64(bits: u64) -> i64 {
    if bits <= i64::MAX as u64 { bits as i64 } else { -1 - (u64::MAX - bits) as i64 }
}

fn swap_bytes(mut bits: u64, count: usize) -> u64 {
    let mut reversed = 0u64;
    for _ in 0..count {
        reversed = (reversed << 8) | (bits & 0xff);
        bits >>= 8;
    }
    reversed
}

#[no_mangle]
pub unsafe extern "C" fn endianness(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 { return -1; }
    let operation = *input;
    if (0..=2).contains(&operation) {
        if length != 2 { return -1; }
        let value = *input.add(1);
        if operation == 0 {
            if !(0..=65535).contains(&value) { return -1; }
            return swap_bytes(value as u64, 2) as i64;
        }
        if operation == 1 {
            if value < 0 || value as u64 > 0xffff_ffff { return -1; }
            return swap_bytes(value as u64, 4) as i64;
        }
        return signed_u64(swap_bytes(value as u64, 8));
    }
    if operation == 3 || operation == 4 {
        if length < 3 { return -1; }
        let count = *input.add(1);
        if !(1..=8).contains(&count) || length != count as usize + 2 { return -1; }
        let mut result = 0u64;
        for index in 0..count as usize {
            let byte = *input.add(index + 2);
            if !(0..=255).contains(&byte) { return -1; }
            let shift = if operation == 3 { 8 * index } else { 8 * (count as usize - 1 - index) };
            result |= (byte as u64) << shift;
        }
        return signed_u64(result);
    }
    if operation == 5 || operation == 6 {
        if length != 3 { return -1; }
        let value_signed = *input.add(1);
        let count = *input.add(2);
        if !(1..=8).contains(&count) { return -1; }
        let value = value_signed as u64;
        if count < 8 && (value_signed < 0 || (value >> (8 * count as usize)) != 0) { return -1; }
        return signed_u64(if operation == 5 { value } else { swap_bytes(value, count as usize) });
    }
    -1
}
