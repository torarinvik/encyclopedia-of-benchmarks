const MAX_MOVES: usize = 64;
const CENTER_BIAS: i64 = 4097;
const CENTER_BASE: i64 = 8194;

#[no_mangle]
pub unsafe extern "C" fn k_means_clustering_zig(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 10 { return -1; }
    let point_value = *input;
    if !(2..=8).contains(&point_value) { return -1; }
    let point_count = point_value as usize;
    if length != point_count + 1 { return -1; }

    let mut points = [0.0_f32; 8];
    for index in 0..point_count {
        let coordinate = *input.add(index + 1);
        if !(-16..=16).contains(&coordinate) || (index > 0 && *input.add(index) >= coordinate) { return -1; }
        points[index] = coordinate as f32;
    }

    let mut centers = [points[0], points[1]];
    let mut old_counts = [0_usize; 2];
    for _ in 0..MAX_MOVES {
        let mut sums = [0.0_f32; 2];
        let mut counts = [0_usize; 2];
        for &point in &points[..point_count] {
            let first_delta = point - centers[0];
            let second_delta = centers[1] - point;
            let first_distance = first_delta * first_delta;
            let second_distance = second_delta * second_delta;
            let cluster = if second_distance < first_distance { 1 } else { 0 };
            sums[cluster] = sums[cluster] + point;
            counts[cluster] += 1;
        }
        if counts[0] == 0 || counts[1] == 0 { return -1; }
        let moved = [sums[0] / counts[0] as f32, sums[1] / counts[1] as f32];
        if moved[0] == centers[0] && moved[1] == centers[1] && counts == old_counts {
            let code0 = (moved[0] * 256.0_f32) as i64 + CENTER_BIAS;
            let code1 = (moved[1] * 256.0_f32) as i64 + CENTER_BIAS;
            if !(1..=8193).contains(&code0) || !(1..=8193).contains(&code1) { return -1; }
            return (code0 * CENTER_BASE + code1) * 81 + counts[0] as i64 * 9 + counts[1] as i64;
        }
        centers = moved;
        old_counts = counts;
    }
    -2
}
