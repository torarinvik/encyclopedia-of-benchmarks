module minimax;

const long MAX_LEAVES = 32;
const long MAX_INPUT_LENGTH = 2 + MAX_LEAVES;
const long INVALID_RESULT = -2147483649;

fn long evaluate(long* values, usz index, usz depth, usz height, bool maximizing) {
    if (depth == height) return values[2 + index];
    long left = evaluate(values, index * 2, depth + 1, height, !maximizing);
    long right = evaluate(values, index * 2 + 1, depth + 1, height, !maximizing);
    if (maximizing) return left > right ? left : right;
    return left < right ? left : right;
}

fn long minimax(long* values, usz length) @export("minimax") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long leaf_count = values[0], turn = values[1];
    if (leaf_count < 1 || leaf_count > MAX_LEAVES || (leaf_count & (leaf_count - 1)) != 0 ||
        (turn != 0 && turn != 1) || length != (usz)(2 + leaf_count)) return INVALID_RESULT;
    for (long leaf = 0; leaf < leaf_count; leaf++)
        if (values[2 + leaf] < -2147483648 || values[2 + leaf] > 2147483647) return INVALID_RESULT;

    usz height = 0;
    for (long width = leaf_count; width > 1; width /= 2) height++;
    return evaluate(values, 0, 0, height, turn == 1);
}
