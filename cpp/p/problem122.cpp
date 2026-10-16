#include <array>
#include <cstddef>
#include <cstdint>

namespace {
bool solve(std::array<std::int64_t, 32>& chain, std::size_t length, std::int64_t goal, std::size_t depth) {
    const auto last = chain[length - 1];
    for (std::size_t index = 0; index < length; ++index) {
        const auto next = chain[index] + last;
        if (next == goal) return true;
        if (next > goal) break;
        if (length < depth) { chain[length] = next; if (solve(chain, length + 1, goal, depth)) return true; }
    }
    return false;
}
}
extern "C" std::int64_t problem122(std::int64_t maximum) noexcept {
    if (maximum < 0 || maximum > 200) return -1;
    std::int64_t total = 0;
    for (std::int64_t goal = 2; goal <= maximum; ++goal) {
        std::array<std::int64_t, 32> chain{}; chain[0] = 1;
        std::size_t depth = 0;
        do { ++depth; chain[0] = 1; } while (!solve(chain, 1, goal, depth));
        total += static_cast<std::int64_t>(depth);
    }
    return total;
}
