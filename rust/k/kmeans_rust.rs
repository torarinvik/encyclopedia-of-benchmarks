const MAX_MOVES: usize = 256;

#[no_mangle]
pub unsafe extern "C" fn kmeans_rust(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 10 { return -1; }
    let n_value = *input;
    if !(2..=8).contains(&n_value) { return -1; }
    let n = n_value as usize;
    if length != n + 1 { return -1; }

    let mut points = [0.0_f64; 8];
    for index in 0..n {
        let coordinate = *input.add(index + 1);
        if !(-16..=16).contains(&coordinate) || (index > 0 && *input.add(index) >= coordinate) { return -1; }
        points[index] = coordinate as f64;
    }

    let mut centers = [points[0], points[n / 2]];
    let mut labels = [0_i64; 8];
    for index in 0..n {
        let d0 = points[index] - centers[0];
        let d1 = points[index] - centers[1];
        if d1 * d1 < d0 * d0 { labels[index] = 1; }
    }

    for _ in 0..MAX_MOVES {
        let mut sums = [0.0_f64; 2];
        let mut counts = [0_usize; 2];
        for index in 0..n {
            let cluster = labels[index] as usize;
            sums[cluster] += points[index];
            counts[cluster] += 1;
        }
        if counts[0] == 0 || counts[1] == 0 { return -1; }
        centers[0] = sums[0] / counts[0] as f64;
        centers[1] = sums[1] / counts[1] as f64;

        let mut next_labels = [0_i64; 8];
        let mut unchanged = true;
        for index in 0..n {
            let d0 = points[index] - centers[0];
            let d1 = points[index] - centers[1];
            if d1 * d1 < d0 * d0 { next_labels[index] = 1; }
            if next_labels[index] != labels[index] { unchanged = false; }
        }
        if unchanged {
            let mut packed = 0_i64;
            for index in 0..n { packed |= next_labels[index] << index; }
            return packed;
        }
        labels = next_labels;
    }
    -2
}
