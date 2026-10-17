const MAX_INPUT_LENGTH: usize = 84;
const MAX_POINTS: usize = 16;
const MAX_DIMENSION: usize = 4;
const MAX_CLUSTERS: usize = 4;

fn exact_integer(value: f64, minimum: i64, maximum: i64) -> Option<i64> {
    if !value.is_finite() || value.trunc() != value || value < minimum as f64 || value > maximum as f64 {
        return None;
    }
    Some(value as i64)
}

#[no_mangle]
pub unsafe extern "C" fn k_means_clust(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_INPUT_LENGTH { return -1; }
    let point_value = match exact_integer(*input, 1, MAX_POINTS as i64) { Some(value) => value, None => return -1 };
    let dimension_value = match exact_integer(*input.add(1), 1, MAX_DIMENSION as i64) { Some(value) => value, None => return -1 };
    let cluster_value = match exact_integer(*input.add(2), 1, MAX_CLUSTERS as i64) { Some(value) => value, None => return -1 };
    let point_count = point_value as usize;
    let dimension = dimension_value as usize;
    let cluster_count = cluster_value as usize;
    if cluster_count > point_count { return -1; }
    let data_start = 3;
    let centroid_start = data_start + point_count * dimension;
    let expected_length = centroid_start + cluster_count * dimension;
    if input_length != expected_length { return -1; }

    for index in data_start..expected_length {
        if exact_integer(*input.add(index), -16, 16).is_none() { return -1; }
    }
    let mut assignments = [0_usize; MAX_POINTS];
    let mut counts = [0_usize; MAX_CLUSTERS];
    let mut sums = [[0_i64; MAX_DIMENSION]; MAX_CLUSTERS];
    for point in 0..point_count {
        let mut best_cluster = 0;
        let mut best_distance = 0_i64;
        for feature in 0..dimension {
            let value = *input.add(data_start + point * dimension + feature) as i64;
            let center = *input.add(centroid_start + feature) as i64;
            let difference = value - center;
            best_distance += difference * difference;
        }
        for cluster in 1..cluster_count {
            let mut distance = 0_i64;
            for feature in 0..dimension {
                let value = *input.add(data_start + point * dimension + feature) as i64;
                let center = *input.add(centroid_start + cluster * dimension + feature) as i64;
                let difference = value - center;
                distance += difference * difference;
            }
            if distance < best_distance { best_distance = distance; best_cluster = cluster; }
        }
        assignments[point] = best_cluster;
        counts[best_cluster] += 1;
        for feature in 0..dimension {
            sums[best_cluster][feature] +=
                *input.add(data_start + point * dimension + feature) as i64;
        }
    }
    for cluster in 0..cluster_count { if counts[cluster] == 0 { return -1; } }
    let output_length = point_count + cluster_count * dimension;
    if output.is_null() || output_capacity < output_length { return -2; }
    for point in 0..point_count { *output.add(point) = assignments[point] as f64; }
    for cluster in 0..cluster_count {
        for feature in 0..dimension {
            *output.add(point_count + cluster * dimension + feature) =
                sums[cluster][feature] as f64 / counts[cluster] as f64;
        }
    }
    output_length as i64
}
