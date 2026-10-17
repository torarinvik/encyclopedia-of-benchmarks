const MAX_LEAVES: i64 = 32;
const MAX_INPUT_LENGTH: usize = 2 + @as(usize, @intCast(MAX_LEAVES));
const INVALID_RESULT: i64 = -2_147_483_649;

fn evaluate(values: [*c]const i64, index: usize, depth: usize, height: usize, maximizing: bool) i64 {
    if (depth == height) return values[2 + index];
    const left = evaluate(values, index * 2, depth + 1, height, !maximizing);
    const right = evaluate(values, index * 2 + 1, depth + 1, height, !maximizing);
    return if (maximizing) @max(left, right) else @min(left, right);
}

export fn minimax(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const leaf_count = values[0];
    const first_turn_is_max = values[1];
    if (leaf_count < 1 or leaf_count > MAX_LEAVES or (leaf_count & (leaf_count - 1)) != 0 or
        (first_turn_is_max != 0 and first_turn_is_max != 1) or
        length != @as(usize, @intCast(2 + leaf_count))) return INVALID_RESULT;
    for (0..@intCast(leaf_count)) |leaf| {
        if (values[2 + leaf] < -2_147_483_648 or values[2 + leaf] > 2_147_483_647) return INVALID_RESULT;
    }
    var height: usize = 0;
    var width: i64 = leaf_count;
    while (width > 1) : (width /= 2) height += 1;
    return evaluate(values, 0, 0, height, first_turn_is_max == 1);
}
