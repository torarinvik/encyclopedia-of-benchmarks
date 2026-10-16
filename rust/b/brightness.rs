const TRAINING: [(i64, i64, i64, i64); 11] = [
    (2, 99, 255, 1), (37, 44, 58, 0), (139, 169, 229, 1),
    (14, 255, 10, 1), (2, 28, 1, 0), (20, 33, 20, 0),
    (252, 227, 65, 1), (71, 65, 24, 0), (168, 80, 80, 1),
    (119, 35, 90, 0), (186, 13, 126, 1),
];

#[no_mangle]
pub unsafe extern "C" fn brightness(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values.iter().any(|&channel| !(0..=255).contains(&channel)) { return -1; }

    let mut best_distance = 195076_i64;
    let mut best_label = -1_i64;
    for &(red, green, blue, label) in &TRAINING {
        let red_delta = values[0] - red;
        let green_delta = values[1] - green;
        let blue_delta = values[2] - blue;
        let distance = red_delta * red_delta + green_delta * green_delta + blue_delta * blue_delta;
        if distance < best_distance {
            best_distance = distance;
            best_label = label;
        }
    }
    best_label
}
