module sprague_grundy_theorem;

const long MAX_POSITION = 64;
const long MAX_MOVE_COUNT = 32;
const long MAX_MOVE_SIZE = 32;
const usz MAX_INPUT_LENGTH = 34;

fn long calculate_grundy(long position, long* memo, long* values, usz move_count) {
    usz index = (usz)position;
    if (memo[index] != -1) return memo[index];
    if (position == 0) { memo[0] = 0; return 0; }

    bool[33] reachable;
    for (usz i = 0; i < 33; i++) reachable[i] = false;
    for (usz i = 0; i < move_count; i++) {
        long move = values[2 + i];
        if (move <= position) {
            long child = calculate_grundy(position - move, memo, values, move_count);
            if (child >= 0 && child <= MAX_MOVE_COUNT) reachable[(usz)child] = true;
        }
    }
    long mex = 0;
    while (mex <= MAX_MOVE_COUNT && reachable[(usz)mex]) mex++;
    memo[index] = mex;
    return mex;
}

// Compute a bounded single-heap subtraction game's Sprague-Grundy number.
fn long sprague_grundy_theorem(long* values, usz length) @export("sprague_grundy_theorem") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long position = values[0];
    long move_count_value = values[1];
    if (position < 0 || position > MAX_POSITION || move_count_value < 0 || move_count_value > MAX_MOVE_COUNT) return -1;
    usz move_count = (usz)move_count_value;
    if (length != 2 + move_count) return -1;
    for (usz i = 0; i < move_count; i++)
        if (values[2 + i] < 1 || values[2 + i] > MAX_MOVE_SIZE) return -1;

    long[MAX_POSITION + 1] memo;
    for (usz i = 0; i <= (usz)MAX_POSITION; i++) memo[i] = -1;
    return calculate_grundy(position, &memo[0], values, move_count);
}
