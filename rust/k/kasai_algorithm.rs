const MAX_LENGTH: usize = 512;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

fn fnv_word(mut hash: u64, value: i64) -> u64 {
    let bits = value as u64;
    for byte in 0..8 {
        hash ^= (bits >> (8 * byte)) & 0xff;
        hash = hash.wrapping_mul(FNV_PRIME);
    }
    hash
}

#[no_mangle]
pub unsafe extern "C" fn kasai_algorithm(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    if values[0] < 0 || values[0] > MAX_LENGTH as i64 {
        return -1;
    }
    let n = values[0] as usize;
    if length != 1 + 2 * n {
        return -1;
    }
    if values[1..1 + n].iter().any(|&byte| !(0..=127).contains(&byte)) {
        return -1;
    }

    let mut suffixes = [0usize; MAX_LENGTH];
    let mut rank = [0usize; MAX_LENGTH];
    let mut seen = [false; MAX_LENGTH];
    let mut lcp = [0i64; MAX_LENGTH];
    for position in 0..n {
        let suffix_value = values[1 + n + position];
        if suffix_value < 0 || suffix_value as u64 >= n as u64 {
            return -1;
        }
        let suffix = suffix_value as usize;
        if seen[suffix] {
            return -1;
        }
        seen[suffix] = true;
        suffixes[position] = suffix;
        rank[suffix] = position;
    }

    for position in 1..n {
        let left = suffixes[position - 1];
        let right = suffixes[position];
        let left_tail_rank = if left + 1 < n { rank[left + 1] as i64 } else { -1 };
        let right_tail_rank = if right + 1 < n { rank[right + 1] as i64 } else { -1 };
        let left_byte = values[1 + left];
        let right_byte = values[1 + right];
        if left_byte > right_byte || (left_byte == right_byte && left_tail_rank >= right_tail_rank) {
            return -1;
        }
    }

    let mut common = 0;
    for start in 0..n {
        let current_rank = rank[start];
        if current_rank == n - 1 {
            common = 0;
            continue;
        }
        let next_start = suffixes[current_rank + 1];
        while start + common < n && next_start + common < n
            && values[1 + start + common] == values[1 + next_start + common]
        {
            common += 1;
        }
        lcp[current_rank] = common as i64;
        if common > 0 {
            common -= 1;
        }
    }

    let mut hash = fnv_word(FNV_OFFSET_BASIS, n as i64);
    for &value in &lcp[..n] {
        hash = fnv_word(hash, value);
    }
    (hash & i64::MAX as u64) as i64
}
