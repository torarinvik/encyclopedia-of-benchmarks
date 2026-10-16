module depth_first_search_tic_tac_toe;

fn bool won(long* board, long player) {
    for (int row = 0; row < 3; row++) if (board[row * 3] == player && board[row * 3 + 1] == player && board[row * 3 + 2] == player) return true;
    for (int col = 0; col < 3; col++) if (board[col] == player && board[col + 3] == player && board[col + 6] == player) return true;
    return (board[0] == player && board[4] == player && board[8] == player)
        || (board[2] == player && board[4] == player && board[6] == player);
}

fn int search(long* board, int side) {
    if (won(board, 1) || won(board, 2)) return -1;
    bool available = false;
    for (int i = 0; i < 9; i++) if (board[i] == 0) available = true;
    if (!available) return -1;
    int other = 3 - side;
    int best_rank = -1;
    int best_score = 0;
    int best_mask = 0;
    for (int i = 0; i < 9; i++) if (board[i] == 0) {
        board[i] = side;
        int score;
        if (won(board, 1)) { score = 1; }
        else if (won(board, 2)) { score = 2; }
        else { int child = search(board, other); score = child < 0 ? 0 : child / 512; }
        board[i] = 0;
        int rank = score == side ? 2 : (score == 0 ? 1 : 0);
        if (rank > best_rank) { best_rank = rank; best_score = score; best_mask = 1 << i; }
        else if (rank == best_rank) best_mask |= 1 << i;
    }
    return best_score * 512 + best_mask;
}

fn long depth_first_search_tic_tac_toe(long* values, usz length) @export("depth_first_search_tic_tac_toe") {
    if (values == null || length != 10 || (values[0] != 1 && values[0] != 2)) return -1;
    long[9] board;
    for (int i = 0; i < 9; i++) { if (values[i + 1] < 0 || values[i + 1] > 2) return -1; board[i] = values[i + 1]; }
    int result = search(&board[0], (int)values[0]);
    return result < 0 ? 0 : 1 + (long)result;
}
