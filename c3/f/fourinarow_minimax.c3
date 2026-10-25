module fourinarow_minimax;

const int MAX_HISTORY = 20, MAX_DEPTH = 7, HUGE_SCORE = 100000;
const ulong C4V = ((ulong)1 << 0) | ((ulong)1 << 7) | ((ulong)1 << 14) | ((ulong)1 << 21);
const ulong C3V = C4V >> 7, C2V = C3V >> 7;
const ulong C4H = 15, C3H = C4H >> 1, C2H = C3H >> 1;
const ulong C4UR = ((ulong)1 << 0) | ((ulong)1 << 8) | ((ulong)1 << 16) | ((ulong)1 << 24);
const ulong C3UR = C4UR >> 8, C2UR = C3UR >> 8;
const ulong C4UL = ((ulong)1 << 3) | ((ulong)1 << 9) | ((ulong)1 << 15) | ((ulong)1 << 21);
const ulong C3UL = C4UL >> 6, C2UL = C3UL >> 6;

fn bool has(ulong board, ulong mask) { return (board & mask) == mask; }
fn int score_board(ulong human, ulong computer) {
    int total = 0;
    for (int player = 0; player < 2; player++) {
        ulong b = player == 0 ? human : computer;
        ulong other = player == 0 ? computer : human;
        int sign = player == 0 ? -1 : 1;
        for (int i = 0; i < 21; i++) if (has(b, C4V << i)) total += sign * 1000;
        for (int i = 0; i < 6; i++) for (int j = 0; j < 4; j++) if (has(b, C4H << (j + i * 6))) total += sign * 1000;
        for (int i = 0; i < 3; i++) for (int j = 0; j < 4; j++) {
            if (has(b, C4UR << (j + i * 6))) total += sign * 1000;
            if (has(b, C4UL << (j + i * 6))) total += sign * 1000;
        }
        for (int i = 0; i < 21; i++) if (has(b, C3V << i) && !(other & (C4V << i))) total += sign * 20;
        for (int i = 0; i < 6; i++) for (int j = 0; j < 5; j++) if (has(b, C3H << (j + i * 6))) total += sign * 20;
        for (int i = 0; i < 3; i++) for (int j = 0; j < 4; j++) {
            if (has(b, C3UR << (j + i * 6))) total += sign * 20;
            if (has(b, C3UL << (j + i * 6))) total += sign * 20;
        }
        for (int i = 0; i < 21; i++) if (has(b, C2V << i) && !(other & (C4V << i))) total += sign * 5;
        for (int i = 0; i < 6; i++) for (int j = 0; j < 6; j++) if (has(b, C2H << (j + i * 6))) total += sign * 5;
        for (int i = 0; i < 3; i++) for (int j = 0; j < 4; j++) {
            if (has(b, C2UR << (j + i * 6))) total += sign * 5;
            if (has(b, C2UL << (j + i * 6))) total += sign * 5;
        }
    }
    return total;
}
fn bool wins(ulong board) {
    for (int row = 0; row < 6; row++) for (int col = 0; col < 7; col++) {
        for (int dc = 0; dc <= 1; dc++) for (int dr = -1; dr <= 1; dr++) {
            if (dc == 0 && dr <= 0) continue;
            int ec = col + 3 * dc, er = row + 3 * dr;
            if (ec >= 7 || er < 0 || er >= 6) continue;
            ulong line = 0;
            for (int k = 0; k < 4; k++) line |= (ulong)1 << (col + k * dc + (row + k * dr) * 7);
            if ((board & line) == line) return true;
        }
    }
    return false;
}
fn int search(ulong human, ulong computer, int side, int level, int limit, int mode, int alpha, int beta) {
    if (level >= limit) return score_board(human, computer);
    if (side == 2) {
        int best = -HUGE_SCORE;
        for (int col = 0; col < 7; col++) {
            int row = 0;
            while (row < 6 && ((human | computer) & ((ulong)1 << (col + row * 7))) != 0) row++;
            if (row == 6) continue;
            int value = search(human, computer | ((ulong)1 << (col + row * 7)), 1, level + 1, limit, mode, best, beta);
            if (value > best) best = value;
            if (mode == 2 && best > beta) return best;
        }
        return best;
    }
    int best = HUGE_SCORE;
    for (int col = 0; col < 7; col++) {
        int row = 0;
        while (row < 6 && ((human | computer) & ((ulong)1 << (col + row * 7))) != 0) row++;
        if (row == 6) continue;
        int value = search(human | ((ulong)1 << (col + row * 7)), computer, 2, level + 1, limit, mode, alpha, best);
        if (value <= best) best = value;
        if (mode == 2 && best < alpha) return best;
    }
    return best;
}
fn long evaluate(ulong human, ulong computer, int side, int depth, int mode) {
    int best = side == 2 ? -HUGE_SCORE : HUGE_SCORE, best_col = 0;
    for (int col = 0; col < 7; col++) {
        int row = 0;
        while (row < 6 && ((human | computer) & ((ulong)1 << (col + row * 7))) != 0) row++;
        if (row == 6) continue;
        int value = side == 2
            ? search(human, computer | ((ulong)1 << (col + row * 7)), 1, 2, depth, mode, best, HUGE_SCORE)
            : search(human | ((ulong)1 << (col + row * 7)), computer, 2, 2, depth, mode, -HUGE_SCORE, best);
        if ((side == 2 && value > best) || (side == 1 && value <= best)) { best = value; best_col = col; }
    }
    return (long)best * 8 + best_col;
}

fn long fourinarow_minimax(long* input, usz length) @export("fourinarow_minimax") {
    if (input == null || length < 4 || length > 4 + MAX_HISTORY) return -1;
    long depth = input[0], mode = input[1], side = input[2], count = input[3];
    if (depth < 2 || depth > MAX_DEPTH || (mode != 0 && mode != 2) || (side != 1 && side != 2) ||
        count < 0 || count > MAX_HISTORY || length != 4 + (usz)count || side != (count % 2 == 0 ? 1 : 2)) return -1;
    ulong human = 0, computer = 0;
    int[7] heights = {0};
    for (long turn = 0; turn < count; turn++) {
        long col = input[4 + (usz)turn];
        if (col < 0 || col >= 7 || heights[(int)col] >= 6) return -1;
        ulong bit = (ulong)1 << ((int)col + heights[(int)col] * 7);
        if (turn % 2 == 0) human |= bit; else computer |= bit;
        heights[(int)col]++;
        if (wins(turn % 2 == 0 ? human : computer)) return -1;
    }
    return evaluate(human, computer, (int)side, (int)depth, (int)mode);
}
