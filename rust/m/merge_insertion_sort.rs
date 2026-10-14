const MAX_VALUES: usize = 256;
const MAX_PAIRS: usize = MAX_VALUES / 2;

unsafe fn sort_pairs(low: *mut i64, high: *mut i64, scratch_low: *mut i64,
                     scratch_high: *mut i64, count: usize) {
    let mut width = 1;
    while width < count {
        let mut start = 0;
        while start < count {
            let middle = (start + width).min(count);
            let end = (middle + width).min(count);
            let mut left = start;
            let mut right = middle;
            let mut output = start;
            while left < middle && right < end {
                let source = if *low.add(left) <= *low.add(right) {
                    let result = left; left += 1; result
                } else { let result = right; right += 1; result };
                *scratch_low.add(output) = *low.add(source);
                *scratch_high.add(output) = *high.add(source);
                output += 1;
            }
            while left < middle {
                *scratch_low.add(output) = *low.add(left);
                *scratch_high.add(output) = *high.add(left);
                left += 1; output += 1;
            }
            while right < end {
                *scratch_low.add(output) = *low.add(right);
                *scratch_high.add(output) = *high.add(right);
                right += 1; output += 1;
            }
            for index in start..end {
                *low.add(index) = *scratch_low.add(index);
                *high.add(index) = *scratch_high.add(index);
            }
            start += width * 2;
        }
        if width > count / 2 { break }
        width *= 2;
    }
}

unsafe fn binary_insert(values: *mut i64, length: &mut usize, item: i64) {
    let mut low = 0;
    let mut high = *length;
    while low < high {
        let middle = low + (high - low) / 2;
        if *values.add(middle) < item { low = middle + 1 } else { high = middle }
    }
    let mut index = *length;
    while index > low {
        *values.add(index) = *values.add(index - 1);
        index -= 1;
    }
    *values.add(low) = item;
    *length += 1;
}

#[no_mangle]
pub unsafe extern "C" fn merge_insertion_sort(values: *mut i64, length: usize) {
    if length > MAX_VALUES { return }
    let mut pair_low = [0_i64; MAX_PAIRS];
    let mut pair_high = [0_i64; MAX_PAIRS];
    let mut scratch_low = [0_i64; MAX_PAIRS];
    let mut scratch_high = [0_i64; MAX_PAIRS];
    let mut chain = [0_i64; MAX_VALUES];
    let pair_count = length / 2;
    for pair in 0..pair_count {
        let first = *values.add(pair * 2);
        let second = *values.add(pair * 2 + 1);
        if first <= second { pair_low[pair] = first; pair_high[pair] = second }
        else { pair_low[pair] = second; pair_high[pair] = first }
    }
    sort_pairs(pair_low.as_mut_ptr(), pair_high.as_mut_ptr(), scratch_low.as_mut_ptr(), scratch_high.as_mut_ptr(), pair_count);
    let mut chain_length = 0;
    for pair in 0..pair_count { chain[chain_length] = pair_low[pair]; chain_length += 1; }
    if pair_count > 0 { chain[chain_length] = pair_high[pair_count - 1]; chain_length += 1; }
    if length % 2 != 0 { binary_insert(chain.as_mut_ptr(), &mut chain_length, *values.add(length - 1)); }
    for pair in 0..pair_count.saturating_sub(1) { binary_insert(chain.as_mut_ptr(), &mut chain_length, pair_high[pair]); }
    for index in 0..length { *values.add(index) = chain[index]; }
}
