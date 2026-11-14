#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t backward_nondeterministic_dawg_match(const std::int64_t* values, std::size_t length) {
    if (values == nullptr || length < 2 || values[0] < 0 || values[0] > 4096 ||
        values[1] < 0 || values[1] > 63) return -2;
    const auto n = static_cast<std::size_t>(values[0]);
    const auto m = static_cast<std::size_t>(values[1]);
    if (length != 2 + n + m) return -2;
    for (std::size_t i = 2; i < length; ++i)
        if (values[i] < 97 || values[i] > 122) return -2;
    if (m == 0) return 0;
    if (m > n) return -1;

    std::array<std::uint64_t, 26> masks{};
    for (std::size_t i = 0; i < m; ++i)
        masks[static_cast<std::size_t>(values[2 + n + i] - 97)] |= std::uint64_t{1} << (m - 1 - i);
    for (std::size_t start = 0; start <= n - m;) {
        auto remaining = m;
        auto shift = m;
        auto states = UINT64_MAX;
        while (remaining > 0 && states != 0) {
            --remaining;
            states &= masks[static_cast<std::size_t>(values[2 + start + remaining] - 97)];
            if (states != 0) {
                if (remaining == 0) return static_cast<std::int64_t>(start);
                shift = remaining;
            }
            states <<= 1;
        }
        start += shift;
    }
    return -1;
}
