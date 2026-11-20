const max_pairs: usize = 10;
const max_input_length: usize = 23;
const ways_stride: usize = 11;
const ways_count: usize = 231;

export fn balanced_parenthesis_rank_unrank(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > max_input_length) return -1;
    const mode = input[0];
    const pairs_value = input[1];
    if (pairs_value < 1 or pairs_value > @as(i64, @intCast(max_pairs))) return -1;
    const pairs: usize = @intCast(pairs_value);
    const sequence_length = 2 * pairs;

    if (mode == 0) {
        if (length != 2 + sequence_length) return -1;
        var balance: i64 = 0;
        for (0..sequence_length) |index| {
            const symbol = input[2 + index];
            if (symbol != 0 and symbol != 1) return -1;
            if (symbol == 0) balance += 1 else balance -= 1;
            if (balance < 0) return -1;
        }
        if (balance != 0) return -1;
    } else if (mode == 1) {
        if (length != 3) return -1;
    } else {
        return -1;
    }

    var ways: [ways_count]i64 = @splat(0);
    ways[0] = 1;
    for (1..sequence_length + 1) |remaining| {
        for (0..pairs + 1) |balance| {
            var count: i64 = 0;
            if (balance < pairs) count += ways[(remaining - 1) * ways_stride + balance + 1];
            if (balance > 0) count += ways[(remaining - 1) * ways_stride + balance - 1];
            ways[remaining * ways_stride + balance] = count;
        }
    }

    if (mode == 0) {
        var rank: i64 = 0;
        var balance: usize = 0;
        for (0..sequence_length) |index| {
            const symbol = input[2 + index];
            const remaining = sequence_length - index - 1;
            if (symbol == 1 and balance < pairs) {
                rank += ways[remaining * ways_stride + balance + 1];
            }
            if (symbol == 0) balance += 1 else balance -= 1;
        }
        return rank;
    }

    var rank = input[2];
    if (rank < 0 or rank >= ways[sequence_length * ways_stride]) return -1;
    var balance: usize = 0;
    var code: i64 = 0;
    for (0..sequence_length) |index| {
        const remaining = sequence_length - index - 1;
        const opening_count: i64 = if (balance < pairs)
            ways[remaining * ways_stride + balance + 1]
        else
            0;
        if (rank < opening_count) {
            balance += 1;
            code <<= 1;
        } else {
            rank -= opening_count;
            balance -= 1;
            code = (code << 1) | 1;
        }
    }
    return code;
}
