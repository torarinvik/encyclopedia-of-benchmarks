#include <stddef.h>
#include <stdint.h>

#define PIECE_COUNT 9
#define POSITION_COUNT 18
#define MAX_DEPTH 8
#define INVALID_RESULT (-1)
#define NO_SOLUTION_RESULT (-2)

typedef struct {
    int p[PIECE_COUNT];
} mason_state;

static const int upper_moves[3][POSITION_COUNT] = {
    {0, 8, 1, 2, 16, 5, 13, 7, 14, 9, 3, 4, 11, 12, 15, 10, 17, 6},
    {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17},
    {1, 2, 9, 10, 4, 17, 6, 0, 8, 15, 11, 12, 5, 13, 7, 14, 3, 16}
};

static const int lower_moves[3][POSITION_COUNT] = {
    {0, 2, 3, 10, 11, 5, 17, 7, 1, 9, 15, 12, 13, 6, 8, 14, 4, 16},
    {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17},
    {7, 0, 1, 16, 4, 12, 6, 14, 8, 2, 3, 10, 11, 13, 15, 9, 17, 5}
};

static const int near_mask[POSITION_COUNT] = {
    0x50, 0x70, 0x70, 0x75, 0x0f, 0x0f, 0x0f, 0x70, 0x70,
    0x70, 0x7d, 0x2b, 0x2f, 0x0f, 0x50, 0x64, 0x67, 0x0f
};

static int near_enough(mason_state state) {
    return (near_mask[state.p[1]] & 0x02) != 0
        && (near_mask[state.p[3]] & 0x08) != 0
        && (near_mask[state.p[4]] & 0x10) != 0
        && (near_mask[state.p[5]] & 0x20) != 0
        && (near_mask[state.p[0]] & 0x01) != 0
        && (near_mask[state.p[2]] & 0x04) != 0
        && (near_mask[state.p[6]] & 0x40) != 0
        && (near_mask[state.p[7]] & 0x40) != 0
        && (near_mask[state.p[8]] & 0x40) != 0;
}

static int is_goal(mason_state state) {
    return state.p[0] == 5 && state.p[1] == 6 && state.p[2] == 12
        && state.p[3] == 13 && state.p[4] == 14 && state.p[5] == 15
        && state.p[6] + state.p[7] + state.p[8] == 3;
}

static mason_state apply_move(mason_state state, const int map[POSITION_COUNT]) {
    mason_state result;
    for (int piece = 0; piece < PIECE_COUNT; ++piece) result.p[piece] = map[state.p[piece]];
    return result;
}

static int search_down(mason_state state, int max_depth, int depth, int last_move);

static int search_up(mason_state state, int max_depth, int depth, int last_move) {
    if (depth == max_depth - 4 && !near_enough(state)) return 0;
    if (is_goal(state)) return 1;
    if (max_depth <= depth) return 0;
    for (int move = 0; move < 3; ++move) {
        if (move == last_move) continue;
        const mason_state next = apply_move(state, upper_moves[move]);
        if (search_down(next, max_depth, depth + 1, move)) return 1;
    }
    return 0;
}

static int search_down(mason_state state, int max_depth, int depth, int last_move) {
    if (max_depth <= depth) return 0;
    for (int move = 0; move < 3; ++move) {
        if (move == last_move) continue;
        const mason_state next = apply_move(state, lower_moves[move]);
        if (search_up(next, max_depth, depth + 1, move)) return 1;
    }
    return 0;
}

int64_t freebench_mason(const int64_t *input, size_t length) {
    if (input == NULL || length != PIECE_COUNT) return INVALID_RESULT;
    mason_state start;
    unsigned int used = 0;
    for (int piece = 0; piece < PIECE_COUNT; ++piece) {
        const int64_t position = input[piece];
        if (position < 0 || position >= POSITION_COUNT) return INVALID_RESULT;
        const unsigned int bit = 1u << (unsigned int)position;
        if ((used & bit) != 0) return INVALID_RESULT;
        used |= bit;
        start.p[piece] = (int)position;
    }
    for (int depth = 2; depth <= MAX_DEPTH; depth += 2) {
        if (search_up(start, depth, 0, -1)) return depth;
    }
    return NO_SOLUTION_RESULT;
}
