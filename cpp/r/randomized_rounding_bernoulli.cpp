#include <cstddef>
#include <cstdint>

extern "C" std::int64_t randomized_rounding_bernoulli(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    constexpr std::size_t max_n = 16, max_input = 65;
    if (!input || length < 5 || length > max_input) return -1;
    const auto n64 = input[0];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(max_n) ||
        length != 1 + 4 * static_cast<std::size_t>(n64)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    std::uint8_t staged[max_n]{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto x_num=input[1+4*i], x_den=input[2+4*i];
        const auto u_num=input[3+4*i], u_den=input[4+4*i];
        if (x_den < 1 || x_den > 32 || x_num < 0 || x_num > x_den ||
            u_den < 1 || u_den > 32 || u_num < 0 || u_num >= u_den) return -1;
        staged[i] = static_cast<std::uint8_t>(u_num*x_den < x_num*u_den);
    }
    if (!output || capacity < n) return -2;
    for (std::size_t i=0;i<n;++i) output[i]=staged[i];
    return static_cast<std::int64_t>(n);
}
