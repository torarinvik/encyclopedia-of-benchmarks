// GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
// Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
// Upstream countlib/count are under GNU GPL version 1; this derivative is licensed under GNU GPL version 1.
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t prolangs_c_gnugo_liberty_count(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > 726) return -1;
    const auto row = input[0], col = input[1], color = input[2], count = input[3];
    if (row < 0 || row >= 19 || col < 0 || col >= 19 || (color != 1 && color != 2) ||
        count < 0 || count > 361 || length != 4 + 2 * static_cast<std::size_t>(count)) return -1;
    std::array<std::uint8_t, 361> board{}, seen{}, liberties{};
    for (std::int64_t k = 0; k < count; ++k) {
        const auto at = input[4 + 2 * static_cast<std::size_t>(k)], stone = input[5 + 2 * static_cast<std::size_t>(k)];
        if (at < 0 || at >= 361 || (stone != 1 && stone != 2) || board[static_cast<std::size_t>(at)]) return -1;
        board[static_cast<std::size_t>(at)] = static_cast<std::uint8_t>(stone);
    }
    const int start = static_cast<int>(row * 19 + col);
    if (board[static_cast<std::size_t>(start)] != color) return -1;
    std::array<int, 361> stack{}; std::size_t top = 0; int total = 0;
    stack[top++] = start; seen[static_cast<std::size_t>(start)] = 1;
    while (top) {
        const int at = stack[--top], r = at / 19, c = at % 19;
        int neighbors[4], n = 0;
        if (r > 0) neighbors[n++] = at - 19;
        if (r < 18) neighbors[n++] = at + 19;
        if (c > 0) neighbors[n++] = at - 1;
        if (c < 18) neighbors[n++] = at + 1;
        for (int j = 0; j < n; ++j) {
            const auto next = static_cast<std::size_t>(neighbors[j]);
            if (board[next] == 0) { if (!liberties[next]) { liberties[next] = 1; ++total; } }
            else if (board[next] == color && !seen[next]) { seen[next] = 1; stack[top++] = neighbors[j]; }
        }
    }
    return total;
}
