const INVALID_RESULT: f64 = -1.0e300;
const MAX_INPUT_LENGTH: usize = 144;
const MAX_ROWS: i64 = 32;
const MAX_DIMENSIONS: i64 = 4;
const MAX_CLUSTERS: i64 = 8;
const MAX_ITERATIONS: i64 = 64;

#[no_mangle]
pub unsafe extern "C" fn kmeans_raw_r(values: *const i64, length: usize) -> f64 {
    if values.is_null() || !(12..=MAX_INPUT_LENGTH).contains(&length) {
        return INVALID_RESULT;
    }
    let rows_value = *values;
    let dimensions_value = *values.add(1);
    let clusters_value = *values.add(2);
    let iteration_limit_value = *values.add(3);
    if !(2..=MAX_ROWS).contains(&rows_value)
        || !(2..=MAX_DIMENSIONS).contains(&dimensions_value)
        || !(1..=MAX_CLUSTERS).contains(&clusters_value)
        || clusters_value > rows_value / 2
        || !(1..=MAX_ITERATIONS).contains(&iteration_limit_value)
    {
        return INVALID_RESULT;
    }

    let rows = rows_value as usize;
    let dimensions = dimensions_value as usize;
    let clusters = clusters_value as usize;
    let iteration_limit = iteration_limit_value as usize;
    let data_count = rows * dimensions;
    let data_start = 4 + clusters;
    let selector_start = data_start + data_count;
    if length != selector_start + 3 {
        return INVALID_RESULT;
    }

    let mut data = [0.0f64; 32 * 4];
    for cluster in 0..clusters {
        let initial_row = *values.add(4 + cluster);
        if initial_row < 0 || initial_row >= rows_value {
            return INVALID_RESULT;
        }
        for earlier in 0..cluster {
            if *values.add(4 + earlier) == initial_row {
                return INVALID_RESULT;
            }
        }
    }
    for index in 0..data_count {
        let coordinate = *values.add(data_start + index);
        if !(-64..=64).contains(&coordinate) {
            return INVALID_RESULT;
        }
        data[index] = coordinate as f64;
    }

    let field = *values.add(selector_start);
    let arg0 = *values.add(selector_start + 1);
    let arg1 = *values.add(selector_start + 2);
    if !(0..=2).contains(&field) {
        return INVALID_RESULT;
    }
    if field == 0 && (arg0 < 0 || arg0 >= clusters_value || arg1 < 0 || arg1 >= dimensions_value) {
        return INVALID_RESULT;
    }
    if field == 1 && (arg0 < 0 || arg0 >= rows_value || arg1 < 0 || arg1 >= clusters_value) {
        return INVALID_RESULT;
    }
    if field == 2 && (arg0 < 0 || arg0 >= rows_value || arg1 != 0) {
        return INVALID_RESULT;
    }

    let mut centers = [0.0f64; 8 * 4];
    for cluster in 0..clusters {
        let initial_row = *values.add(4 + cluster) as usize;
        for dimension in 0..dimensions {
            centers[cluster * dimensions + dimension] = data[initial_row * dimensions + dimension];
        }
    }

    let mut distances = [[0.0f64; 8]; 32];
    let mut assignments = [0usize; 32];
    let mut stable = false;
    for _iteration in 0..iteration_limit {
        let mut member_counts = [0usize; 8];
        for row in 0..rows {
            let mut best_cluster = 0;
            for cluster in 0..clusters {
                let mut squared_distance = 0.0;
                for dimension in 0..dimensions {
                    let difference = data[row * dimensions + dimension]
                        - centers[cluster * dimensions + dimension];
                    squared_distance += difference * difference;
                }
                distances[row][cluster] = squared_distance.sqrt();
                if cluster > 0 && distances[row][cluster] < distances[row][best_cluster] {
                    best_cluster = cluster;
                }
            }
            assignments[row] = best_cluster;
            member_counts[best_cluster] += 1;
        }
        if member_counts[..clusters].iter().any(|&count| count < 2) {
            return INVALID_RESULT;
        }

        let mut updated = [0.0f64; 8 * 4];
        for row in 0..rows {
            let cluster = assignments[row];
            for dimension in 0..dimensions {
                updated[cluster * dimensions + dimension] += data[row * dimensions + dimension];
            }
        }
        stable = true;
        for cluster in 0..clusters {
            for dimension in 0..dimensions {
                let index = cluster * dimensions + dimension;
                updated[index] /= member_counts[cluster] as f64;
                if updated[index] != centers[index] {
                    stable = false;
                }
            }
        }
        centers[..clusters * dimensions].copy_from_slice(&updated[..clusters * dimensions]);
        if stable {
            break;
        }
    }
    if !stable {
        return INVALID_RESULT;
    }

    let row_or_cluster = arg0 as usize;
    let second = arg1 as usize;
    match field {
        0 => centers[row_or_cluster * dimensions + second],
        1 => distances[row_or_cluster][second],
        _ => assignments[row_or_cluster] as f64,
    }
}
