const MAX_HEIGHT: usize = 5;
const MAX_WIDTH: usize = 5;
const MAX_PATHS: usize = 3;
const MAX_INPUT_LENGTH: usize = 11;

fn single_source_paths(height: usize, width: usize, blocked: i64, source_row: usize, sink_row: usize) -> i64 {
    let mut ways = [[0i64; MAX_WIDTH]; MAX_HEIGHT];
    for row in 0..height {
        for column in 0..width {
            let bit = row * width + column;
            if ((blocked >> bit) & 1) != 0 {
                ways[row][column] = 0;
            } else if row == source_row && column == 0 {
                ways[row][column] = 1;
            } else {
                if row > 0 { ways[row][column] += ways[row - 1][column]; }
                if column > 0 { ways[row][column] += ways[row][column - 1]; }
            }
        }
    }
    ways[sink_row][width - 1]
}

fn determinant(matrix: [[i64; MAX_PATHS]; MAX_PATHS], order: usize) -> i64 {
    let second_limit = if order >= 2 { order } else { 1 };
    let third_limit = if order >= 3 { order } else { 1 };
    let mut total = 0i64;
    for first in 0..order {
        for second in 0..second_limit {
            if order >= 2 && second == first { continue; }
            for third in 0..third_limit {
                if order >= 3 && (third == first || third == second) { continue; }
                let permutation = [first, second, third];
                let mut inversions = 0usize;
                let mut product = 1i64;
                for row in 0..order {
                    product *= matrix[row][permutation[row]];
                    for later in (row + 1)..order {
                        if permutation[row] > permutation[later] { inversions += 1; }
                    }
                }
                if inversions % 2 == 0 { total += product; } else { total -= product; }
            }
        }
    }
    total
}

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.len() < 4 || input.len() > MAX_INPUT_LENGTH { return Err(()); }
    let (height64, width64, path_count64, blocked) = (input[0], input[1], input[2], input[3]);
    if !(1..=MAX_HEIGHT as i64).contains(&height64)
        || !(2..=MAX_WIDTH as i64).contains(&width64)
        || !(1..=MAX_PATHS as i64).contains(&path_count64)
        || blocked < 0 { return Err(()); }
    let (height, width, path_count) = (height64 as usize, width64 as usize, path_count64 as usize);
    if input.len() != 4 + 2 * path_count { return Err(()); }
    let cell_count = height * width;
    if blocked >= (1i64 << cell_count) { return Err(()); }

    let mut sources = [0usize; MAX_PATHS];
    let mut sinks = [0usize; MAX_PATHS];
    for i in 0..path_count {
        let (source, sink) = (input[4 + i], input[4 + path_count + i]);
        if source < 0 || source >= height64 || sink < 0 || sink >= height64 || source > sink { return Err(()); }
        if i > 0 && (source <= sources[i - 1] as i64 || sink <= sinks[i - 1] as i64) { return Err(()); }
        sources[i] = source as usize;
        sinks[i] = sink as usize;
        if ((blocked >> (sources[i] * width)) & 1) != 0
            || ((blocked >> (sinks[i] * width + width - 1)) & 1) != 0 { return Err(()); }
    }

    let mut matrix = [[0i64; MAX_PATHS]; MAX_PATHS];
    for source_index in 0..path_count {
        for sink_index in 0..path_count {
            matrix[source_index][sink_index] = single_source_paths(
                height, width, blocked, sources[source_index], sinks[sink_index]);
        }
    }
    Ok(determinant(matrix, path_count))
}

#[no_mangle]
pub unsafe extern "C" fn lgv_nonintersecting_paths(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
