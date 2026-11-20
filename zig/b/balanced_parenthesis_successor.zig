// Clean-room bounded lexicographic successor for a one-type Dyck word.
const max_pairs: usize = 10;
const max_input_length: usize = 21;
const max_output_bytes: usize = 20;

export fn balanced_parenthesis_successor(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > max_input_length) return -1;
    const input = input_opt.?;
    const pair_value = input[0];
    if (pair_value < 1 or pair_value > max_pairs) return -1;
    const pairs: usize = @intCast(pair_value);
    const sequence_length = 2 * pairs;
    if (length != 1 + sequence_length) return -1;

    var symbols: [max_output_bytes]u8 = [_]u8{0} ** max_output_bytes;
    var balance: i64 = 0;
    for (0..sequence_length) |i| {
        const symbol = input[1 + i];
        if (symbol != 0 and symbol != 1) return -1;
        symbols[i] = @intCast(symbol);
        if (symbol == 0) balance += 1 else balance -= 1;
        if (balance < 0) return -1;
    }
    if (balance != 0) return -1;
    if (output_opt == null or capacity < sequence_length) return -2;

    const output = output_opt.?;
    var staged: [max_output_bytes]u8 = [_]u8{0} ** max_output_bytes;
    var reverse_depth: i64 = 0;
    var cursor = sequence_length;
    while (cursor > 0) {
        cursor -= 1;
        if (symbols[cursor] == 0) reverse_depth -= 1 else reverse_depth += 1;
        if (symbols[cursor] == 0 and reverse_depth > 0) {
            reverse_depth -= 1;
            const suffix_length = sequence_length - cursor - 1;
            const opening_count: usize = @intCast((@as(i64, @intCast(suffix_length)) - reverse_depth) / 2);
            const closing_count = suffix_length - opening_count;
            for (0..cursor) |j| staged[j] = if (symbols[j] == 0) 40 else 41;
            staged[cursor] = 41;
            var position = cursor + 1;
            for (0..opening_count) |_| {
                staged[position] = 40;
                position += 1;
            }
            for (0..closing_count) |_| {
                staged[position] = 41;
                position += 1;
            }
            for (0..sequence_length) |j| output[j] = staged[j];
            return @intCast(sequence_length);
        }
    }
    return -3;
}
