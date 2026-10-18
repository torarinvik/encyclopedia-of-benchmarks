const MAX_CITIES: usize = 8;
const MAX_INPUT_LENGTH: usize = 66;
const JAVA_INT_MIN: i64 = i32::MIN as i64;
const JAVA_INT_MAX: i64 = i32::MAX as i64;
const MAX_EDGE_COST: i64 = 1_000;

fn evaluate_permutation(matrix: &[i64], city_count: usize, order: &[usize], best: &mut i64) {
    let mut cost = 0i64;
    let mut previous = 0usize;
    for &city in order.iter().take(city_count - 1) {
        let edge = matrix[previous * city_count + city];
        if edge == JAVA_INT_MAX {
            return;
        }
        cost += edge;
        previous = city;
    }
    let return_edge = matrix[previous * city_count];
    if return_edge == JAVA_INT_MAX {
        return;
    }
    cost += return_edge;
    if cost < *best {
        *best = cost;
    }
}

fn enumerate_permutations(
    matrix: &[i64],
    city_count: usize,
    order: &mut [usize],
    position: usize,
    best: &mut i64,
) {
    if position == city_count - 1 {
        evaluate_permutation(matrix, city_count, order, best);
        return;
    }
    for index in position..city_count - 1 {
        order.swap(position, index);
        enumerate_permutations(matrix, city_count, order, position + 1, best);
        order.swap(position, index);
    }
}

#[no_mangle]
pub unsafe extern "C" fn traveling_salesman(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let city_count_value = values[0];
    if !(0..=MAX_CITIES as i64).contains(&city_count_value) {
        return -1;
    }
    let city_count = city_count_value as usize;
    if length != 1 + city_count * city_count {
        return -1;
    }

    let matrix = &values[1..];
    if matrix.iter().any(|&value| !(JAVA_INT_MIN..=JAVA_INT_MAX).contains(&value)) {
        return -1;
    }
    if city_count <= 1 {
        return 0;
    }

    for row in 0..city_count {
        for column in 0..city_count {
            if row == column {
                continue;
            }
            let edge = matrix[row * city_count + column];
            if edge != JAVA_INT_MAX && !(0..=MAX_EDGE_COST).contains(&edge) {
                return -1;
            }
        }
    }

    let mut order = [0usize; MAX_CITIES - 1];
    for city in 1..city_count {
        order[city - 1] = city;
    }
    let mut best = JAVA_INT_MAX;
    enumerate_permutations(matrix, city_count, &mut order[..city_count - 1], 0, &mut best);
    best
}
