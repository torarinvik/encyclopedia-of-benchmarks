const MAX_CITIES: usize = 8;
const COORDINATE_LIMIT: f64 = 16.0;

#[no_mangle]
pub unsafe extern "C" fn travelling_salesman_python_bruteforce(
    input: *const f64,
    input_len: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=17).contains(&input_len) { return -1; }
    let values = std::slice::from_raw_parts(input, input_len);
    let raw_count = values[0];
    if !raw_count.is_finite() || !(2.0..=8.0).contains(&raw_count) || raw_count.fract() != 0.0 { return -1; }
    let city_count = raw_count as usize;
    if input_len != 1 + 2 * city_count { return -1; }

    let mut x = [0.0; MAX_CITIES];
    let mut y = [0.0; MAX_CITIES];
    for city in 0..city_count {
        x[city] = values[1 + 2 * city];
        y[city] = values[2 + 2 * city];
        if !x[city].is_finite() || !y[city].is_finite() ||
            x[city].abs() > COORDINATE_LIMIT || y[city].abs() > COORDINATE_LIMIT ||
            x[city].fract() != 0.0 || y[city].fract() != 0.0 { return -1; }
    }

    let permutation_len = city_count - 1;
    let mut order = [0usize; MAX_CITIES - 1];
    let mut best_order = [0usize; MAX_CITIES - 1];
    for i in 0..permutation_len { order[i] = i + 1; }
    let mut best_distance = f64::INFINITY;
    loop {
        let mut total = 0.0;
        let mut previous = 0;
        for i in 0..=permutation_len {
            let next = if i == permutation_len { 0 } else { order[i] };
            let dx = x[next] - x[previous];
            let dy = y[next] - y[previous];
            total += (dx * dx + dy * dy).sqrt();
            previous = next;
        }
        if total < best_distance {
            best_distance = total;
            best_order[..permutation_len].copy_from_slice(&order[..permutation_len]);
        }

        let mut i = permutation_len;
        while i > 1 && order[i - 2] >= order[i - 1] { i -= 1; }
        if i <= 1 { break; }
        let pivot = i - 2;
        let mut j = permutation_len - 1;
        while order[j] <= order[pivot] { j -= 1; }
        order.swap(pivot, j);
        order[i - 1..permutation_len].reverse();
    }

    let mut result = [0.0; 11];
    let path_len = city_count + 1;
    result[0] = path_len as f64;
    result[1] = 0.0;
    for i in 0..permutation_len { result[2 + i] = best_order[i] as f64; }
    result[path_len] = 0.0;
    result[path_len + 1] = best_distance;
    let required = city_count + 3;
    if output.is_null() || output_capacity < required { return -2; }
    for i in 0..required { *output.add(i) = result[i]; }
    required as i64
}
