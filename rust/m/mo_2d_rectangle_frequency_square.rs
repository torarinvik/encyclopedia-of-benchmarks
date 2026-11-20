const MAX_SIDE: usize = 8;
const MAX_QUERIES: usize = 32;
const MAX_VALUE: usize = 7;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 195;

#[derive(Clone, Copy)]
struct RectangleQuery {
    top_block: usize,
    left_block: usize,
    bottom_block: usize,
    right_block: usize,
    top: usize,
    left: usize,
    bottom: usize,
    right: usize,
    ordinal: usize,
}

fn query_before(a: RectangleQuery, b: RectangleQuery) -> bool {
    let a_key = (a.top_block, a.left_block, a.bottom_block, a.right_block,
        a.top, a.left, a.bottom, a.right, a.ordinal);
    let b_key = (b.top_block, b.left_block, b.bottom_block, b.right_block,
        b.top, b.left, b.bottom, b.right, b.ordinal);
    a_key < b_key
}

fn add_value(value: usize, frequencies: &mut [i64; MAX_VALUE + 1], statistic: &mut i64) {
    let old_frequency = frequencies[value];
    *statistic += 2 * old_frequency + 1;
    frequencies[value] = old_frequency + 1;
}

fn remove_value(value: usize, frequencies: &mut [i64; MAX_VALUE + 1], statistic: &mut i64) {
    let old_frequency = frequencies[value];
    *statistic += 1 - 2 * old_frequency;
    frequencies[value] = old_frequency - 1;
}

#[no_mangle]
pub unsafe extern "C" fn mo_2d_rectangle_frequency_square(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let side_value = values[0];
    let query_count_value = values[1];
    if !(1..=MAX_SIDE as i64).contains(&side_value)
        || !(0..=MAX_QUERIES as i64).contains(&query_count_value)
    {
        return -1;
    }
    let side = side_value as usize;
    let query_count = query_count_value as usize;
    let matrix_end = 2 + side * side;
    if length != matrix_end + 4 * query_count {
        return -1;
    }

    let mut matrix = [0usize; MAX_SIDE * MAX_SIDE];
    for position in 0..side * side {
        let value = values[2 + position];
        if !(0..=MAX_VALUE as i64).contains(&value) {
            return -1;
        }
        matrix[position] = value as usize;
    }

    let mut queries = [RectangleQuery {
        top_block: 0, left_block: 0, bottom_block: 0, right_block: 0,
        top: 0, left: 0, bottom: 0, right: 0, ordinal: 0,
    }; MAX_QUERIES];
    for ordinal in 0..query_count {
        let offset = matrix_end + 4 * ordinal;
        let top_value = values[offset];
        let left_value = values[offset + 1];
        let bottom_value = values[offset + 2];
        let right_value = values[offset + 3];
        if top_value < 0 || bottom_value < top_value || bottom_value >= side_value
            || left_value < 0 || right_value < left_value || right_value >= side_value
        {
            return -1;
        }
        queries[ordinal] = RectangleQuery {
            top_block: 0, left_block: 0, bottom_block: 0, right_block: 0,
            top: top_value as usize,
            left: left_value as usize,
            bottom: bottom_value as usize,
            right: right_value as usize,
            ordinal,
        };
    }

    let side_fourth = side * side * side * side;
    let mut block_size = 0usize;
    for candidate in 1..=side {
        if query_count * candidate * candidate * candidate * candidate <= side_fourth {
            block_size = candidate;
        }
    }
    if block_size == 0 {
        block_size = 1;
    }
    for query in queries.iter_mut().take(query_count) {
        query.top_block = query.top / block_size;
        query.left_block = query.left / block_size;
        query.bottom_block = query.bottom / block_size;
        query.right_block = query.right / block_size;
    }
    for i in 1..query_count {
        let current = queries[i];
        let mut position = i;
        while position > 0 && query_before(current, queries[position - 1]) {
            queries[position] = queries[position - 1];
            position -= 1;
        }
        queries[position] = current;
    }

    if query_count == 0 {
        return 0;
    }
    let mut answers = [0i64; MAX_QUERIES];
    let mut frequencies = [0i64; MAX_VALUE + 1];
    let mut statistic = 0i64;
    let mut top = queries[0].top;
    let mut left = queries[0].left;
    let mut bottom = queries[0].bottom;
    let mut right = queries[0].right;
    for row in top..=bottom {
        for column in left..=right {
            add_value(matrix[row * side + column], &mut frequencies, &mut statistic);
        }
    }
    answers[queries[0].ordinal] = statistic;

    for sorted_index in 1..query_count {
        let query = queries[sorted_index];
        while top > query.top {
            top -= 1;
            for column in left..=right {
                add_value(matrix[top * side + column], &mut frequencies, &mut statistic);
            }
        }
        while bottom < query.bottom {
            bottom += 1;
            for column in left..=right {
                add_value(matrix[bottom * side + column], &mut frequencies, &mut statistic);
            }
        }
        while left > query.left {
            left -= 1;
            for row in top..=bottom {
                add_value(matrix[row * side + left], &mut frequencies, &mut statistic);
            }
        }
        while right < query.right {
            right += 1;
            for row in top..=bottom {
                add_value(matrix[row * side + right], &mut frequencies, &mut statistic);
            }
        }
        while top < query.top {
            for column in left..=right {
                remove_value(matrix[top * side + column], &mut frequencies, &mut statistic);
            }
            top += 1;
        }
        while bottom > query.bottom {
            for column in left..=right {
                remove_value(matrix[bottom * side + column], &mut frequencies, &mut statistic);
            }
            bottom -= 1;
        }
        while left < query.left {
            for row in top..=bottom {
                remove_value(matrix[row * side + left], &mut frequencies, &mut statistic);
            }
            left += 1;
        }
        while right > query.right {
            for row in top..=bottom {
                remove_value(matrix[row * side + right], &mut frequencies, &mut statistic);
            }
            right -= 1;
        }
        answers[query.ordinal] = statistic;
    }

    let mut checksum = 0i64;
    for ordinal in 0..query_count {
        checksum += (ordinal as i64 + 1) * answers[ordinal];
    }
    checksum
}
