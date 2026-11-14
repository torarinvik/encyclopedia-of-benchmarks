// Independent bounded maximum-area triangle draft; uncompiled and unrun.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t maximum_area_triangle_convex(const std::int64_t* input,
                                                       std::size_t length) {
    if (!input || !length || input[0] < 3 || input[0] > 1024) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * n) return -1;
    for (std::size_t i = 1; i < length; ++i)
        if (input[i] < -1000000 || input[i] > 1000000) return -1;
    auto cross = [&](std::size_t a, std::size_t b, std::size_t c) -> std::int64_t {
        const auto ax = input[1 + 2 * a], ay = input[2 + 2 * a];
        return (input[1 + 2 * b] - ax) * (input[2 + 2 * c] - ay)
             - (input[2 + 2 * b] - ay) * (input[1 + 2 * c] - ax);
    };
    for (std::size_t i = 0; i < n; ++i) {
        const auto next = (i + 1) % n;
        for (std::size_t j = 0; j < n; ++j)
            if (j != i && j != next && cross(i, next, j) <= 0) return -1;
    }
    std::int64_t best = 0;
    for (std::size_t i = 0; i + 2 < n; ++i) {
        for (std::size_t j = i + 1; j + 1 < n; ++j) {
            std::size_t lo = j + 1, hi = n - 1;
            while (lo < hi) {
                const auto mid = lo + (hi - lo) / 2;
                if (cross(i, j, mid) < cross(i, j, mid + 1)) lo = mid + 1;
                else hi = mid;
            }
            const auto value = cross(i, j, lo);
            if (value > best) best = value;
        }
    }
    return best;
}
