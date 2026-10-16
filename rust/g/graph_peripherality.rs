const MAX_VERTICES: usize = 8;
const MAX_EDGES: i64 = 56;
const INF: i64 = i64::MAX / 4;

fn put_i64(output: &mut [u8], word: usize, value: i64) {
    output[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn graph_peripherality(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let edge_value = values[1];
    if !(1..=8).contains(&n_value) || !(0..=MAX_EDGES).contains(&edge_value)
        || edge_value > n_value * (n_value - 1) || length != 2 + 3 * edge_value as usize { return -1; }
    let n = n_value as usize;
    let edge_count = edge_value as usize;
    let mut distance = [[INF; MAX_VERTICES]; MAX_VERTICES];
    for i in 0..n { distance[i][i] = 0; }
    for edge in 0..edge_count {
        let (source_value, destination_value, weight) = (values[2 + 3 * edge], values[3 + 3 * edge], values[4 + 3 * edge]);
        if source_value < 0 || source_value >= n_value || destination_value < 0 || destination_value >= n_value
            || source_value == destination_value || !(1..=1_000_000).contains(&weight) { return -1; }
        let (source, destination) = (source_value as usize, destination_value as usize);
        if distance[source][destination] != INF { return -1; }
        distance[source][destination] = weight;
    }
    for middle in 0..n {
        for source in 0..n {
            if distance[source][middle] == INF { continue; }
            for destination in 0..n {
                if distance[middle][destination] != INF {
                    let candidate = distance[source][middle] + distance[middle][destination];
                    if candidate < distance[source][destination] { distance[source][destination] = candidate; }
                }
            }
        }
    }
    if n > 1 {
        for source in 0..n {
            for destination in 0..n {
                if source != destination && distance[source][destination] == INF { return -1; }
            }
        }
    }
    let (mut peripheral, mut far) = (-1i64, -1i64);
    let (mut peripheral_infinite, mut far_infinite, mut any_reachable) = (false, false, false);
    let (mut best_eccentricity, mut best_farness) = (-1i64, -1i64);
    if n == 1 { peripheral = 0; far = 0; best_eccentricity = 0; best_farness = 0; }
    else {
        for source in 0..n {
            let (mut found, mut eccentricity, mut farness) = (false, 0i64, 0i64);
            for destination in 0..n {
                let value = distance[source][destination];
                if destination == source || value == INF || value == 0 { continue; }
                found = true;
                if value > eccentricity { eccentricity = value; }
                farness += value;
            }
            any_reachable |= found;
            let infinite = !found;
            if peripheral < 0 || (infinite && !peripheral_infinite) ||
                (infinite == peripheral_infinite && (infinite || eccentricity > best_eccentricity ||
                 (eccentricity == best_eccentricity && (source as i64) < peripheral))) {
                peripheral = source as i64; peripheral_infinite = infinite; best_eccentricity = eccentricity;
            }
            if far < 0 || (infinite && !far_infinite) ||
                (infinite == far_infinite && (infinite || farness > best_farness ||
                 (farness == best_farness && (source as i64) < far))) {
                far = source as i64; far_infinite = infinite; best_farness = farness;
            }
        }
        if !any_reachable { peripheral = -1; far = -1; best_eccentricity = -1; best_farness = -1; }
        else { if peripheral_infinite { best_eccentricity = -1; } if far_infinite { best_farness = -1; } }
    }
    if output.is_null() || capacity < 32 { return -2; }
    let destination = std::slice::from_raw_parts_mut(output, 32);
    put_i64(destination, 0, peripheral); put_i64(destination, 1, best_eccentricity);
    put_i64(destination, 2, far); put_i64(destination, 3, best_farness);
    32
}
