#include <cstddef>
#include <cstdint>

static constexpr std::int64_t MAX_VALUE = 1000000000000LL;

static std::int64_t decimal_exponent(std::int64_t base) {
    if (base < 1) return -1;
    std::int64_t exponent = 0;
    while (base > 1 && base % 10 == 0) {
        base /= 10;
        ++exponent;
    }
    return base == 1 ? exponent : -1;
}

static bool valid_base(std::int64_t base) {
    return base == 0 || decimal_exponent(base) >= 0;
}

static std::int64_t source_score(std::int64_t base, std::int64_t exponent) {
    if (base == 0) return 0;
    if (exponent == 0) return 1;
    return decimal_exponent(base) * exponent;
}

extern "C" std::int64_t largest_of_very_large_numbers(const std::int64_t* values,
                                                       std::size_t length) {
    if (values == nullptr || length != 4) return -2;
    for (std::size_t i = 0; i < 4; ++i) if (values[i] < 0 || values[i] > MAX_VALUE) return -2;
    if (!valid_base(values[0]) || !valid_base(values[2])) return -2;
    const std::int64_t a = source_score(values[0], values[1]);
    const std::int64_t b = source_score(values[2], values[3]);
    return (a > b) - (a < b);
}
