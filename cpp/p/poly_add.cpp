#include <cstddef>
#include <cstdint>

static constexpr std::size_t MAX_TERMS = 16;
static constexpr std::size_t MAX_INPUT_VALUES = 67;
static constexpr std::size_t MAX_OUTPUT_TERMS = 32;

static void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

static bool validate_terms(const std::int64_t *input, std::size_t start, std::size_t count) noexcept {
    std::int64_t previous_degree = 64;
    for (std::size_t i = 0; i < count; ++i) {
        const auto coefficient = input[start + 2 * i];
        const auto degree = input[start + 2 * i + 1];
        if (coefficient < -1000000 || coefficient > 1000000
            || degree < 0 || degree > 63 || degree >= previous_degree) return false;
        previous_degree = degree;
    }
    return true;
}

extern "C" std::int64_t poly_add(const std::int64_t *input, std::size_t length,
                                  std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const auto count_a_value = input[0];
    if (count_a_value < 1 || count_a_value > static_cast<std::int64_t>(MAX_TERMS)) return -1;
    const auto count_a = static_cast<std::size_t>(count_a_value);
    const std::size_t count_b_index = 1 + 2 * count_a;
    if (length <= count_b_index) return -1;
    const auto count_b_value = input[count_b_index];
    if (count_b_value < 1 || count_b_value > static_cast<std::int64_t>(MAX_TERMS)) return -1;
    const auto count_b = static_cast<std::size_t>(count_b_value);
    if (length != 2 + 2 * (count_a + count_b)) return -1;

    const std::size_t start_a = 1;
    const std::size_t start_b = count_b_index + 1;
    if (!validate_terms(input, start_a, count_a) || !validate_terms(input, start_b, count_b)) return -1;

    std::int64_t coefficients[MAX_OUTPUT_TERMS];
    std::int64_t degrees[MAX_OUTPUT_TERMS];
    std::size_t i = 0, j = 0, terms = 0;
    while (i < count_a && j < count_b) {
        const auto coefficient_a = input[start_a + 2 * i];
        const auto degree_a = input[start_a + 2 * i + 1];
        const auto coefficient_b = input[start_b + 2 * j];
        const auto degree_b = input[start_b + 2 * j + 1];
        if (degree_a > degree_b) {
            coefficients[terms] = coefficient_a; degrees[terms++] = degree_a; ++i;
        } else if (degree_a < degree_b) {
            coefficients[terms] = coefficient_b; degrees[terms++] = degree_b; ++j;
        } else {
            coefficients[terms] = coefficient_a + coefficient_b; degrees[terms++] = degree_a;
            ++i; ++j;
        }
    }
    while (i < count_a) {
        coefficients[terms] = input[start_a + 2 * i];
        degrees[terms++] = input[start_a + 2 * i + 1]; ++i;
    }
    while (j < count_b) {
        coefficients[terms] = input[start_b + 2 * j];
        degrees[terms++] = input[start_b + 2 * j + 1]; ++j;
    }

    const std::size_t required = terms * 16;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t term = 0; term < terms; ++term) {
        put_i64_le(output, term * 16, coefficients[term]);
        put_i64_le(output, term * 16 + 8, degrees[term]);
    }
    return static_cast<std::int64_t>(required);
}
