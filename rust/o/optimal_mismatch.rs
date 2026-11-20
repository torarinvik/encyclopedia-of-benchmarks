const MAX_TEXT: usize = 256;
const MAX_PATTERN: usize = 16;
const MAX_INPUT: usize = 274;

#[no_mangle]
pub unsafe extern "C" fn optimal_mismatch(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT { return -2; }
    let raw_n = *values;
    let raw_m = *values.add(1);
    if raw_n < 0 || raw_n > MAX_TEXT as i64 || raw_m < 1 || raw_m > MAX_PATTERN as i64 {
        return -2;
    }
    let n = raw_n as usize;
    let m = raw_m as usize;
    if length != 2 + n + m { return -2; }
    let pattern_start = 2 + n;
    for i in 0..(n + m) {
        let byte = *values.add(2 + i);
        if !(0..=127).contains(&byte) { return -2; }
    }
    if m > n { return -1; }

    let mut frequency = [0usize; 128];
    for i in 0..n { frequency[*values.add(2 + i) as usize] += 1; }
    let mut order = [0usize; 16];
    for i in 0..m { order[i] = i; }
    for i in 1..m {
        let selected = order[i];
        let mut cursor = i;
        while cursor > 0 {
            let previous = order[cursor - 1];
            let pf = frequency[*values.add(pattern_start + previous) as usize];
            let sf = frequency[*values.add(pattern_start + selected) as usize];
            if pf < sf || (pf == sf && previous > selected) { break; }
            order[cursor] = previous;
            cursor -= 1;
        }
        order[cursor] = selected;
    }

    let mut quick_shift = [m + 1; 128];
    for i in 0..m {
        quick_shift[*values.add(pattern_start + i) as usize] = m - i;
    }
    let mut adapted_shift = [m; 16];
    for rank in 0..m {
        let mismatch = order[rank];
        for shift in 1..=m {
            let mut compatible = true;
            for prior in 0..rank {
                let position = order[prior];
                if position >= shift &&
                    *values.add(pattern_start + position) != *values.add(pattern_start + position - shift) {
                    compatible = false;
                    break;
                }
            }
            if !compatible { continue; }
            if mismatch >= shift &&
                *values.add(pattern_start + mismatch - shift) == *values.add(pattern_start + mismatch) {
                continue;
            }
            adapted_shift[rank] = shift;
            break;
        }
    }

    let mut start = 0usize;
    let last_start = n - m;
    while start <= last_start {
        let mut rank = 0usize;
        while rank < m &&
            *values.add(2 + start + order[rank]) == *values.add(pattern_start + order[rank]) {
            rank += 1;
        }
        if rank == m { return start as i64; }
        if start + m == n { break; }
        let quick = quick_shift[*values.add(2 + start + m) as usize];
        start += adapted_shift[rank].max(quick);
    }
    -1
}
