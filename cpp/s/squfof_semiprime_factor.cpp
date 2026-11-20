#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_number = 1'000'000'000'000LL;
constexpr std::int64_t max_steps = 256;

std::int64_t isqrt(std::int64_t value, std::int64_t upper) {
    std::int64_t low = 0, high = upper + 1;
    while (low + 1 < high) {
        const auto middle = low + (high - low) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

std::int64_t gcd(std::int64_t left, std::int64_t right) {
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

std::int64_t reverse_walk(std::int64_t number, std::int64_t discriminant,
                          std::int64_t a, std::int64_t p, std::int64_t q,
                          std::int64_t cap) {
    const auto root = isqrt(q, 1'414'214);
    if (root * root != q) return 0;
    const auto quotient = (a - p) / root;
    auto r = quotient * root + p;
    auto previous_s = root;
    auto s = (discriminant - r * r) / root;
    for (std::int64_t step = 0; step < cap; ++step) {
        const auto next_quotient = (a + r) / s;
        const auto next_r = next_quotient * s - r;
        if (next_r == r) {
            const auto factor = gcd(number, r);
            if (factor > 1 && factor < number) {
                const auto other = number / factor;
                return factor < other ? factor : other;
            }
            return 0;
        }
        const auto next_s = previous_s + next_quotient * (r - next_r);
        previous_s = s;
        s = next_s;
        r = next_r;
    }
    return 0;
}
}

extern "C" std::int64_t squfof_semiprime_factor(const std::int64_t *input,
                                                std::size_t length) noexcept {
    if (input == nullptr || length != 3) return -1;
    const auto number = input[0];
    const auto forward_cap = input[1];
    const auto reverse_cap = input[2];
    if (number < 3 || number > max_number || number % 2 == 0
        || forward_cap < 0 || forward_cap > max_steps
        || reverse_cap < 0 || reverse_cap > max_steps) return -1;
    const auto exact_root = isqrt(number, 1'000'000);
    if (exact_root * exact_root == number) return exact_root;
    const auto discriminant = number % 4 == 1 ? 2 * number : number;
    const auto a = isqrt(discriminant, 1'414'214);
    auto previous_q = std::int64_t{1};
    auto q = discriminant - a * a;
    auto p = a;
    auto index = std::int64_t{1};
    for (std::int64_t step = 0; step < forward_cap; ++step) {
        const auto quotient = (a + p) / q;
        const auto next_p = quotient * q - p;
        const auto next_q = previous_q + quotient * (p - next_p);
        previous_q = q;
        q = next_q;
        p = next_p;
        ++index;
        if (index % 2 == 0) {
            const auto factor = reverse_walk(number, discriminant, a, p, q, reverse_cap);
            if (factor != 0) return factor;
        }
    }
    return 0;
}
