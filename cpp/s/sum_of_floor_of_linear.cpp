#include <cstddef>
#include <cstdint>

namespace {
std::int64_t floor_sum(std::int64_t n, std::int64_t m,
                       std::int64_t a, std::int64_t b) noexcept {
    std::int64_t answer = 0;
    for (;;) {
        if (a >= m) {
            const std::int64_t quotient = a / m;
            std::int64_t left = n;
            std::int64_t right = n - 1;
            if (left % 2 == 0) left /= 2;
            else right /= 2;
            answer += left * right * quotient;
            a %= m;
        }
        if (b >= m) {
            answer += n * (b / m);
            b %= m;
        }
        const std::int64_t numerator = a * n + b;
        const std::int64_t height = numerator / m;
        if (height == 0) return answer;
        b = numerator % m;
        n = height;
        const std::int64_t previous_m = m;
        m = a;
        a = previous_m;
    }
}
} // namespace

extern "C" std::int64_t sum_of_floor_of_linear(const std::int64_t* input,
                                                std::size_t length) noexcept {
    constexpr std::int64_t max_parameter = INT64_C(1000000000);
    if (input == nullptr || length != 4) return -1;
    const std::int64_t n = input[0];
    const std::int64_t m = input[1];
    const std::int64_t a = input[2];
    const std::int64_t b = input[3];
    if (n < 1 || n > max_parameter || m < 1 || m > max_parameter
        || a < 0 || a >= m || b < 0 || b >= m) return -1;
    return floor_sum(n, m, a, b);
}
