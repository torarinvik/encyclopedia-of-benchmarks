fn squared_distance(coordinates: &[i64; 128], dimension: usize,
                    row: usize, center: usize) -> i64 {
    let mut distance = 0i64;
    for axis in 0..dimension {
        let difference = coordinates[row * dimension + axis]
                       - coordinates[center * dimension + axis];
        distance += difference * difference;
    }
    distance
}

fn row_is_selected(centers: &[i64; 8], count: usize, row: i64) -> bool {
    centers[..count].contains(&row)
}

#[no_mangle]
pub unsafe extern "C" fn kmeans_plus_plus_seeding(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > 140 {
        return -1;
    }
    let point_count_value = *input;
    let dimension_value = *input.add(1);
    let center_count_value = *input.add(2);
    let first_row = *input.add(3);
    if !(1..=32).contains(&point_count_value)
        || !(1..=4).contains(&dimension_value)
        || !(1..=8).contains(&center_count_value)
        || center_count_value > point_count_value
        || first_row < 0
        || first_row >= point_count_value
    {
        return -1;
    }

    let point_count = point_count_value as usize;
    let dimension = dimension_value as usize;
    let center_count = center_count_value as usize;
    let coordinate_count = point_count * dimension;
    let draw_offset = 4 + coordinate_count;
    if length != draw_offset + center_count - 1 {
        return -1;
    }

    let mut coordinates = [0i64; 128];
    for index in 0..coordinate_count {
        let coordinate = *input.add(4 + index);
        if !(-16..=16).contains(&coordinate) {
            return -1;
        }
        coordinates[index] = coordinate;
    }

    let mut centers = [0i64; 8];
    let mut nearest = [0i64; 32];
    centers[0] = first_row;
    for row in 0..point_count {
        nearest[row] = squared_distance(&coordinates, dimension, row, first_row as usize);
    }

    for step in 0..(center_count - 1) {
        let draw = *input.add(draw_offset + step);
        let total_weight: i64 = nearest[..point_count].iter().sum();
        let chosen: i64;
        if total_weight == 0 {
            if draw != 0 {
                return -1;
            }
            let Some(row) = (0..point_count)
                .find(|&row| !row_is_selected(&centers, step + 1, row as i64))
            else {
                return -1;
            };
            chosen = row as i64;
        } else {
            if draw < 0 || draw >= total_weight {
                return -1;
            }
            let mut cumulative = 0i64;
            let mut selected_row = None;
            for row in 0..point_count {
                cumulative += nearest[row];
                if cumulative > draw {
                    selected_row = Some(row as i64);
                    break;
                }
            }
            let Some(row) = selected_row else {
                return -1;
            };
            chosen = row;
        }

        centers[step + 1] = chosen;
        for row in 0..point_count {
            let distance = squared_distance(&coordinates, dimension, row, chosen as usize);
            if distance < nearest[row] {
                nearest[row] = distance;
            }
        }
    }

    let output_bytes = center_count * 8;
    if output.is_null() || output_capacity < output_bytes {
        return -2;
    }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    for index in 0..center_count {
        output_slice[index * 8..index * 8 + 8]
            .copy_from_slice(&centers[index].to_le_bytes());
    }
    output_bytes as i64
}
