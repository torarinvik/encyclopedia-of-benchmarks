#include <cstddef>
#include <cstdint>

extern "C" std::int64_t tsvc_s423_antidependence_offset64(const std::int64_t *input, std::size_t length) {
    constexpr std::size_t min_n = 65, max_n = 128, x_length = max_n + 64;
    if (input == nullptr || length < min_n + 65 || length > max_n + 65) return -1;
    if (input[0] < static_cast<std::int64_t>(min_n) || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (length != n + 65) return -1;
    std::int64_t a[max_n]{};
    std::int64_t x[x_length]{};
    for (std::size_t i = 0; i < n; ++i) {
        a[i] = input[1+i];
        if (a[i] < 0 || a[i] > 2) return -1;
    }
    for (std::size_t i = 0; i < 64; ++i) {
        x[i] = input[1+n+i];
        if (x[i] < 0 || x[i] > 2) return -1;
    }
    for (std::size_t i = 64; i < n+64; ++i) x[i] = 1;
    for (std::size_t i = 0; i < n-1; ++i) x[i+1] = x[i+64] + a[i];
    std::int64_t sum = 0;
    for (std::size_t i = 0; i < n; ++i) sum += x[i];
    return sum;
}
