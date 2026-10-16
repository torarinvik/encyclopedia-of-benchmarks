#[no_mangle]
pub extern "C" fn maximum_sum_bst(input: *const i64, length: usize) -> i64 {
    const MAX_SLOTS: usize = 31;
    const MAX_VALUE: i64 = 1_000_000;
    const EMPTY_MIN: i64 = 1_000_001;
    if input.is_null() || length < 1 || length > MAX_SLOTS + 1 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 0 || input[0] > MAX_SLOTS as i64 || length != input[0] as usize + 1 { return -1; }
    let count = input[0] as usize;
    for i in 0..count {
        if input[i + 1] < -1 || input[i + 1] > MAX_VALUE { return -1; }
        if input[i + 1] != -1 && i > 0 && input[(i - 1) / 2 + 1] == -1 { return -1; }
    }
    if count == 0 { return 0; }
    let mut valid = [false; MAX_SLOTS];
    let mut minimum = [0_i64; MAX_SLOTS];
    let mut maximum = [0_i64; MAX_SLOTS];
    let mut sum = [0_i64; MAX_SLOTS];
    let mut best = [0_i64; MAX_SLOTS];
    for i in (0..count).rev() {
        if input[i + 1] == -1 { valid[i] = true; minimum[i] = EMPTY_MIN; maximum[i] = -1; continue; }
        let left = 2 * i + 1; let right = left + 1;
        let lv = left >= count || valid[left]; let rv = right >= count || valid[right];
        let lmax = if left < count { maximum[left] } else { -1 };
        let rmin = if right < count { minimum[right] } else { EMPTY_MIN };
        let lmin = if left < count { minimum[left] } else { EMPTY_MIN };
        let rmax = if right < count { maximum[right] } else { -1 };
        let lsum = if left < count { sum[left] } else { 0 };
        let rsum = if right < count { sum[right] } else { 0 };
        let lb = if left < count { best[left] } else { 0 };
        let rb = if right < count { best[right] } else { 0 };
        let value = input[i + 1];
        if lv && rv && lmax < value && value < rmin {
            valid[i] = true; minimum[i] = lmin.min(value); maximum[i] = rmax.max(value);
            sum[i] = lsum + rsum + value; best[i] = sum[i].max(lb).max(rb);
        } else { best[i] = lb.max(rb); }
    }
    best[0]
}
