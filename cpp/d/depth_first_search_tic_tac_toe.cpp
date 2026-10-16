#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int lines[8][3] = {{0,1,2},{3,4,5},{6,7,8},{0,3,6},{1,4,7},{2,5,8},{0,4,8},{2,4,6}};
bool won(const std::array<int64_t, 9>& board, int player) {
    for (const auto& line : lines)
        if (board[line[0]] == player && board[line[1]] == player && board[line[2]] == player) return true;
    return false;
}
int search(std::array<int64_t, 9>& board, int side) {
    if (won(board, 1) || won(board, 2)) return -1;
    bool available = false;
    for (auto cell : board) available |= cell == 0;
    if (!available) return -1;
    const int other = 3 - side;
    int best_rank = -1, best_score = 0, best_mask = 0;
    for (int i = 0; i < 9; ++i) if (board[i] == 0) {
        board[i] = side;
        int score;
        if (won(board, 1)) score = 1;
        else if (won(board, 2)) score = 2;
        else { const int child = search(board, other); score = child < 0 ? 0 : child / 512; }
        board[i] = 0;
        const int rank = score == side ? 2 : (score == 0 ? 1 : 0);
        if (rank > best_rank) { best_rank = rank; best_score = score; best_mask = 1 << i; }
        else if (rank == best_rank) best_mask |= 1 << i;
    }
    return best_score * 512 + best_mask;
}
}

extern "C" int64_t depth_first_search_tic_tac_toe(const int64_t* values, std::size_t length) {
    if (values == nullptr || length != 10 || (values[0] != 1 && values[0] != 2)) return -1;
    std::array<int64_t, 9> board{};
    for (int i = 0; i < 9; ++i) { if (values[i + 1] < 0 || values[i + 1] > 2) return -1; board[i] = values[i + 1]; }
    const int result = search(board, static_cast<int>(values[0]));
    return result < 0 ? 0 : 1 + result;
}
