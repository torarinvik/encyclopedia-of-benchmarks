const MAX_TERMS: usize = 4097;
const MAX_INPUT: usize = 3;
const MAX_SEED: i64 = 100_000;
const MAX_VALUE: i64 = 100_000;
const MAX_TRANSITIONS: i64 = 4_096;

fn aliquotSum(value: i64) i64 {
    if (value == 1) return 0;
    var total: i64 = 1;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@rem(value, divisor) == 0) {
            total += divisor;
            const partner = @divTrunc(value, divisor);
            if (partner != divisor) total += partner;
        }
    }
    return total;
}

fn storeI64(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn decompose(input: []const i64, words: *[3]i64) i64 {
    if (input.len != 2 or input[0] < 1 or input[0] > MAX_SEED or
        input[1] < 1 or input[1] > MAX_TRANSITIONS) return -1;
    var keys: [MAX_TERMS]i64 = @splat(0);
    var first_indices: [MAX_TERMS]i64 = @splat(0);
    var key_count: usize = 0;
    var current = input[0];
    var transitions: i64 = 0;
    var positive_count: i64 = 0;
    while (true) {
        if (current == 0) {
            words.* = .{ 0, positive_count, 0 };
            break;
        }
        var low: usize = 0;
        var high = key_count;
        while (low < high) {
            const middle = low + (high - low) / 2;
            if (keys[middle] < current) low = middle + 1 else high = middle;
        }
        if (low < key_count and keys[low] == current) {
            words.* = .{ 1, first_indices[low], transitions - first_indices[low] };
            break;
        }
        var cursor = key_count;
        while (cursor > low) {
            keys[cursor] = keys[cursor - 1];
            first_indices[cursor] = first_indices[cursor - 1];
            cursor -= 1;
        }
        keys[low] = current;
        first_indices[low] = transitions;
        key_count += 1;
        positive_count += 1;
        if (transitions >= input[1]) {
            words.* = .{ -3, transitions, current };
            break;
        }
        const next_value = aliquotSum(current);
        transitions += 1;
        if (next_value > MAX_VALUE) {
            words.* = .{ -2, transitions, next_value };
            break;
        }
        current = next_value;
    }
    return 3;
}

export fn aliquot_orbit_decomposition(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT) return -1;
    const input_ptr = input_opt.?;
    const input = input_ptr[0..length];
    var words: [3]i64 = .{ 0, 0, 0 };
    const result = decompose(input, &words);
    if (result < 0) return result;
    if (output_opt == null or capacity < 24) return -2;
    const output = output_opt.?[0..24];
    for (0..3) |word| storeI64(output, word * 8, words[word]);
    return 24;
}
