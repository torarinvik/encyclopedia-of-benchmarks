#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_cells = 16;
constexpr std::size_t max_length = 19;
constexpr std::size_t max_topples = 1488;
}

extern "C" std::int64_t abelian_sandpile_stabilization(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_length) return -1;
    if (input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 4) return -1;
    const auto rows = static_cast<std::size_t>(input[0]);
    const auto cols = static_cast<std::size_t>(input[1]);
    const auto cells = rows * cols;
    if (length != 2 + cells) return -1;

    std::array<std::int64_t, max_cells> board{};
    for (std::size_t site = 0; site < cells; ++site) {
        const auto height = input[2 + site];
        if (height < 0 || height > 31) return -1;
        board[site] = height;
    }

    std::array<std::size_t, max_cells> queue{};
    std::array<bool, max_cells> queued{};
    std::size_t head = 0, tail = 0, count = 0;
    const auto enqueue = [&](std::size_t site) {
        if (board[site] >= 4 && !queued[site]) {
            queue[tail] = site;
            tail = (tail + 1) % cells;
            ++count;
            queued[site] = true;
        }
    };
    for (std::size_t site = 0; site < cells; ++site) enqueue(site);

    std::size_t topples = 0;
    while (count != 0) {
        const auto site = queue[head];
        head = (head + 1) % cells;
        --count;
        queued[site] = false;
        if (board[site] < 4) continue;
        const auto row = site / cols;
        const auto col = site % cols;
        board[site] -= 4;
        if (++topples > max_topples) return -1;
        if (row > 0) { const auto next = site - cols; ++board[next]; enqueue(next); }
        if (col + 1 < cols) { const auto next = site + 1; ++board[next]; enqueue(next); }
        if (row + 1 < rows) { const auto next = site + cols; ++board[next]; enqueue(next); }
        if (col > 0) { const auto next = site - 1; ++board[next]; enqueue(next); }
        enqueue(site);
    }

    std::int64_t result = 0;
    std::int64_t place = 1;
    for (std::size_t site = 0; site < cells; ++site) {
        result += board[site] * place;
        place *= 4;
    }
    return result;
}
