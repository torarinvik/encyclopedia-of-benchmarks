const MAX_WORDS: usize = 8;
const MAX_PATH_WORDS: usize = MAX_WORDS + 1;
const MAX_INPUT_LENGTH: usize = 4 + MAX_WORDS;
const MAX_OUTPUT_FIELDS: usize = MAX_PATH_WORDS + MAX_WORDS + 2;

fn powerOf26(exponent: usize) i64 {
    var result: i64 = 1;
    for (0..exponent) |_| result *= 26;
    return result;
}

fn findActiveWord(words: []const i64, active: *const [MAX_WORDS]bool, candidate: i64) ?usize {
    for (words, 0..) |word, index| {
        if (active[index] and word == candidate) return index;
    }
    return null;
}

fn backtrack(
    current: i64,
    target: i64,
    width: usize,
    words: []const i64,
    active: *[MAX_WORDS]bool,
    path: *[MAX_PATH_WORDS]i64,
    path_length: *usize,
) bool {
    if (current == target) return true;
    for (0..width) |position| {
        const factor = powerOf26(width - position - 1);
        const digit = @rem(@divTrunc(current, factor), 26);
        for (0..26) |replacement_index| {
            const replacement: i64 = @intCast(replacement_index);
            const candidate = current + (replacement - digit) * factor;
            const index = findActiveWord(words, active, candidate) orelse continue;
            active[index] = false;
            path[path_length.*] = candidate;
            path_length.* += 1;
            if (backtrack(candidate, target, width, words, active, path, path_length)) return true;
            path_length.* -= 1;
            active[index] = true;
        }
    }
    return false;
}

fn writeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn word_ladder_dfs(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const width_value = values[0];
    const begin = values[1];
    const end = values[2];
    const count_value = values[3];
    if (width_value < 1 or width_value > 5 or count_value < 0 or count_value > 8 or
        length != 4 + @as(usize, @intCast(count_value))) return -1;
    const width: usize = @intCast(width_value);
    const count: usize = @intCast(count_value);
    const words = values[4 .. 4 + count];
    const limit = powerOf26(width);
    if (begin < 0 or begin >= limit or end < 0 or end >= limit) return -1;
    for (words, 0..) |word, index| {
        if (word < 0 or word >= limit or (index > 0 and words[index - 1] >= word)) return -1;
    }

    var active: [MAX_WORDS]bool = [_]bool{false} ** MAX_WORDS;
    for (0..count) |index| active[index] = true;
    var path: [MAX_PATH_WORDS]i64 = [_]i64{0} ** MAX_PATH_WORDS;
    path[0] = begin;
    var path_length: usize = 1;
    if (findActiveWord(words, &active, end) != null) {
        if (!backtrack(begin, end, width, words, &active, &path, &path_length)) {
            path_length = 0;
        }
    } else {
        path_length = 0;
    }

    var fields: [MAX_OUTPUT_FIELDS]i64 = [_]i64{0} ** MAX_OUTPUT_FIELDS;
    var field_count: usize = 0;
    fields[field_count] = @intCast(path_length);
    field_count += 1;
    for (path[0..path_length]) |word| {
        fields[field_count] = word;
        field_count += 1;
    }
    var remaining_count: usize = 0;
    for (0..count) |index| {
        if (active[index]) remaining_count += 1;
    }
    fields[field_count] = @intCast(remaining_count);
    field_count += 1;
    for (words, 0..) |word, index| {
        if (active[index]) {
            fields[field_count] = word;
            field_count += 1;
        }
    }

    const required = field_count * 8;
    if (output == null or capacity < required) return -2;
    const output_bytes = output.?;
    for (fields[0..field_count], 0..) |value, index| writeI64Le(output_bytes, index * 8, value);
    return @intCast(required);
}
