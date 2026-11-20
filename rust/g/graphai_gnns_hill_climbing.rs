const MAX_N: usize = 16;
const MAX_D: usize = 4;
const MAX_INPUT: usize = 89;
const MAX_PARSEABLE: usize = 90;
const COORD_LIMIT: i64 = 100;
const DISTANCE_RADIX: i64 = 160_001;

#[no_mangle]
pub unsafe extern "C" fn graphai_gnns_hill_climbing(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 5 || length > MAX_PARSEABLE {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let d_value = values[1];
    let start_value = values[2];
    let e_value = values[3];
    let t_value = values[4];
    if !(2..=MAX_N as i64).contains(&n_value)
        || !(1..=MAX_D as i64).contains(&d_value)
        || start_value < 0 || start_value >= n_value
        || e_value < 1 || e_value >= n_value
        || !(0..=16).contains(&t_value)
    {
        return -1;
    }
    let n = n_value as usize;
    let d = d_value as usize;
    if length != 5 + n * d + n + d || length > MAX_INPUT {
        return -1;
    }

    let mut coordinates = [0i64; MAX_N * MAX_D];
    for index in 0..n * d {
        let coordinate = values[5 + index];
        if !(-COORD_LIMIT..=COORD_LIMIT).contains(&coordinate) {
            return -1;
        }
        coordinates[index] = coordinate;
    }
    let mask_offset = 5 + n * d;
    let valid_bits = (1i64 << n) - 1;
    let mut masks = [0i64; MAX_N];
    for vertex in 0..n {
        let mask = values[mask_offset + vertex];
        if mask < 0 || mask & !valid_bits != 0 || mask & (1i64 << vertex) != 0 {
            return -1;
        }
        masks[vertex] = mask;
    }
    let mut query = [0i64; MAX_D];
    for axis in 0..d {
        let coordinate = values[mask_offset + n + axis];
        if !(-COORD_LIMIT..=COORD_LIMIT).contains(&coordinate) {
            return -1;
        }
        query[axis] = coordinate;
    }

    let mut current = start_value as usize;
    let mut current_distance = 0i64;
    for axis in 0..d {
        let delta = coordinates[current * d + axis] - query[axis];
        current_distance += delta * delta;
    }
    let mut evaluations = 1i64;
    let mut moves = 0i64;
    for _ in 0..t_value {
        let mut best_vertex = current;
        let mut best_distance = current_distance;
        let mut inspected = 0i64;
        for vertex in 0..n {
            if masks[current] & (1i64 << vertex) == 0 {
                continue;
            }
            let mut distance = 0i64;
            for axis in 0..d {
                let delta = coordinates[vertex * d + axis] - query[axis];
                distance += delta * delta;
            }
            evaluations += 1;
            inspected += 1;
            if distance < best_distance || (distance == best_distance && vertex < best_vertex) {
                best_vertex = vertex;
                best_distance = distance;
            }
            if inspected == e_value {
                break;
            }
        }
        if best_distance >= current_distance {
            break;
        }
        current = best_vertex;
        current_distance = best_distance;
        moves += 1;
    }
    (((evaluations * 17 + moves) * 16 + current as i64) * DISTANCE_RADIX) + current_distance
}
