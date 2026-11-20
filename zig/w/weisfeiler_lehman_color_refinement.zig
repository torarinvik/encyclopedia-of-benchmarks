const MAX_VERTICES: usize = 8;
const MAX_INPUT_LENGTH: usize = 9;
const INVALID_RESULT: i64 = -1;
const DEGREE_COLOR_PLACE: i64 = 43046721;

fn bitCount(value_input: i64) i64 {
    var value = value_input;
    var count: i64 = 0;
    while (value != 0) {
        count += value & 1;
        value >>= 1;
    }
    return count;
}

export fn weisfeiler_lehman_color_refinement(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH + 1) return INVALID_RESULT;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_VERTICES) return INVALID_RESULT;
    const n: usize = @intCast(input[0]);
    if (length != 1 + n) return INVALID_RESULT;

    const allowed: i64 = (@as(i64, 1) << @intCast(n)) - 1;
    var adjacency = [_]i64{0} ** MAX_VERTICES;
    var colors = [_]i64{0} ** MAX_VERTICES;
    var next_colors = [_]i64{0} ** MAX_VERTICES;
    var class_count: usize = 0;
    for (0..n) |vertex| {
        const mask = input[1 + vertex];
        if (mask < 0 or (mask & ~allowed) != 0 or
            (mask & (@as(i64, 1) << @intCast(vertex))) != 0) return INVALID_RESULT;
        adjacency[vertex] = mask;
        colors[vertex] = bitCount(mask);
        var first_degree = true;
        for (0..vertex) |prior| {
            if (colors[prior] == colors[vertex]) first_degree = false;
            if (((adjacency[vertex] >> @intCast(prior)) & 1) !=
                ((adjacency[prior] >> @intCast(vertex)) & 1)) return INVALID_RESULT;
        }
        if (first_degree) class_count += 1;
    }
    if (n == 0) return 0;

    while (true) {
        var keys = [_]i64{0} ** MAX_VERTICES;
        var unique_keys = [_]i64{0} ** MAX_VERTICES;
        var unique_count: usize = 0;
        for (0..n) |vertex| {
            var neighbor_colors = [_]i64{0} ** MAX_VERTICES;
            var neighbor_count: usize = 0;
            for (0..n) |neighbor| {
                if ((adjacency[vertex] & (@as(i64, 1) << @intCast(neighbor))) == 0) continue;
                const value = colors[neighbor];
                var position = neighbor_count;
                while (position > 0 and neighbor_colors[position - 1] > value) {
                    neighbor_colors[position] = neighbor_colors[position - 1];
                    position -= 1;
                }
                neighbor_colors[position] = value;
                neighbor_count += 1;
            }

            var suffix: i64 = 0;
            for (0..MAX_VERTICES) |slot| {
                suffix *= 9;
                if (slot < neighbor_count) suffix += neighbor_colors[slot] + 1;
            }
            keys[vertex] = colors[vertex] * DEGREE_COLOR_PLACE + suffix;
            var seen = false;
            for (0..vertex) |prior| {
                if (keys[prior] == keys[vertex]) seen = true;
            }
            if (!seen) {
                unique_keys[unique_count] = keys[vertex];
                unique_count += 1;
            }
        }

        for (1..unique_count) |index| {
            const value = unique_keys[index];
            var position = index;
            while (position > 0 and unique_keys[position - 1] > value) {
                unique_keys[position] = unique_keys[position - 1];
                position -= 1;
            }
            unique_keys[position] = value;
        }
        for (0..n) |vertex| {
            var rank: usize = 0;
            while (unique_keys[rank] != keys[vertex]) rank += 1;
            next_colors[vertex] = @intCast(rank);
        }
        for (0..n) |vertex| colors[vertex] = next_colors[vertex];
        if (unique_count == class_count) break;
        class_count = unique_count;
    }

    var packed: i64 = 0;
    var place: i64 = 1;
    for (0..n) |vertex| {
        packed += colors[vertex] * place;
        place *= 9;
    }
    return packed;
}
