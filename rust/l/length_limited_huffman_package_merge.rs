const MAX_SYMBOLS: usize = 12;
const MAX_LEVELS: usize = 10;
const MAX_ITEMS: usize = 24;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 15;

#[no_mangle]
pub unsafe extern "C" fn length_limited_huffman_package_merge(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || !(4..=MAX_PARSEABLE_INPUT_LENGTH).contains(&length) {
        return -1;
    }
    let n_value = *input;
    let limit_value = *input.add(1);
    if !(2..=MAX_SYMBOLS as i64).contains(&n_value)
        || !(1..=6).contains(&limit_value)
        || n_value > (1i64 << limit_value as u32)
    {
        return -1;
    }
    let n = n_value as usize;
    let limit = limit_value as usize;
    if length != n + 2 {
        return -1;
    }

    let mut weights = [0i64; MAX_SYMBOLS];
    for i in 0..n {
        let weight = *input.add(i + 2);
        if !(0..=1_000_000).contains(&weight) {
            return -1;
        }
        weights[i] = weight;
    }
    weights[..n].sort_unstable();

    let mut lists = [[0i64; MAX_ITEMS]; MAX_LEVELS];
    let mut counts = [0usize; MAX_LEVELS];
    for level in 0..limit {
        lists[level][..n].copy_from_slice(&weights[..n]);
        counts[level] = n;
    }

    let mut remaining = ((n - 1) as i64) << limit;
    let mut total = 0i64;
    let mut level = 0usize;
    while remaining > 0 {
        while level < MAX_LEVELS && counts[level] == 0 {
            level += 1;
        }
        if level >= MAX_LEVELS {
            return -1;
        }

        let width = 1i64 << level;
        let needed = remaining & -remaining;
        if width > needed {
            return -1;
        }
        if width == needed {
            total += lists[level][0];
            let count = counts[level];
            lists[level].copy_within(1..count, 0);
            counts[level] -= 1;
            remaining -= width;
            if remaining == 0 {
                break;
            }
        }

        let package_count = counts[level] / 2;
        let mut packages = [0i64; MAX_ITEMS];
        for i in 0..package_count {
            packages[i] = lists[level][2 * i] + lists[level][2 * i + 1];
        }
        counts[level] = 0;

        let next_level = level + 1;
        if next_level >= MAX_LEVELS {
            return -1;
        }
        let mut merged = [0i64; MAX_ITEMS];
        let mut package_index = 0usize;
        let mut existing_index = 0usize;
        let mut merged_count = 0usize;
        while package_index < package_count && existing_index < counts[next_level] {
            if packages[package_index] <= lists[next_level][existing_index] {
                if merged_count >= MAX_ITEMS {
                    return -1;
                }
                merged[merged_count] = packages[package_index];
                package_index += 1;
            } else {
                if merged_count >= MAX_ITEMS {
                    return -1;
                }
                merged[merged_count] = lists[next_level][existing_index];
                existing_index += 1;
            }
            merged_count += 1;
        }
        while package_index < package_count {
            if merged_count >= MAX_ITEMS {
                return -1;
            }
            merged[merged_count] = packages[package_index];
            package_index += 1;
            merged_count += 1;
        }
        while existing_index < counts[next_level] {
            if merged_count >= MAX_ITEMS {
                return -1;
            }
            merged[merged_count] = lists[next_level][existing_index];
            existing_index += 1;
            merged_count += 1;
        }
        lists[next_level] = merged;
        counts[next_level] = merged_count;
        level = next_level;
    }

    total
}
