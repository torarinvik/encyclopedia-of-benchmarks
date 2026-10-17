const MAX_CITIES: usize = 10;
const MAX_MASKS: usize = 1024;
const MAX_STATES: usize = MAX_CITIES * MAX_MASKS;
const MAX_INPUT_VALUES: usize = 102;
const MAX_DISTANCE: i64 = 1_000;

fn solve(
    position: usize,
    mask: usize,
    city_count: usize,
    distances: &[i64; MAX_CITIES * MAX_CITIES],
    memo: &mut [i64; MAX_STATES],
    seen: &mut [bool; MAX_STATES],
) -> i64 {
    let all_visited = (1usize << city_count) - 1;
    if mask == all_visited {
        return distances[position * city_count];
    }
    let state = position * MAX_MASKS + mask;
    if seen[state] {
        return memo[state];
    }

    seen[state] = true;
    let mut best = i64::MAX;
    for city in 0..city_count {
        let bit = 1usize << city;
        if mask & bit == 0 {
            let cost = distances[position * city_count + city]
                + solve(city, mask | bit, city_count, distances, memo, seen);
            if cost < best {
                best = cost;
            }
        }
    }
    memo[state] = best;
    best
}

#[no_mangle]
pub unsafe extern "C" fn traveling_salesman_bitmask(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let city_count_value = values[0];
    if !(2..=MAX_CITIES as i64).contains(&city_count_value) {
        return -1;
    }
    let city_count = city_count_value as usize;
    if length != 1 + city_count * city_count {
        return -1;
    }

    let mut distances = [0i64; MAX_CITIES * MAX_CITIES];
    for index in 0..city_count * city_count {
        let distance = values[1 + index];
        if !(0..=MAX_DISTANCE).contains(&distance) {
            return -1;
        }
        if index / city_count == index % city_count && distance != 0 {
            return -1;
        }
        distances[index] = distance;
    }

    let mut memo = [0i64; MAX_STATES];
    let mut seen = [false; MAX_STATES];
    solve(0, 1, city_count, &distances, &mut memo, &mut seen)
}
