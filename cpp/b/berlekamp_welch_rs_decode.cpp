#include <cstddef>
#include <cstdint>

namespace {
constexpr int field = 7;
constexpr std::size_t max_n = 7;
constexpr std::size_t max_k = 3;
constexpr std::size_t max_t = 2;
constexpr std::size_t max_vars = 8;
constexpr std::size_t max_poly = 5;

int mod7(int value) noexcept {
    value %= field;
    return value < 0 ? value + field : value;
}

int inverse7(int value) noexcept {
    constexpr int inverses[7] = {0, 1, 4, 5, 2, 3, 6};
    return inverses[value];
}

std::int64_t decode(std::size_t n, std::size_t k, std::size_t errors,
                    const std::int64_t received[max_n]) noexcept {
    const std::size_t q_count = k + errors;
    const std::size_t e_count = errors + 1;
    const std::size_t variable_count = q_count + e_count;
    int matrix[max_n][max_vars]{};

    for (std::size_t row = 0; row < n; ++row) {
        int powers[max_poly] = {1, 0, 0, 0, 0};
        for (std::size_t degree = 1; degree < max_poly; ++degree)
            powers[degree] = powers[degree - 1] * static_cast<int>(row) % field;
        for (std::size_t degree = 0; degree < q_count; ++degree)
            matrix[row][degree] = powers[degree];
        for (std::size_t degree = 0; degree < e_count; ++degree)
            matrix[row][q_count + degree] = mod7(-static_cast<int>(received[row]) * powers[degree]);
    }

    std::size_t pivot_columns[max_vars]{};
    bool is_pivot[max_vars]{};
    std::size_t pivot_row = 0;
    for (std::size_t column = 0; column < variable_count && pivot_row < n; ++column) {
        std::size_t found = pivot_row;
        while (found < n && matrix[found][column] == 0) ++found;
        if (found == n) continue;
        for (std::size_t c = 0; c < variable_count; ++c) {
            const int temporary = matrix[pivot_row][c];
            matrix[pivot_row][c] = matrix[found][c];
            matrix[found][c] = temporary;
        }
        const int inverse = inverse7(matrix[pivot_row][column]);
        for (std::size_t c = 0; c < variable_count; ++c)
            matrix[pivot_row][c] = matrix[pivot_row][c] * inverse % field;
        for (std::size_t row = 0; row < n; ++row) {
            if (row == pivot_row) continue;
            const int factor = matrix[row][column];
            if (factor == 0) continue;
            for (std::size_t c = 0; c < variable_count; ++c)
                matrix[row][c] = mod7(matrix[row][c] - factor * matrix[pivot_row][c]);
        }
        pivot_columns[pivot_row] = column;
        is_pivot[column] = true;
        ++pivot_row;
    }

    std::size_t free_column = variable_count;
    for (std::size_t column = 0; column < variable_count; ++column) {
        if (!is_pivot[column]) { free_column = column; break; }
    }
    if (free_column == variable_count) return 0;
    int solution[max_vars]{};
    solution[free_column] = 1;
    for (std::size_t row = 0; row < pivot_row; ++row)
        solution[pivot_columns[row]] = mod7(-matrix[row][free_column]);

    int numerator[max_poly]{};
    int locator[max_poly]{};
    for (std::size_t degree = 0; degree < q_count; ++degree) numerator[degree] = solution[degree];
    for (std::size_t degree = 0; degree < e_count; ++degree) locator[degree] = solution[q_count + degree];
    bool locator_zero = true;
    for (std::size_t degree = 0; degree < e_count; ++degree)
        if (locator[degree] != 0) locator_zero = false;
    if (locator_zero) return 0;
    std::size_t locator_degree = e_count - 1;
    while (locator_degree > 0 && locator[locator_degree] == 0) --locator_degree;

    int remainder[max_poly]{};
    for (std::size_t degree = 0; degree < q_count; ++degree) remainder[degree] = numerator[degree];
    std::size_t remainder_degree = q_count - 1;
    while (remainder_degree > 0 && remainder[remainder_degree] == 0) --remainder_degree;
    bool numerator_zero = true;
    for (std::size_t degree = 0; degree < q_count; ++degree)
        if (remainder[degree] != 0) numerator_zero = false;

    int quotient[max_poly]{};
    std::size_t quotient_count = 1;
    if (!numerator_zero && remainder_degree >= locator_degree)
        quotient_count = remainder_degree - locator_degree + 1;
    const int inverse_lead = inverse7(locator[locator_degree]);
    while (!numerator_zero && remainder_degree >= locator_degree) {
        const std::size_t shift = remainder_degree - locator_degree;
        const int factor = remainder[remainder_degree] * inverse_lead % field;
        quotient[shift] = factor;
        for (std::size_t degree = 0; degree <= locator_degree; ++degree)
            remainder[shift + degree] = mod7(remainder[shift + degree] - factor * locator[degree]);
        while (remainder_degree > 0 && remainder[remainder_degree] == 0) --remainder_degree;
        numerator_zero = true;
        for (std::size_t degree = 0; degree < q_count; ++degree)
            if (remainder[degree] != 0) numerator_zero = false;
    }
    for (std::size_t degree = 0; degree < q_count; ++degree)
        if (remainder[degree] != 0) return 0;
    if (quotient_count > k) return 0;

    int coefficients[max_k]{};
    for (std::size_t degree = 0; degree < quotient_count; ++degree)
        coefficients[degree] = quotient[degree];
    std::size_t mismatches = 0;
    for (std::size_t x = 0; x < n; ++x) {
        int value = 0;
        for (std::size_t degree = k; degree > 0; --degree)
            value = (value * static_cast<int>(x) + coefficients[degree - 1]) % field;
        if (value != received[x]) ++mismatches;
    }
    if (mismatches > errors) return 0;

    std::int64_t result = 1;
    std::int64_t place = 1;
    for (std::size_t degree = 0; degree < k; ++degree) {
        result += coefficients[degree] * place;
        place *= field;
    }
    return result;
}
} // namespace

extern "C" std::int64_t berlekamp_welch_rs_decode(const std::int64_t *input,
                                                   std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > 11) return -1;
    const std::int64_t n_value = input[0];
    const std::int64_t k_value = input[1];
    const std::int64_t t_value = input[2];
    if (n_value < 2 || n_value > static_cast<std::int64_t>(max_n)
        || k_value < 1 || k_value > static_cast<std::int64_t>(max_k)
        || k_value > n_value || t_value < 0 || t_value > static_cast<std::int64_t>(max_t)
        || 2 * t_value > n_value - k_value) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    const std::size_t k = static_cast<std::size_t>(k_value);
    const std::size_t errors = static_cast<std::size_t>(t_value);
    if (length != 3 + n) return -1;
    std::int64_t received[max_n]{};
    for (std::size_t index = 0; index < n; ++index) {
        const std::int64_t symbol = input[3 + index];
        if (symbol < 0 || symbol >= field) return -1;
        received[index] = symbol;
    }
    return decode(n, k, errors, received);
}
