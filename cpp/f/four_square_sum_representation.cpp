#include <cstddef>
#include <cstdint>

namespace {
std::int64_t floor_sqrt(std::int64_t value) noexcept {
    std::int64_t root = 0;
    while ((root + 1) * (root + 1) <= value) ++root;
    return root;
}

std::int64_t pack(std::int64_t a, std::int64_t b, std::int64_t c, std::int64_t d) noexcept {
    return (((a * 33 + b) * 33 + c) * 33 + d);
}
} // namespace

extern "C" std::int64_t four_square_sum_representation(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 1) return -1;
    const auto n = input[0];
    if (n < 0 || n > 1024) return -1;

    for (auto a = floor_sqrt(n); a >= 0; --a) {
        const auto rem_a = n - a * a;
        auto b_max = floor_sqrt(rem_a);
        if (b_max > a) b_max = a;
        for (auto b = b_max; b >= 0; --b) {
            const auto rem_b = rem_a - b * b;
            auto c_max = floor_sqrt(rem_b);
            if (c_max > b) c_max = b;
            for (auto c = c_max; c >= 0; --c) {
                const auto rem_c = rem_b - c * c;
                const auto d = floor_sqrt(rem_c);
                if (d <= c && d * d == rem_c) return pack(a, b, c, d);
            }
        }
    }
    return -2;
}
