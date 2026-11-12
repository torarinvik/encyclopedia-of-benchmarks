const MAX_N: usize = 24;
const MAX_RUNS: usize = 144;

#[derive(Clone, Copy)]
struct Run { period: usize, left: usize, right: usize }

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { output[offset + byte] = ((bits >> (8 * byte)) & 0xff) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn runenumerate(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_N + 1 { return -1; }
    let n_value = *input;
    if n_value < 1 || n_value > MAX_N as i64 || length != n_value as usize + 1 { return -1; }
    let n = n_value as usize;
    let mut text = [0usize; MAX_N];
    for i in 0..n {
        let value = *input.add(i + 1);
        if !(0..26).contains(&value) { return -1; }
        text[i] = value as usize;
    }
    if output.is_null() { return -2; }

    let mut lcp = [[0usize; MAX_N + 1]; MAX_N + 1];
    for i in (0..n).rev() {
        for j in ((i + 1)..n).rev() {
            if text[i] == text[j] { lcp[i][j] = 1 + lcp[i + 1][j + 1]; }
        }
    }
    let mut runs = [Run { period: 0, left: 0, right: 0 }; MAX_RUNS];
    let mut count = 0usize;
    for period in 1..=n / 2 {
        let mut i = period;
        while i < n {
            if text[i] != text[i - period] { i += 1; continue; }
            let first = i;
            while i < n && text[i] == text[i - period] { i += 1; }
            let left = first - period;
            let right = i;
            if right - left < 2 * period { continue; }
            let mut minimal = true;
            for smaller in 1..period {
                if lcp[left][left + smaller] >= right - left - smaller {
                    minimal = false;
                    break;
                }
            }
            if minimal && count < MAX_RUNS {
                runs[count] = Run { period, left, right };
                count += 1;
            }
        }
    }
    runs[..count].sort_by_key(|run| (run.period, run.left, run.right));
    let needed = 8 + 24 * count;
    if capacity < needed { return -2; }
    let out = std::slice::from_raw_parts_mut(output, capacity);
    store_i64_le(out, 0, count as i64);
    for i in 0..count {
        let offset = 8 + 24 * i;
        store_i64_le(out, offset, runs[i].period as i64);
        store_i64_le(out, offset + 8, runs[i].left as i64);
        store_i64_le(out, offset + 16, runs[i].right as i64);
    }
    needed as i64
}
