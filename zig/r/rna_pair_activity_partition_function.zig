const MAX_SEQUENCE_LENGTH: usize = 16;
const MAX_PARSEABLE_LENGTH: usize = 122;

fn pairInputIndex(n: usize, left: usize, right: usize) usize {
    const preceding = left * (2 * n - left - 1) / 2;
    return 1 + preceding + (right - left - 1);
}

pub export fn rna_pair_activity_partition_function(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_SEQUENCE_LENGTH) return -1;
    const n: usize = @intCast(input[0]);
    const expected_length = if (n == 0) 1 else 1 + n * (n - 1) / 2;
    if (length != expected_length) return -1;
    for (input[1..length]) |activity| if (activity < 0 or activity > 3) return -1;
    if (n == 0) return 1;

    var table: [MAX_SEQUENCE_LENGTH][MAX_SEQUENCE_LENGTH]i64 = @splat(@splat(0));
    var span: usize = 1;
    while (span <= n) : (span += 1) {
        var left: usize = 0;
        while (left + span <= n) : (left += 1) {
            const right = left + span - 1;
            var total: i64 = if (left == right) 1 else table[left][right - 1];
            var partner = left;
            while (partner < right) : (partner += 1) {
                const activity = input[pairInputIndex(n, partner, right)];
                const before: i64 = if (partner == left) 1 else table[left][partner - 1];
                const inside: i64 = if (partner + 1 >= right) 1 else table[partner + 1][right - 1];
                total += before * inside * activity;
            }
            table[left][right] = total;
        }
    }
    return table[0][n - 1];
}
