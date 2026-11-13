#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t cell_count = 16;

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length != cell_count) return -1;

    std::int64_t blank = -1;
    for (std::size_t i = 0; i < cell_count; ++i) {
        if (input[i] < 0 || input[i] >= 16) return -1;
        for (std::size_t j = 0; j < i; ++j) {
            if (input[i] == input[j]) return -1;
        }
        if (input[i] == 0) blank = static_cast<std::int64_t>(i);
    }
    if (blank < 0) return -1;

    std::int64_t inversions = 0;
    for (std::size_t i = 0; i < cell_count; ++i) {
        if (input[i] == 0) continue;
        for (std::size_t j = i + 1; j < cell_count; ++j) {
            if (input[j] != 0 && input[i] > input[j]) ++inversions;
        }
    }
    const auto blank_row_from_top = blank / 4 + 1;
    return (inversions + blank_row_from_top) % 2 == 0 ? 1 : 0;
}
}  // namespace

extern "C" std::int64_t fifteen_puzzle_solvability(
    const std::int64_t* input, std::size_t length) noexcept {
    return solve(input, length);
}
