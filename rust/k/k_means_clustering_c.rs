const MAX_MOVES: usize = 64;
const CENTER_SCALE: f64 = 256.0;
const CENTER_BIAS: i64 = 4097;
const CENTER_BASE: i64 = 8194;

#[no_mangle]
pub unsafe extern "C" fn k_means_clustering_c(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > 18 { return -1; }
    let n_value = *input;
    if !(3..=8).contains(&n_value) { return -1; }
    let n = n_value as usize;
    if length != 1 + 2 * n { return -1; }

    let mut labels = [0_i64; 8];
    let mut has_zero = false;
    let mut has_one = false;
    for index in 0..n {
        let label = *input.add(index + 1);
        let coordinate = *input.add(1 + n + index);
        if label != 0 && label != 1 { return -1; }
        labels[index] = label;
        has_zero |= label == 0;
        has_one |= label == 1;
        if !(-16..=16).contains(&coordinate) ||
            (index > 0 && *input.add(n + index) >= coordinate) {
            return -1;
        }
    }
    if !has_zero || !has_one { return -1; }

    for _ in 0..MAX_MOVES {
        let mut sums = [0.0_f64; 2];
        let mut counts = [0_usize; 2];
        for index in 0..n {
            let cluster = labels[index] as usize;
            sums[cluster] += *input.add(1 + n + index) as f64;
            counts[cluster] += 1;
        }
        if counts[0] == 0 || counts[1] == 0 { return -1; }
        let centers = [sums[0] / counts[0] as f64, sums[1] / counts[1] as f64];

        let mut next_labels = [0_i64; 8];
        let mut changed = 0;
        for index in 0..n {
            let point = *input.add(1 + n + index) as f64;
            let d0 = point - centers[0];
            let d1 = point - centers[1];
            if d1 * d1 < d0 * d0 { next_labels[index] = 1; }
            if next_labels[index] != labels[index] { changed += 1; }
        }
        labels = next_labels;
        if changed == 0 {
            let code0 = (centers[0] * CENTER_SCALE) as i64 + CENTER_BIAS;
            let code1 = (centers[1] * CENTER_SCALE) as i64 + CENTER_BIAS;
            if !(1..=8193).contains(&code0) || !(1..=8193).contains(&code1) { return -1; }
            return code0 * CENTER_BASE + code1;
        }
    }
    -2
}
