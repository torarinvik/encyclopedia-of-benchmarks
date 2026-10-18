const U53_MAX: i64 = 9_007_199_254_740_991;
const U53_DENOMINATOR: f64 = 9_007_199_254_740_992.0;

#[no_mangle]
pub unsafe extern "C" fn k_means_rust(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 10 || *input != 4 { return -1; }
    let max_iter = *input.add(1);
    if !(1..=16).contains(&max_iter) { return -1; }
    let draw0 = *input.add(2);
    let draw1 = *input.add(4);
    if *input.add(3) != 0 || *input.add(5) != 0 ||
        !(0..=U53_MAX).contains(&draw0) || !(0..=U53_MAX).contains(&draw1) || draw0 == draw1 {
        return -1;
    }

    let mut points = [0.0_f64; 4];
    for index in 0..4 {
        let coordinate = *input.add(index + 6);
        if !(-16..=16).contains(&coordinate) ||
            (index > 0 && *input.add(index + 5) >= coordinate) {
            return -1;
        }
        points[index] = coordinate as f64;
    }
    if *input.add(7) >= 0 || *input.add(8) <= 1 { return -1; }

    let mut centers = [
        [draw0 as f64 / U53_DENOMINATOR, 0.0],
        [draw1 as f64 / U53_DENOMINATOR, 0.0],
    ];
    let mut labels = [0_i64; 4];
    for _ in 0..max_iter {
        let mut sums = [[0.0_f64; 2]; 2];
        let mut counts = [0_usize; 2];
        for index in 0..4 {
            let dx0 = points[index] - centers[0][0];
            let dy0 = -centers[0][1];
            let dx1 = points[index] - centers[1][0];
            let dy1 = -centers[1][1];
            let distance0 = dx0 * dx0 + dy0 * dy0;
            let distance1 = dx1 * dx1 + dy1 * dy1;
            let cluster = if distance1 < distance0 { 1 } else { 0 };
            labels[index] = cluster as i64;
            sums[cluster][0] += points[index];
            sums[cluster][1] += 0.0;
            counts[cluster] += 1;
        }
        if counts[0] == 0 || counts[1] == 0 { return -1; }
        for cluster in 0..2 {
            centers[cluster][0] = sums[cluster][0] / counts[cluster] as f64;
            centers[cluster][1] = sums[cluster][1] / counts[cluster] as f64;
        }
    }

    let mut packed = 0_i64;
    for index in 0..4 { packed |= labels[index] << index; }
    packed
}
