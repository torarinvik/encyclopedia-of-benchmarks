#include <cstddef>
#include <cstdint>
extern "C" std::int64_t josephus_problem(const std::int64_t *values, std::size_t length) noexcept {
    if (length != 2) return -1;
    const auto n = values[0], step = values[1];
    if (n < 1 || n > 100000 || step < 1) return -1;
    std::int64_t winner = 0;
    for (std::int64_t size = 1; size <= n; ++size) winner = (winner + step % size) % size;
    return winner + 1;
}
