const INVALID_RESULT: f64 = -1.0e300;
const MIN_CITIES: usize = 1;
const MAX_CITIES: usize = 8;
const MAX_INPUT_LENGTH: usize = 68;
const MAX_EDGE_COST: i64 = 1_000;

#[no_mangle]
pub unsafe extern "C" fn traveling_salesman_solver_nearest_neighbor(
    input: *const i64,
    length: usize,
) -> f64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let selector = values[0];
    let city_count_value = values[1];
    let start_value = values[2];
    if city_count_value < MIN_CITIES as i64 || city_count_value > MAX_CITIES as i64 {
        return INVALID_RESULT;
    }
    let city_count = city_count_value as usize;
    if selector < 0
        || selector > city_count as i64 + 1
        || start_value < 0
        || start_value >= city_count_value
        || length != 3 + city_count * city_count
    {
        return INVALID_RESULT;
    }
    let matrix = &values[3..];
    if matrix.iter().any(|&edge| !(0..=MAX_EDGE_COST).contains(&edge)) {
        return INVALID_RESULT;
    }

    let mut route = [0usize; MAX_CITIES + 1];
    let mut visited = [false; MAX_CITIES];
    let start = start_value as usize;
    let mut current = start;
    route[0] = start;
    visited[start] = true;
    let mut total_distance = 0i64;

    for step in 1..city_count {
        let mut minimum_distance = 1_001i64;
        let mut next_city = MAX_CITIES;
        for city in 0..city_count {
            if !visited[city] {
                let distance = matrix[current * city_count + city];
                if distance < minimum_distance {
                    minimum_distance = distance;
                    next_city = city;
                }
            }
        }
        if next_city == MAX_CITIES {
            return INVALID_RESULT;
        }
        route[step] = next_city;
        visited[next_city] = true;
        total_distance += minimum_distance;
        current = next_city;
    }
    total_distance += matrix[current * city_count + start];
    route[city_count] = start;

    if selector == 0 {
        total_distance as f64
    } else {
        route[(selector - 1) as usize] as f64
    }
}
