#include <cstddef>
#include <cstdint>
static std::int64_t josephus_solve(std::int64_t n, std::int64_t step) {
    if (n == 1) return 0;
    return (josephus_solve(n - 1, step) + step % n) % n;
}
extern "C" std::int64_t josephus_problem_recursive(const std::int64_t *values, std::size_t length) noexcept {
    if (length != 2) return -1;
    const auto n = values[0], step = values[1];
    if (n < 1 || n > 256 || step < 1) return -1;
    return josephus_solve(n, step) + 1;
}
