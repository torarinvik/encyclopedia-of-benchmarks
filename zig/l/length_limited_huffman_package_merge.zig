const MAX_SYMBOLS: usize = 12;
const MAX_LIMIT: usize = 6;
const MAX_LEVELS: usize = 16;
const MAX_ITEMS: usize = 32;
const MAX_INPUT_LENGTH: usize = 15;

fn solve(symbol_count: usize, limit: usize, input: [*]const i64) i64 {
    var weights: [MAX_SYMBOLS]i64 = @splat(0);
    for (0..symbol_count) |index| {
        const weight = input[index + 2];
        if (weight < 0 or weight > 1_000_000) return -1;
        weights[index] = weight;
    }
    for (1..symbol_count) |index| {
        const key = weights[index];
        var position = index;
        while (position > 0 and weights[position - 1] > key) {
            weights[position] = weights[position - 1];
            position -= 1;
        }
        weights[position] = key;
    }

    var levels: [MAX_LEVELS * MAX_ITEMS]i64 = @splat(0);
    var counts: [MAX_LEVELS]usize = @splat(0);
    for (0..limit) |level| {
        for (0..symbol_count) |index| levels[level * MAX_ITEMS + index] = weights[index];
        counts[level] = symbol_count;
    }
    var remaining: i64 = (@as(i64, @intCast(symbol_count)) - 1) << @intCast(limit);
    var total: i64 = 0;
    var level: usize = 0;
    while (remaining > 0) {
        while (level < MAX_LEVELS and counts[level] == 0) level += 1;
        if (level >= MAX_LEVELS) return -1;
        const width: i64 = @as(i64, 1) << @intCast(level);
        const smallest_needed = remaining & -remaining;
        if (width > smallest_needed) return -1;

        const base = level * MAX_ITEMS;
        var current_count = counts[level];
        if (width == smallest_needed) {
            total += levels[base];
            for (1..current_count) |index| levels[base + index - 1] = levels[base + index];
            current_count -= 1;
            counts[level] = current_count;
            remaining -= width;
            if (remaining == 0) break;
        }

        var packages: [MAX_ITEMS]i64 = @splat(0);
        var package_count: usize = 0;
        var index: usize = 0;
        while (index + 1 < current_count) : (index += 2) {
            packages[package_count] = levels[base + index] + levels[base + index + 1];
            package_count += 1;
        }
        counts[level] = 0;

        const next_level = level + 1;
        if (next_level >= MAX_LEVELS) return -1;
        const existing_count = counts[next_level];
        var merged: [MAX_ITEMS]i64 = @splat(0);
        var package_index: usize = 0;
        var existing_index: usize = 0;
        var merged_count: usize = 0;
        while (package_index < package_count and existing_index < existing_count) {
            if (packages[package_index] <= levels[next_level * MAX_ITEMS + existing_index]) {
                merged[merged_count] = packages[package_index];
                package_index += 1;
            } else {
                merged[merged_count] = levels[next_level * MAX_ITEMS + existing_index];
                existing_index += 1;
            }
            merged_count += 1;
        }
        while (package_index < package_count) {
            merged[merged_count] = packages[package_index];
            package_index += 1;
            merged_count += 1;
        }
        while (existing_index < existing_count) {
            merged[merged_count] = levels[next_level * MAX_ITEMS + existing_index];
            existing_index += 1;
            merged_count += 1;
        }
        for (0..merged_count) |item| levels[next_level * MAX_ITEMS + item] = merged[item];
        counts[next_level] = merged_count;
        level = next_level;
    }
    return total;
}

export fn length_limited_huffman_package_merge(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const symbol_value = input[0];
    const limit_value = input[1];
    if (symbol_value < 2 or symbol_value > 12 or limit_value < 1 or limit_value > 6) return -1;
    const symbol_count: usize = @intCast(symbol_value);
    const limit: usize = @intCast(limit_value);
    if (symbol_count > (@as(usize, 1) << @intCast(limit)) or length != symbol_count + 2) return -1;
    return solve(symbol_count, limit, input);
}
