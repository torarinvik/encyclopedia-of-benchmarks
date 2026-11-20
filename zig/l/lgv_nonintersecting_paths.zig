const MAX_HEIGHT: usize = 5;
const MAX_WIDTH: usize = 5;
const MAX_PATHS: usize = 3;
const MAX_INPUT_LENGTH: usize = 11;

fn singleSourcePaths(height: usize, width: usize, blocked: i64, source_row: usize, sink_row: usize) i64 {
    var ways: [MAX_HEIGHT][MAX_WIDTH]i64 = [_][MAX_WIDTH]i64{[_]i64{0} ** MAX_WIDTH} ** MAX_HEIGHT;
    for (0..height) |row| {
        for (0..width) |column| {
            const bit = row * width + column;
            if (((blocked >> @intCast(bit)) & 1) != 0) {
                ways[row][column] = 0;
            } else if (row == source_row and column == 0) {
                ways[row][column] = 1;
            } else {
                if (row > 0) ways[row][column] += ways[row - 1][column];
                if (column > 0) ways[row][column] += ways[row][column - 1];
            }
        }
    }
    return ways[sink_row][width - 1];
}

fn determinant(matrix: [MAX_PATHS][MAX_PATHS]i64, order: usize) i64 {
    const second_limit = if (order >= 2) order else 1;
    const third_limit = if (order >= 3) order else 1;
    var total: i64 = 0;
    for (0..order) |first| {
        for (0..second_limit) |second| {
            if (order >= 2 and second == first) continue;
            for (0..third_limit) |third| {
                if (order >= 3 and (third == first or third == second)) continue;
                const permutation = [3]usize{ first, second, third };
                var inversions: usize = 0;
                var product: i64 = 1;
                for (0..order) |row| {
                    product *= matrix[row][permutation[row]];
                    var later = row + 1;
                    while (later < order) : (later += 1) {
                        if (permutation[row] > permutation[later]) inversions += 1;
                    }
                }
                if (inversions % 2 == 0) {
                    total += product;
                } else {
                    total -= product;
                }
            }
        }
    }
    return total;
}

fn execute(input: []const i64) ?i64 {
    if (input.len < 4 or input.len > MAX_INPUT_LENGTH) return null;
    const height64 = input[0];
    const width64 = input[1];
    const path_count64 = input[2];
    const blocked = input[3];
    if (height64 < 1 or height64 > MAX_HEIGHT or width64 < 2 or width64 > MAX_WIDTH
        or path_count64 < 1 or path_count64 > MAX_PATHS or blocked < 0) return null;
    const height: usize = @intCast(height64);
    const width: usize = @intCast(width64);
    const path_count: usize = @intCast(path_count64);
    if (input.len != 4 + 2 * path_count) return null;
    const cell_count = height * width;
    if (blocked >= (@as(i64, 1) << @intCast(cell_count))) return null;

    var sources: [MAX_PATHS]usize = [_]usize{0} ** MAX_PATHS;
    var sinks: [MAX_PATHS]usize = [_]usize{0} ** MAX_PATHS;
    for (0..path_count) |i| {
        const source = input[4 + i];
        const sink = input[4 + path_count + i];
        if (source < 0 or source >= height64 or sink < 0 or sink >= height64 or source > sink) return null;
        if (i > 0 and (source <= @as(i64, @intCast(sources[i - 1]))
            or sink <= @as(i64, @intCast(sinks[i - 1])))) return null;
        sources[i] = @intCast(source);
        sinks[i] = @intCast(sink);
        const source_bit = sources[i] * width;
        const sink_bit = sinks[i] * width + width - 1;
        if (((blocked >> @intCast(source_bit)) & 1) != 0
            or ((blocked >> @intCast(sink_bit)) & 1) != 0) return null;
    }

    var matrix: [MAX_PATHS][MAX_PATHS]i64 = [_][MAX_PATHS]i64{[_]i64{0} ** MAX_PATHS} ** MAX_PATHS;
    for (0..path_count) |source_index| {
        for (0..path_count) |sink_index| {
            matrix[source_index][sink_index] = singleSourcePaths(
                height, width, blocked, sources[source_index], sinks[sink_index]);
        }
    }
    return determinant(matrix, path_count);
}

export fn lgv_nonintersecting_paths(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 4 or length > MAX_INPUT_LENGTH) return -1;
    return execute(input[0..length]) orelse -1;
}
