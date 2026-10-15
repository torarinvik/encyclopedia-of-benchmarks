// Three reciprocal thin-lens formula solves.
#include <cstddef>
#include <cstdint>

extern "C" double lens_formulae(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return -1.0e300;
    const std::int64_t operation = values[0];
    const std::int64_t first = values[1];
    const std::int64_t second = values[2];
    if (operation < 0 || operation > 2 || first == 0 || second == 0 ||
        first < -1'000'000 || first > 1'000'000 || second < -1'000'000 || second > 1'000'000)
        return -1.0e300;
    if (operation == 0) {
        if (first == second) return -1.0e300;
        return 1.0 / ((1.0 / static_cast<double>(second)) - (1.0 / static_cast<double>(first)));
    }
    if (operation == 1) {
        if (first == second) return -1.0e300;
        return 1.0 / ((1.0 / static_cast<double>(second)) - (1.0 / static_cast<double>(first)));
    }
    if (first == -second) return -1.0e300;
    return 1.0 / ((1.0 / static_cast<double>(second)) + (1.0 / static_cast<double>(first)));
}
