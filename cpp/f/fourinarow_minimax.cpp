#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxHistory = 20, kMaxDepth = 7, kHuge = 100000;
constexpr std::uint64_t kC4V = (1ull << 0) | (1ull << 7) | (1ull << 14) | (1ull << 21);
constexpr std::uint64_t kC3V = kC4V >> 7, kC2V = kC3V >> 7;
constexpr std::uint64_t kC4H = 15, kC3H = kC4H >> 1, kC2H = kC3H >> 1;
constexpr std::uint64_t kC4UR = (1ull << 0) | (1ull << 8) | (1ull << 16) | (1ull << 24);
constexpr std::uint64_t kC3UR = kC4UR >> 8, kC2UR = kC3UR >> 8;
constexpr std::uint64_t kC4UL = (1ull << 3) | (1ull << 9) | (1ull << 15) | (1ull << 21);
constexpr std::uint64_t kC3UL = kC4UL >> 6, kC2UL = kC3UL >> 6;

bool has(std::uint64_t board, std::uint64_t mask) { return (board & mask) == mask; }
int score_board(std::uint64_t human, std::uint64_t computer) {
    int total = 0;
    for (int player = 0; player < 2; ++player) {
        const std::uint64_t b = player == 0 ? human : computer;
        const std::uint64_t other = player == 0 ? computer : human;
        const int sign = player == 0 ? -1 : 1;
        for (int i = 0; i < 21; ++i) if (has(b, kC4V << i)) total += sign * 1000;
        for (int i = 0; i < 6; ++i) for (int j = 0; j < 4; ++j)
            if (has(b, kC4H << (j + i * 6))) total += sign * 1000;
        for (int i = 0; i < 3; ++i) for (int j = 0; j < 4; ++j) {
            if (has(b, kC4UR << (j + i * 6))) total += sign * 1000;
            if (has(b, kC4UL << (j + i * 6))) total += sign * 1000;
        }
        for (int i = 0; i < 21; ++i) if (has(b, kC3V << i) && !(other & (kC4V << i))) total += sign * 20;
        for (int i = 0; i < 6; ++i) for (int j = 0; j < 5; ++j)
            if (has(b, kC3H << (j + i * 6))) total += sign * 20;
        for (int i = 0; i < 3; ++i) for (int j = 0; j < 4; ++j) {
            if (has(b, kC3UR << (j + i * 6))) total += sign * 20;
            if (has(b, kC3UL << (j + i * 6))) total += sign * 20;
        }
        for (int i = 0; i < 21; ++i) if (has(b, kC2V << i) && !(other & (kC4V << i))) total += sign * 5;
        for (int i = 0; i < 6; ++i) for (int j = 0; j < 6; ++j)
            if (has(b, kC2H << (j + i * 6))) total += sign * 5;
        for (int i = 0; i < 3; ++i) for (int j = 0; j < 4; ++j) {
            if (has(b, kC2UR << (j + i * 6))) total += sign * 5;
            if (has(b, kC2UL << (j + i * 6))) total += sign * 5;
        }
    }
    return total;
}
bool wins(std::uint64_t board) {
    for (int row = 0; row < 6; ++row) for (int col = 0; col < 7; ++col) {
        for (int dc = 0; dc <= 1; ++dc) for (int dr = -1; dr <= 1; ++dr) {
            if (dc == 0 && dr <= 0) continue;
            const int ec = col + 3 * dc, er = row + 3 * dr;
            if (ec >= 7 || er < 0 || er >= 6) continue;
            std::uint64_t line = 0;
            for (int k = 0; k < 4; ++k) line |= 1ull << (col + k * dc + (row + k * dr) * 7);
            if ((board & line) == line) return true;
        }
    }
    return false;
}
int search(std::uint64_t human, std::uint64_t computer, int side, int level, int limit,
           int mode, int alpha, int beta) {
    if (level >= limit) return score_board(human, computer);
    if (side == 2) {
        int best = -kHuge;
        for (int col = 0; col < 7; ++col) {
            int row = 0;
            while (row < 6 && ((human | computer) & (1ull << (col + row * 7)))) ++row;
            if (row == 6) continue;
            const int value = search(human, computer | (1ull << (col + row * 7)), 1,
                                     level + 1, limit, mode, best, beta);
            if (value > best) best = value;
            if (mode == 2 && best > beta) return best;
        }
        return best;
    }
    int best = kHuge;
    for (int col = 0; col < 7; ++col) {
        int row = 0;
        while (row < 6 && ((human | computer) & (1ull << (col + row * 7)))) ++row;
        if (row == 6) continue;
        const int value = search(human | (1ull << (col + row * 7)), computer, 2,
                                 level + 1, limit, mode, alpha, best);
        if (value <= best) best = value;
        if (mode == 2 && best < alpha) return best;
    }
    return best;
}
std::int64_t evaluate(std::uint64_t human, std::uint64_t computer, int side, int depth, int mode) {
    int best = side == 2 ? -kHuge : kHuge, best_col = 0;
    for (int col = 0; col < 7; ++col) {
        int row = 0;
        while (row < 6 && ((human | computer) & (1ull << (col + row * 7)))) ++row;
        if (row == 6) continue;
        const int value = side == 2
            ? search(human, computer | (1ull << (col + row * 7)), 1, 2, depth, mode, best, kHuge)
            : search(human | (1ull << (col + row * 7)), computer, 2, 2, depth, mode, -kHuge, best);
        if ((side == 2 && value > best) || (side == 1 && value <= best)) { best = value; best_col = col; }
    }
    return static_cast<std::int64_t>(best) * 8 + best_col;
}
} // namespace

extern "C" std::int64_t fourinarow_minimax(const std::int64_t *input, std::size_t length) {
    if (!input || length < 4 || length > 4 + kMaxHistory) return -1;
    const std::int64_t depth = input[0], mode = input[1], side = input[2], count = input[3];
    if (depth < 2 || depth > kMaxDepth || (mode != 0 && mode != 2) || (side != 1 && side != 2) ||
        count < 0 || count > kMaxHistory || length != 4 + static_cast<std::size_t>(count) ||
        side != (count % 2 == 0 ? 1 : 2)) return -1;
    std::uint64_t human = 0, computer = 0;
    int heights[7] = {};
    for (std::int64_t turn = 0; turn < count; ++turn) {
        const std::int64_t col = input[4 + static_cast<std::size_t>(turn)];
        if (col < 0 || col >= 7 || heights[col] >= 6) return -1;
        const int row = heights[col]++;
        const std::uint64_t bit = 1ull << (static_cast<int>(col) + row * 7);
        if (turn % 2 == 0) human |= bit; else computer |= bit;
        if (wins(turn % 2 == 0 ? human : computer)) return -1;
    }
    return evaluate(human, computer, static_cast<int>(side), static_cast<int>(depth), static_cast<int>(mode));
}
