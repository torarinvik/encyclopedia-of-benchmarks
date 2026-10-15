fn msd_order_key(value: i64) -> u64 {
    let sign_bit = 1u64 << 63;
    if value < 0 {
        sign_bit - 1 - (-(value + 1)) as u64
    } else {
        sign_bit + value as u64
    }
}

fn msd_sort_range(values: &mut [i64], begin: usize, end: usize, bit: i32) {
    if end - begin < 2 || bit < 0 {
        return;
    }
    let mut left = begin;
    let mut right = end;
    while left < right {
        while left < right && ((msd_order_key(values[left]) >> (bit as u32)) & 1) == 0 {
            left += 1;
        }
        while left < right && ((msd_order_key(values[right - 1]) >> (bit as u32)) & 1) != 0 {
            right -= 1;
        }
        if left < right {
            values.swap(left, right - 1);
            left += 1;
            right -= 1;
        }
    }
    msd_sort_range(values, begin, left, bit - 1);
    msd_sort_range(values, left, end, bit - 1);
}

/// In-place most-significant-bit radix sort for signed 64-bit values.
#[no_mangle]
pub extern "C" fn msd_radix_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    msd_sort_range(values, 0, length, 63);
}
