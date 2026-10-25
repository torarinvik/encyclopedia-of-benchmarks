const MAX_POINTS: i64 = 4;
const NUM_BINS: usize = 20;
const MAX_INPUT_LENGTH: usize = 26;
const PI_VALUE: f64 = 3.141592653589793238462643383279502884;

fn f32_from_raw(value: i64) -> f32 { (value as f32) / 1_000_000.0f32 }

#[no_mangle]
pub unsafe extern "C" fn parboil_tpacf_cross_correlation(
    input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 8 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let data_value = values[0];
    let random_value = values[1];
    if !(1..=MAX_POINTS).contains(&data_value) || !(1..=MAX_POINTS).contains(&random_value) { return -1; }
    let data_count = data_value as usize;
    let random_count = random_value as usize;
    if input_length != 2 + 3 * (data_count + random_count) || values[2..].iter().any(|v| !(-1_000_000..=1_000_000).contains(v)) { return -1; }
    if output.is_null() || output_capacity < NUM_BINS { return -2; }

    let mut boundaries = [0.0f32; NUM_BINS + 1];
    for k in 0..=NUM_BINS {
        let exponent = 1.0f64.log10() + (k as f64) * 1.0 / 5.0;
        let arcminutes = 10.0f64.powf(exponent);
        let radians = arcminutes / 60.0 * (PI_VALUE / 180.0);
        boundaries[k] = radians.cos() as f32;
    }
    let mut histogram = [0u8; NUM_BINS];
    let random_base = 2 + 3 * data_count;
    for j in 0..random_count {
        let rx = f32_from_raw(values[random_base + 3 * j]);
        let ry = f32_from_raw(values[random_base + 3 * j + 1]);
        let rz = f32_from_raw(values[random_base + 3 * j + 2]);
        for i in 0..data_count {
            let dx = f32_from_raw(values[2 + 3 * i]);
            let dy = f32_from_raw(values[2 + 3 * i + 1]);
            let dz = f32_from_raw(values[2 + 3 * i + 2]);
            let px = dx * rx; let py = dy * ry; let pz = dz * rz;
            let xy = px + py;
            let distance = xy + pz;
            let mut min = 0usize; let mut max = NUM_BINS;
            while max > min + 1 {
                let middle = (min + max) / 2;
                if distance >= boundaries[middle] { max = middle; } else { min = middle; }
            }
            if distance < boundaries[min] && distance >= boundaries[max] { histogram[max - 1] += 1; }
        }
    }
    std::slice::from_raw_parts_mut(output, NUM_BINS).copy_from_slice(&histogram);
    NUM_BINS as i64
}
