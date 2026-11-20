const MAX_DIM: usize = 5;
const MAX_PAT_DIM: usize = 4;
const MAX_INPUT: usize = 196;
const MAX_MATCHES: usize = 125;

fn putLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn sameRows(plane: [MAX_PAT_DIM * MAX_PAT_DIM]i64, left: usize,
            right: usize, width: usize) bool {
    for (0..width) |column| if (plane[left * width + column] != plane[right * width + column]) return false;
    return true;
}

export fn three_dimensional_bird_baker_matching(
    input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 7 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const r0, c0, d0 = input[0], input[1], input[2];
    const pr0, pc0, pd0 = input[3], input[4], input[5];
    if (r0 < 1 or r0 > 5 or c0 < 1 or c0 > 5 or d0 < 1 or d0 > 5
        or pr0 < 1 or pr0 > 4 or pc0 < 1 or pc0 > 4 or pd0 < 1 or pd0 > 4
        or pr0 > r0 or pc0 > c0 or pd0 > d0) return -1;
    const rows: usize = @intCast(r0);
    const columns: usize = @intCast(c0);
    const depths: usize = @intCast(d0);
    const p_rows: usize = @intCast(pr0);
    const p_columns: usize = @intCast(pc0);
    const p_depths: usize = @intCast(pd0);
    const text_size = rows * columns * depths;
    const pattern_size = p_rows * p_columns * p_depths;
    if (length != 6 + text_size + pattern_size) return -1;
    var text: [MAX_DIM * MAX_DIM * MAX_DIM]i64 = @splat(0);
    var pattern: [MAX_PAT_DIM * MAX_PAT_DIM * MAX_PAT_DIM]i64 = @splat(0);
    for (0..text_size) |i| {
        text[i] = input[6 + i];
        if (text[i] < 0 or text[i] > 3) return -1;
    }
    for (0..pattern_size) |i| {
        pattern[i] = input[6 + text_size + i];
        if (pattern[i] < 0 or pattern[i] > 3) return -1;
    }

    var plane_ids: [MAX_PAT_DIM]usize = @splat(0);
    var unique_planes: [MAX_PAT_DIM][MAX_PAT_DIM * MAX_PAT_DIM]i64 = @splat(@splat(0));
    const plane_area = p_rows * p_columns;
    var unique_count: usize = 0;
    for (0..p_depths) |pz| {
        var found = unique_count;
        for (0..unique_count) |candidate| {
            var equal = true;
            for (0..plane_area) |i| if (unique_planes[candidate][i] != pattern[pz * plane_area + i]) { equal = false; };
            if (equal) { found = candidate; break; }
        }
        if (found == unique_count) {
            for (0..plane_area) |i| unique_planes[unique_count][i] = pattern[pz * plane_area + i];
            unique_count += 1;
        }
        plane_ids[pz] = found;
    }

    const row_starts = rows - p_rows + 1;
    const column_starts = columns - p_columns + 1;
    var labels: [MAX_DIM][MAX_DIM][MAX_DIM]i8 = @splat(@splat(@splat(-1)));
    for (0..depths) |z| {
        for (0..unique_count) |unique| {
            var marks: [MAX_DIM][MAX_DIM][MAX_PAT_DIM]bool = @splat(@splat(@splat(false)));
            var prefix: [MAX_PAT_DIM]usize = @splat(0);
            for (1..p_rows) |i| {
                var matched = prefix[i - 1];
                while (matched > 0 and !sameRows(unique_planes[unique], i, matched, p_columns)) matched = prefix[matched - 1];
                if (sameRows(unique_planes[unique], i, matched, p_columns)) matched += 1;
                prefix[i] = matched;
            }
            for (0..rows) |row| {
                for (0..column_starts) |col| {
                    for (0..p_rows) |p_row| {
                        var equal = true;
                        for (0..p_columns) |p_col| if (text[(z * rows + row) * columns + col + p_col]
                            != unique_planes[unique][p_row * p_columns + p_col]) { equal = false; };
                        marks[row][col][p_row] = equal;
                    }
                }
            }
            for (0..column_starts) |col| {
                var matched: usize = 0;
                for (0..rows) |row| {
                    while (matched > 0 and !marks[row][col][matched]) matched = prefix[matched - 1];
                    if (marks[row][col][matched]) matched += 1;
                    if (matched == p_rows) {
                        labels[z][row + 1 - p_rows][col] = @intCast(unique);
                        matched = prefix[matched - 1];
                    }
                }
            }
        }
    }

    var depth_prefix: [MAX_PAT_DIM]usize = @splat(0);
    for (1..p_depths) |i| {
        var matched = depth_prefix[i - 1];
        while (matched > 0 and plane_ids[i] != plane_ids[matched]) matched = depth_prefix[matched - 1];
        if (plane_ids[i] == plane_ids[matched]) matched += 1;
        depth_prefix[i] = matched;
    }
    var matches: [MAX_MATCHES][3]i64 = @splat(@splat(0));
    var count: usize = 0;
    for (0..row_starts) |row| {
        for (0..column_starts) |col| {
            var matched: usize = 0;
            for (0..depths) |z| {
                const token = labels[z][row][col];
                while (matched > 0 and token != @as(i8, @intCast(plane_ids[matched]))) matched = depth_prefix[matched - 1];
                if (token == @as(i8, @intCast(plane_ids[matched]))) matched += 1;
                if (matched == p_depths) {
                    matches[count] = .{@intCast(row), @intCast(col), @intCast(z + 1 - p_depths)};
                    count += 1;
                    matched = depth_prefix[matched - 1];
                }
            }
        }
    }
    const bytes = 8 * (1 + 3 * count);
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    putLe(output, 0, @intCast(count));
    for (0..count) |i| for (0..3) |axis| putLe(output, 8 * (1 + 3 * i + axis), matches[i][axis]);
    return @intCast(bytes);
}
