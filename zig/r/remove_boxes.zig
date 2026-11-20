const MAX_BOXES: usize = 18;
const MAX_PARSEABLE_LENGTH: usize = MAX_BOXES + 2;
const MAX_MEMO: usize = MAX_BOXES * MAX_BOXES * (MAX_BOXES + 1);

fn solveBoxes(left: usize, right: usize, carry: usize, colors: *const [MAX_BOXES]i64,
    counts: *const [MAX_BOXES]usize, memo: *[MAX_MEMO]i64) i64 {
    if (left > right) return 0;
    const index = (left * MAX_BOXES + right) * (MAX_BOXES + 1) + carry;
    if (memo[index] >= 0) return memo[index];
    const attached = counts[left] + carry;
    var best = @as(i64, @intCast(attached * attached))
        + solveBoxes(left + 1, right, 0, colors, counts, memo);
    for (left + 1..right + 1) |later| {
        if (colors[later] == colors[left]) {
            const joined = solveBoxes(left + 1, later - 1, 0, colors, counts, memo)
                + solveBoxes(later, right, attached, colors, counts, memo);
            best = @max(best, joined);
        }
    }
    memo[index] = best;
    return best;
}

export fn remove_boxes(values_opt: ?[*]const i64, length: usize) i64 {
    const values = values_opt orelse return -1;
    if (length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    if (values[0] < 0 or values[0] > @as(i64, @intCast(MAX_BOXES))) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 1) return -1;

    var colors: [MAX_BOXES]i64 = @splat(0);
    var counts: [MAX_BOXES]usize = @splat(0);
    var groups: usize = 0;
    for (0..n) |index| {
        const color = values[index + 1];
        if (color < 0 or color > 7) return -1;
        if (groups > 0 and colors[groups - 1] == color) {
            counts[groups - 1] += 1;
        } else {
            colors[groups] = color;
            counts[groups] = 1;
            groups += 1;
        }
    }
    if (groups == 0) return 0;

    var memo: [MAX_MEMO]i64 = @splat(-1);
    return solveBoxes(0, groups - 1, 0, &colors, &counts, &memo);
}
