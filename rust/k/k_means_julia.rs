const MIN_POINTS: usize = 3;
const MAX_POINTS: usize = 8;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 10;
const MAX_MOVES: usize = 64;
const CENTER_SCALE: i64 = 256;
const CENTER_BIAS: i64 = 4097;
const CENTER_BASE: i64 = 8194;

#[no_mangle]
pub unsafe extern "C" fn k_means_julia(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < MIN_POINTS as i64 || values[0] > MAX_POINTS as i64 {
        return -1;
    }
    let point_count = values[0] as usize;
    if length != point_count + 1 {
        return -1;
    }

    let mut points = [0.0_f64; MAX_POINTS];
    for index in 0..point_count {
        let value = values[index + 1];
        if !(-16..=16).contains(&value) || (index > 0 && values[index] >= value) {
            return -1;
        }
        points[index] = value as f64;
    }

    let mut centers = [points[0], points[point_count / 2]];
    for _ in 0..MAX_MOVES {
        let mut sums = [0.0_f64; 2];
        let mut counts = [0_usize; 2];
        for &point in &points[..point_count] {
            let first_delta = point - centers[0];
            let second_delta = point - centers[1];
            let first_distance = (first_delta * first_delta).sqrt();
            let second_distance = (second_delta * second_delta).sqrt();
            let cluster = if second_distance < first_distance { 1 } else { 0 };
            sums[cluster] += point;
            counts[cluster] += 1;
        }
        if counts[0] == 0 || counts[1] == 0 {
            return -1;
        }
        let moved = [
            sums[0] / counts[0] as f64,
            sums[1] / counts[1] as f64,
        ];
        if moved[0] == centers[0] && moved[1] == centers[1] {
            let quantized_first = (moved[0] * CENTER_SCALE as f64) as i64;
            let quantized_second = (moved[1] * CENTER_SCALE as f64) as i64;
            let code_first = quantized_first + CENTER_BIAS;
            let code_second = quantized_second + CENTER_BIAS;
            if !(1..=8193).contains(&code_first) || !(1..=8193).contains(&code_second) {
                return -1;
            }
            return code_first * CENTER_BASE + code_second;
        }
        centers = moved;
    }
    -2
}
