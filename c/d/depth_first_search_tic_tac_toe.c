#include <stddef.h>
#include <stdint.h>

static const int lines[8][3] = {{0,1,2},{3,4,5},{6,7,8},{0,3,6},{1,4,7},{2,5,8},{0,4,8},{2,4,6}};

static int won(const int64_t *board, int player) {
    for (int line = 0; line < 8; ++line)
        if (board[lines[line][0]] == player && board[lines[line][1]] == player && board[lines[line][2]] == player) return 1;
    return 0;
}

/* Encodes recursive Some(score, mask) as score*512+mask; -1 is terminal None. */
static int search(int64_t *board, int side) {
    if (won(board, 1) || won(board, 2)) return -1;
    int available = 0;
    for (int i = 0; i < 9; ++i) available += board[i] == 0;
    if (!available) return -1;
    int other = 3 - side, best_rank = -1, best_score = 0, best_mask = 0;
    for (int i = 0; i < 9; ++i) if (board[i] == 0) {
        board[i] = side;
        int score;
        if (won(board, 1)) score = 1;
        else if (won(board, 2)) score = 2;
        else { int child = search(board, other); score = child < 0 ? 0 : child / 512; }
        board[i] = 0;
        int rank = score == side ? 2 : score == 0 ? 1 : 0;
        if (rank > best_rank) { best_rank = rank; best_score = score; best_mask = 1 << i; }
        else if (rank == best_rank) best_mask |= 1 << i;
    }
    return best_score * 512 + best_mask;
}

int64_t depth_first_search_tic_tac_toe(const int64_t *values, size_t length) {
    if (values == NULL || length != 10 || (values[0] != 1 && values[0] != 2)) return -1;
    int64_t board[9];
    for (int i = 0; i < 9; ++i) { if (values[i + 1] < 0 || values[i + 1] > 2) return -1; board[i] = values[i + 1]; }
    int result = search(board, (int)values[0]);
    return result < 0 ? 0 : 1 + result;
}
