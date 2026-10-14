fn bucket_order_key(value: i64) -> u64 {
    let sign_bit = 1u64 << 63;
    if value < 0 {
        sign_bit - 1 - (-(value + 1)) as u64
    } else {
        sign_bit + value as u64
    }
}

fn bucket_sort_insertion(values: &mut [i64], low: usize, high: usize) {
    let mut index = low;
    if low < high {
        index += 1;
    }
    while index < high {
        let key = values[index];
        let mut position = index;
        while position > low && values[position - 1] > key {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = key;
        index += 1;
    }
}

/// Stable top-byte bucket sort for signed 64-bit values.
#[no_mangle]
pub extern "C" fn bucket_sort(values: *mut i64, scratch: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let scratch = unsafe { std::slice::from_raw_parts_mut(scratch, length + 256) };
    scratch[..256].fill(0);
    for index in 0..length {
        let bucket = (bucket_order_key(values[index]) >> 56) as usize;
        scratch[bucket] += 1;
    }
    let mut next = 0usize;
    for bucket in 0..256 {
        let count = scratch[bucket] as usize;
        scratch[bucket] = next as i64;
        next += count;
    }
    for index in 0..length {
        let bucket = (bucket_order_key(values[index]) >> 56) as usize;
        let destination = scratch[bucket] as usize;
        scratch[bucket] += 1;
        scratch[256 + destination] = values[index];
    }
    let mut low = 0usize;
    for bucket in 0..256 {
        let high = scratch[bucket] as usize;
        bucket_sort_insertion(&mut scratch[256..(256 + length)], low, high);
        low = high;
    }
    values.copy_from_slice(&scratch[256..(256 + length)]);
}
