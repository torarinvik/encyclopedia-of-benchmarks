#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 100000;
constexpr std::size_t max_parseable_length = 2;

std::int64_t sum_digits(std::int64_t value) {
    std::int64_t result = 0;
    for (; value != 0; value /= 10) result += value % 10;
    return result;
}

std::int64_t multiply_digits(std::int64_t value) {
    std::int64_t result = 1;
    while (value != 0) {
        result *= value % 10;
        value /= 10;
    }
    return result;
}

std::int64_t reduce_sum_root(std::int64_t value) {
    for (; value >= 10; value = sum_digits(value)) {}
    return value;
}

std::int64_t reduce_product_root(std::int64_t value) {
    for (; value >= 10; value = multiply_digits(value)) {}
    return value;
}

bool is_dividuus(std::int64_t n) {
    const std::int64_t values[] = {
        sum_digits(n), multiply_digits(n), reduce_sum_root(n), reduce_product_root(n)
    };
    for (const std::int64_t divisor : values) if (divisor == 0) return false;
    for (const std::int64_t divisor : values) if (n % divisor != 0) return false;
    return true;
}
}

extern "C" std::int64_t dividuus_number_predicate(const std::int64_t *input,
                                                  std::size_t length) {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (length != 1 || input[0] < 1 || input[0] > max_n) return -1;
    return is_dividuus(input[0]) ? 1 : 0;
}
