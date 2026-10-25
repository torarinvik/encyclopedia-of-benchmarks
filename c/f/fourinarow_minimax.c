#include <stddef.h>
#include <stdint.h>

#define MAX_HISTORY 20
#define MAX_DEPTH 7
#define HUGE_SCORE 100000

static const uint64_t C4V = (UINT64_C(1) << 0) | (UINT64_C(1) << 7) | (UINT64_C(1) << 14) | (UINT64_C(1) << 21);
static const uint64_t C3V = C4V >> 7;
static const uint64_t C2V = C3V >> 7;
static const uint64_t C4H = UINT64_C(15);
static const uint64_t C3H = C4H >> 1;
static const uint64_t C2H = C3H >> 1;
static const uint64_t C4UR = (UINT64_C(1) << 0) | (UINT64_C(1) << 8) | (UINT64_C(1) << 16) | (UINT64_C(1) << 24);
static const uint64_t C3UR = C4UR >> 8;
static const uint64_t C2UR = C3UR >> 8;
static const uint64_t C4UL = (UINT64_C(1) << 3) | (UINT64_C(1) << 9) | (UINT64_C(1) << 15) | (UINT64_C(1) << 21);
static const uint64_t C3UL = C4UL >> 6;
static const uint64_t C2UL = C3UL >> 6;

static int has(uint64_t board, uint64_t pattern) { return (board & pattern) == pattern; }

static int score_board(uint64_t human, uint64_t computer) {
    int total = 0;
    for (int player = 0; player < 2; ++player) {
        uint64_t b = player == 0 ? human : computer;
        uint64_t other = player == 0 ? computer : human;
        int sign = player == 0 ? -1 : 1;
        for (int i = 0; i < 21; ++i)
            if (has(b, C4V << i)) total += sign * 1000;
        for (int i = 0; i < 6; ++i) for (int j = 0; j < 4; ++j)
            if (has(b, C4H << (j + i * 6))) total += sign * 1000;
        for (int i = 0; i < 3; ++i) for (int j = 0; j < 4; ++j) {
            if (has(b, C4UR << (j + i * 6))) total += sign * 1000;
            if (has(b, C4UL << (j + i * 6))) total += sign * 1000;
        }
        for (int i = 0; i < 21; ++i)
            if (has(b, C3V << i) && !(other & (C4V << i))) total += sign * 20;
        for (int i = 0; i < 6; ++i) for (int j = 0; j < 5; ++j)
            if (has(b, C3H << (j + i * 6))) total += sign * 20;
        for (int i = 0; i < 3; ++i) for (int j = 0; j < 4; ++j) {
            if (has(b, C3UR << (j + i * 6))) total += sign * 20;
            if (has(b, C3UL << (j + i * 6))) total += sign * 20;
        }
        for (int i = 0; i < 21; ++i)
            if (has(b, C2V << i) && !(other & (C4V << i))) total += sign * 5;
        for (int i = 0; i < 6; ++i) for (int j = 0; j < 6; ++j)
            if (has(b, C2H << (j + i * 6))) total += sign * 5;
        for (int i = 0; i < 3; ++i) for (int j = 0; j < 4; ++j) {
            if (has(b, C2UR << (j + i * 6))) total += sign * 5;
            if (has(b, C2UL << (j + i * 6))) total += sign * 5;
        }
    }
    return total;
}

static int wins(uint64_t board) {
    for (int row = 0; row < 6; ++row) for (int col = 0; col < 7; ++col) {
        int bit = col + row * 7;
        for (int dcol = 0; dcol <= 1; ++dcol) for (int drow = -1; drow <= 1; ++drow) {
            if (dcol == 0 && drow <= 0) continue;
            int end_col = col + 3 * dcol, end_row = row + 3 * drow;
            if (end_col >= 7 || end_row < 0 || end_row >= 6) continue;
            uint64_t line = UINT64_C(1) << bit;
            for (int k = 1; k < 4; ++k)
                line |= UINT64_C(1) << (col + k * dcol + (row + k * drow) * 7);
            if ((board & line) == line) return 1;
        }
    }
    return 0;
}

static int search(uint64_t human, uint64_t computer, int side, int level, int limit,
                  int mode, int alpha, int beta) {
    if (level >= limit) return score_board(human, computer);
    if (side == 2) {
        int best = -HUGE_SCORE;
        for (int col = 0; col < 7; ++col) {
            int row = 0;
            while (row < 6 && ((human | computer) & (UINT64_C(1) << (col + row * 7)))) ++row;
            if (row == 6) continue;
            int value = search(human, computer | (UINT64_C(1) << (col + row * 7)), 1,
                               level + 1, limit, mode, best, beta);
            if (value > best) best = value;
            if (mode == 2 && best > beta) return best;
        }
        return best;
    }
    int best = HUGE_SCORE;
    for (int col = 0; col < 7; ++col) {
        int row = 0;
        while (row < 6 && ((human | computer) & (UINT64_C(1) << (col + row * 7)))) ++row;
        if (row == 6) continue;
        int value = search(human | (UINT64_C(1) << (col + row * 7)), computer, 2,
                           level + 1, limit, mode, alpha, best);
        if (value <= best) best = value;
        if (mode == 2 && best < alpha) return best;
    }
    return best;
}

static int choose(uint64_t human, uint64_t computer, int side, int depth, int mode) {
    int best = side == 2 ? -HUGE_SCORE : HUGE_SCORE;
    int best_col = 0;
    for (int col = 0; col < 7; ++col) {
        int row = 0;
        while (row < 6 && ((human | computer) & (UINT64_C(1) << (col + row * 7)))) ++row;
        if (row == 6) continue;
        int value = side == 2
            ? search(human, computer | (UINT64_C(1) << (col + row * 7)), 1, 2, depth, mode, best, HUGE_SCORE)
            : search(human | (UINT64_C(1) << (col + row * 7)), computer, 2, 2, depth, mode, -HUGE_SCORE, best);
        if ((side == 2 && value > best) || (side == 1 && value <= best)) { best = value; best_col = col; }
        if (mode == 2 && ((side == 2 && best > HUGE_SCORE) || (side == 1 && best < -HUGE_SCORE))) break;
    }
    return best * 8 + best_col;
}

int64_t fourinarow_minimax(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > 4 + MAX_HISTORY) return -1;
    int64_t depth = input[0], mode = input[1], side = input[2], count = input[3];
    if (depth < 2 || depth > MAX_DEPTH || (mode != 0 && mode != 2) ||
        (side != 1 && side != 2) || count < 0 || count > MAX_HISTORY || length != 4 + (size_t)count ||
        side != (count % 2 == 0 ? 1 : 2)) return -1;
    uint64_t human = 0, computer = 0;
    int heights[7] = {0};
    for (int64_t turn = 0; turn < count; ++turn) {
        int64_t col = input[4 + (size_t)turn];
        if (col < 0 || col >= 7 || heights[col] >= 6) return -1;
        int player = turn % 2 == 0 ? 1 : 2;
        uint64_t bit = UINT64_C(1) << ((int)col + heights[col] * 7);
        if (player == 1) human |= bit; else computer |= bit;
        ++heights[col];
        if (wins(player == 1 ? human : computer)) return -1;
    }
    return choose(human, computer, (int)side, (int)depth, (int)mode);
}
