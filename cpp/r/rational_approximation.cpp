#include <cstddef>
#include <cstdint>

namespace {
struct RationalBounds {
    std::int64_t lower_numerator;
    std::int64_t lower_denominator;
    std::int64_t upper_numerator;
    std::int64_t upper_denominator;
};

std::int64_t gcd_positive(std::int64_t left, std::int64_t right) noexcept {
    while (right != 0) {
        const std::int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

RationalBounds bounded_neighbors(std::int64_t limit, std::int64_t x,
                                 std::int64_t y) noexcept {
    const std::int64_t divisor = gcd_positive(x, y);
    const std::int64_t reduced_x = x / divisor;
    const std::int64_t reduced_y = y / divisor;
    if (reduced_x <= limit && reduced_y <= limit) {
        return {reduced_x, reduced_y, reduced_x, reduced_y};
    }

    std::int64_t a = 0, b = 1;
    std::int64_t c = 1, d = 0;
    while (true) {
        const std::int64_t middle_numerator = a + c;
        const std::int64_t middle_denominator = b + d;
        if (middle_numerator > limit || middle_denominator > limit) break;

        const std::int64_t target_side = middle_numerator * y;
        const std::int64_t middle_side = middle_denominator * x;
        if (target_side == middle_side) {
            return {middle_numerator, middle_denominator,
                    middle_numerator, middle_denominator};
        }
        if (target_side < middle_side) {
            const std::int64_t lower_gap = b * x - a * y;
            const std::int64_t upper_gap = c * y - d * x;
            std::int64_t step = lower_gap / upper_gap;
            const std::int64_t numerator_cap = (limit - a) / c;
            if (step > numerator_cap) step = numerator_cap;
            if (d > 0) {
                const std::int64_t denominator_cap = (limit - b) / d;
                if (step > denominator_cap) step = denominator_cap;
            }
            a += step * c;
            b += step * d;
        } else {
            const std::int64_t upper_gap = c * y - d * x;
            const std::int64_t lower_gap = b * x - a * y;
            std::int64_t step = upper_gap / lower_gap;
            if (a > 0) {
                const std::int64_t numerator_cap = (limit - c) / a;
                if (step > numerator_cap) step = numerator_cap;
            }
            const std::int64_t denominator_cap = (limit - d) / b;
            if (step > denominator_cap) step = denominator_cap;
            c += step * a;
            d += step * b;
        }
    }
    return {a, b, c, d};
}

void store_i64_le(std::uint8_t* output, std::size_t offset,
                  std::int64_t value) noexcept {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>((bits >> (byte * 8)) & 0xffu);
    }
}
} // namespace

extern "C" std::int64_t rational_approximation(const std::int64_t* values,
                                               std::size_t length,
                                               std::uint8_t* output,
                                               std::size_t capacity) noexcept {
    if (values == nullptr || length != 3) return -1;
    const std::int64_t limit = values[0];
    const std::int64_t x = values[1];
    const std::int64_t y = values[2];
    if (limit < 1 || limit > INT64_C(1000000000)
        || x < 1 || x > INT64_C(1000000000)
        || y < 1 || y > INT64_C(1000000000)) return -1;
    if (output == nullptr || capacity < 32) return -2;

    const RationalBounds bounds = bounded_neighbors(limit, x, y);
    store_i64_le(output, 0, bounds.lower_numerator);
    store_i64_le(output, 8, bounds.lower_denominator);
    store_i64_le(output, 16, bounds.upper_numerator);
    store_i64_le(output, 24, bounds.upper_denominator);
    return 32;
}
