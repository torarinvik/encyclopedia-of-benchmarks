module freebench_mason;

const int PIECE_COUNT = 9;
const int MAX_DEPTH = 8;
const int[54] UPPER_MOVES = {
    0, 8, 1, 2, 16, 5, 13, 7, 14, 9, 3, 4, 11, 12, 15, 10, 17, 6,
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
    1, 2, 9, 10, 4, 17, 6, 0, 8, 15, 11, 12, 5, 13, 7, 14, 3, 16
};
const int[54] LOWER_MOVES = {
    0, 2, 3, 10, 11, 5, 17, 7, 1, 9, 15, 12, 13, 6, 8, 14, 4, 16,
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
    7, 0, 1, 16, 4, 12, 6, 14, 8, 2, 3, 10, 11, 13, 15, 9, 17, 5
};
const int[18] NEAR_MASK = {
    0x50, 0x70, 0x70, 0x75, 0x0f, 0x0f, 0x0f, 0x70, 0x70,
    0x70, 0x7d, 0x2b, 0x2f, 0x0f, 0x50, 0x64, 0x67, 0x0f
};

fn bool near_enough(long* state) {
    return (NEAR_MASK[(int)state[1]] & 0x02) != 0 &&
        (NEAR_MASK[(int)state[3]] & 0x08) != 0 &&
        (NEAR_MASK[(int)state[4]] & 0x10) != 0 &&
        (NEAR_MASK[(int)state[5]] & 0x20) != 0 &&
        (NEAR_MASK[(int)state[0]] & 0x01) != 0 &&
        (NEAR_MASK[(int)state[2]] & 0x04) != 0 &&
        (NEAR_MASK[(int)state[6]] & 0x40) != 0 &&
        (NEAR_MASK[(int)state[7]] & 0x40) != 0 &&
        (NEAR_MASK[(int)state[8]] & 0x40) != 0;
}

fn bool is_goal(long* state) {
    return state[0] == 5 && state[1] == 6 && state[2] == 12 &&
        state[3] == 13 && state[4] == 14 && state[5] == 15 &&
        state[6] + state[7] + state[8] == 3;
}

fn void apply_move(long* state, int movement, bool upper, long* next) {
    for (int piece = 0; piece < PIECE_COUNT; piece++) {
        int index = movement * 18 + (int)state[piece];
        next[piece] = (long)(upper ? UPPER_MOVES[index] : LOWER_MOVES[index]);
    }
}

fn bool search_down(long* state, int bound, int depth, int last_move);

fn bool search_up(long* state, int bound, int depth, int last_move) {
    if (depth == bound - 4 && !near_enough(state)) return false;
    if (is_goal(state)) return true;
    if (bound <= depth) return false;
    for (int movement = 0; movement < 3; movement++) {
        if (movement == last_move) continue;
        long[9] next = {0};
        apply_move(state, movement, true, &next[0]);
        if (search_down(&next[0], bound, depth + 1, movement)) return true;
    }
    return false;
}

fn bool search_down(long* state, int bound, int depth, int last_move) {
    if (bound <= depth) return false;
    for (int movement = 0; movement < 3; movement++) {
        if (movement == last_move) continue;
        long[9] next = {0};
        apply_move(state, movement, false, &next[0]);
        if (search_up(&next[0], bound, depth + 1, movement)) return true;
    }
    return false;
}

fn long freebench_mason(long* input, usz length) @export("freebench_mason") {
    if (input == null || length != PIECE_COUNT) return -1;
    ulong used = 0;
    for (int piece = 0; piece < PIECE_COUNT; piece++) {
        long position = input[piece];
        if (position < 0 || position >= 18) return -1;
        ulong bit = (ulong)1 << (ulong)position;
        if ((used & bit) != 0) return -1;
        used |= bit;
    }
    for (int bound = 2; bound <= MAX_DEPTH; bound += 2) {
        if (search_up(input, bound, 0, -1)) return (long)bound;
    }
    return -2;
}
