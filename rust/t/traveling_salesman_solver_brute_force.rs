const INVALID_RESULT: f64 = -1.0e300;
const MIN_CITIES: usize = 2;
const MAX_CITIES: usize = 8;
const MAX_INPUT_LENGTH: usize = 67;
const MAX_EDGE_COST: i64 = 1_000;

fn evaluate_route(
    matrix: &[i64],
    city_count: usize,
    order: &[usize],
    best_distance: &mut i64,
    best_route: &mut [usize; MAX_CITIES + 1],
) {
    let mut route = [0usize; MAX_CITIES + 1];
    route[0] = 0;
    for index in 0..city_count - 1 {
        route[index + 1] = order[index];
    }
    route[city_count] = 0;

    let mut distance = 0i64;
    for index in 0..city_count {
        distance += matrix[route[index] * city_count + route[index + 1]];
    }
    if distance < *best_distance {
        *best_distance = distance;
        best_route[..=city_count].copy_from_slice(&route[..=city_count]);
    }
}

fn enumerate_routes(
    matrix: &[i64],
    city_count: usize,
    order: &mut [usize],
    position: usize,
    used: &mut [bool; MAX_CITIES],
    best_distance: &mut i64,
    best_route: &mut [usize; MAX_CITIES + 1],
) {
    if position == city_count - 1 {
        evaluate_route(matrix, city_count, order, best_distance, best_route);
        return;
    }
    for city in 1..city_count {
        if used[city] {
            continue;
        }
        used[city] = true;
        order[position] = city;
        enumerate_routes(matrix, city_count, order, position + 1, used,
                          best_distance, best_route);
        used[city] = false;
    }
}

#[no_mangle]
pub unsafe extern "C" fn traveling_salesman_solver_brute_force(
    input: *const i64,
    length: usize,
) -> f64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let selector = values[0];
    let city_count_value = values[1];
    if city_count_value < MIN_CITIES as i64 || city_count_value > MAX_CITIES as i64 {
        return INVALID_RESULT;
    }
    let city_count = city_count_value as usize;
    if selector < 0 || selector > city_count as i64 + 1 || length != 2 + city_count * city_count {
        return INVALID_RESULT;
    }
    let matrix = &values[2..];
    if matrix.iter().any(|&edge| !(0..=MAX_EDGE_COST).contains(&edge)) {
        return INVALID_RESULT;
    }

    let mut order = [0usize; MAX_CITIES - 1];
    let mut used = [false; MAX_CITIES];
    used[0] = true;
    let mut best_distance = 8_001i64;
    let mut best_route = [0usize; MAX_CITIES + 1];
    enumerate_routes(
        matrix,
        city_count,
        &mut order[..city_count - 1],
        0,
        &mut used,
        &mut best_distance,
        &mut best_route,
    );
    if selector == 0 {
        best_distance as f64
    } else {
        best_route[(selector - 1) as usize] as f64
    }
}
