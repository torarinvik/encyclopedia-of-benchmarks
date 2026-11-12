const MAX_SOURCE_LENGTH: usize = 6;
const MAX_INPUT_LENGTH: usize = 16;
const MAX_OUTPUT_LENGTH: usize = 12;

const Sequence = struct {
    values: [MAX_OUTPUT_LENGTH]u8 = @splat(0),
    length: usize = 0,
};

fn maximumSubsequence(source: []const i64, requested: usize) Sequence {
    var stack: [MAX_SOURCE_LENGTH]u8 = @splat(0);
    var stack_length: usize = 0;
    var deletions = source.len - requested;
    for (source) |value| {
        const digit: u8 = @intCast(value);
        while (deletions > 0 and stack_length > 0 and stack[stack_length - 1] < digit) {
            stack_length -= 1;
            deletions -= 1;
        }
        stack[stack_length] = digit;
        stack_length += 1;
    }
    stack_length -= deletions;
    var selected = Sequence{};
    selected.length = stack_length;
    for (0..stack_length) |i| selected.values[i] = stack[i];
    return selected;
}

fn compareSuffix(first: *const Sequence, i0: usize, second: *const Sequence, j0: usize) i32 {
    var i = i0;
    var j = j0;
    while (i < first.length and j < second.length) {
        if (first.values[i] != second.values[j]) return if (first.values[i] > second.values[j]) 1 else -1;
        i += 1;
        j += 1;
    }
    if (i == first.length and j == second.length) return 0;
    return if (i == first.length) -1 else 1;
}

fn mergeSequences(first: *const Sequence, second: *const Sequence) Sequence {
    var merged = Sequence{};
    var i: usize = 0;
    var j: usize = 0;
    while (i < first.length or j < second.length) {
        const order = compareSuffix(first, i, second, j);
        if (j == second.length or (i < first.length and order >= 0)) {
            merged.values[merged.length] = first.values[i];
            i += 1;
        } else {
            merged.values[merged.length] = second.values[j];
            j += 1;
        }
        merged.length += 1;
    }
    return merged;
}

fn greater(left: *const Sequence, right: *const Sequence) bool {
    for (0..left.length) |i| {
        if (left.values[i] != right.values[i]) return left.values[i] > right.values[i];
    }
    return false;
}

export fn create_maximum_number(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const max_source_i64: i64 = @intCast(MAX_SOURCE_LENGTH);
    if (values[0] < 0 or values[0] > max_source_i64
        or values[1] < 0 or values[1] > max_source_i64) return -1;
    const first_length: usize = @intCast(values[0]);
    const second_length: usize = @intCast(values[1]);
    const total_source_length_i64: i64 = @intCast(first_length + second_length);
    if (values[2] < 0 or values[2] > total_source_length_i64) return -1;
    const requested: usize = @intCast(values[2]);
    if (length != 3 + first_length + second_length) return -1;
    for (values[3..]) |digit| if (digit < 0 or digit > 9) return -1;
    if (output == null or capacity < requested) return -2;

    const first = values[3 .. 3 + first_length];
    const second = values[3 + first_length ..];
    const minimum_first = if (requested > second_length) requested - second_length else 0;
    const maximum_first = @min(requested, first_length);
    var best = Sequence{};
    var have_best = false;
    var take_first = minimum_first;
    while (take_first <= maximum_first) : (take_first += 1) {
        const selected_first = maximumSubsequence(first, take_first);
        const selected_second = maximumSubsequence(second, requested - take_first);
        const candidate = mergeSequences(&selected_first, &selected_second);
        if (!have_best or greater(&candidate, &best)) {
            best = candidate;
            have_best = true;
        }
    }
    const destination = output.?;
    for (0..requested) |i| destination[i] = best.values[i];
    return @intCast(requested);
}
