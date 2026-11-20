const MAX_N: usize = 64;
const MIN_VALUE: i64 = -1_000_000;
const MAX_VALUE: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn interpolation_sequential_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_N + 3 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    let target = values[1];
    if count_value < 0 || count_value > MAX_N as i64 || length != count_value as usize + 2
        || !(MIN_VALUE..=MAX_VALUE).contains(&target)
    {
        return -1;
    }
    let count = count_value as usize;
    let items = &values[2..];
    for i in 0..count {
        if !(MIN_VALUE..=MAX_VALUE).contains(&items[i])
            || (i > 0 && items[i - 1] >= items[i])
        {
            return -1;
        }
    }
    if count == 0 {
        return -1;
    }
    let first = items[0];
    let last = items[count - 1];
    if target < first || target > last {
        return -1;
    }
    if count == 1 {
        return if first == target { 0 } else { -1 };
    }

    let position = ((target - first) * (count as i64 - 1) / (last - first)) as usize;
    let estimated = items[position];
    if estimated == target {
        return position as i64;
    }
    if estimated < target {
        for i in position + 1..count {
            if items[i] >= target {
                return if items[i] == target { i as i64 } else { -1 };
            }
        }
    } else {
        let mut i = position;
        while i > 0 {
            i -= 1;
            if items[i] <= target {
                return if items[i] == target { i as i64 } else { -1 };
            }
        }
    }
    -1
}
