fn radix_order_key(value: i64) -> u64 {
    let sign_bit = 1u64 << 63;
    if value < 0 {
        sign_bit - 1 - (-(value + 1)) as u64
    } else {
        sign_bit + value as u64
    }
}

/// Stable LSD radix sort for signed 64-bit values.
#[no_mangle]
pub extern "C" fn radix_sort(values: *mut i64, scratch: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let scratch = unsafe { std::slice::from_raw_parts_mut(scratch, length + 256) };
    for pass in 0..8 {
        scratch[..256].fill(0);
        let shift = pass * 8;
        for index in 0..length {
            let bucket = ((radix_order_key(values[index]) >> shift) & 255) as usize;
            scratch[bucket] += 1;
        }
        let mut next = 0usize;
        for bucket in 0..256 {
            let count = scratch[bucket] as usize;
            scratch[bucket] = next as i64;
            next += count;
        }
        for index in 0..length {
            let bucket = ((radix_order_key(values[index]) >> shift) & 255) as usize;
            let destination = scratch[bucket] as usize;
            scratch[bucket] += 1;
            scratch[256 + destination] = values[index];
        }
        values.copy_from_slice(&scratch[256..(256 + length)]);
    }
}
