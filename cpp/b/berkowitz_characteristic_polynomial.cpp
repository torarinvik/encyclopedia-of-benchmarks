#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 7;
constexpr std::size_t max_input_words = 52;

std::int64_t residue(std::int64_t value, std::int64_t modulus) {
    const auto result = value % modulus;
    return result < 0 ? result + modulus : result;
}

std::int64_t negative_residue(std::int64_t value, std::int64_t modulus) {
    return value == 0 ? 0 : modulus - value;
}

void store_i64_le(std::uint8_t *output, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t berkowitz_characteristic_polynomial(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_input_words) return -1;
    const auto n64 = input[0];
    const auto modulus = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(max_n)
        || modulus < 2 || modulus > 1'000'000'000) return -1;
    const auto n = static_cast<std::size_t>(n64);
    if (length != 2 + n * n) return -1;

    std::array<std::int64_t, max_n * max_n> matrix{};
    for (std::size_t i = 0; i < n * n; ++i) {
        const auto entry = input[i + 2];
        if (entry < -1'000'000 || entry > 1'000'000) return -1;
        matrix[i] = residue(entry, modulus);
    }
    const auto output_bytes = (n + 1) * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;

    std::array<std::int64_t, max_n + 1> coefficients{};
    std::array<std::int64_t, max_n + 1> current{};
    std::array<std::int64_t, max_n + 1> toeplitz{};
    std::array<std::int64_t, max_n> vector{};
    std::array<std::int64_t, max_n> next_vector{};
    coefficients[0] = 1;
    for (std::size_t size = 1; size <= n; ++size) {
        const auto start = n - size;
        const auto block = size - 1;
        for (std::size_t i = 0; i <= size; ++i) toeplitz[i] = 0;
        toeplitz[0] = 1;
        toeplitz[1] = negative_residue(matrix[start * n + start], modulus);
        for (std::size_t row = 0; row < block; ++row)
            vector[row] = matrix[(start + 1 + row) * n + start];

        for (std::size_t power = 0; power < block; ++power) {
            std::int64_t dot = 0;
            for (std::size_t col = 0; col < block; ++col)
                dot = (dot + matrix[start * n + start + 1 + col] * vector[col]) % modulus;
            toeplitz[power + 2] = negative_residue(dot, modulus);
            for (std::size_t row = 0; row < block; ++row) {
                std::int64_t value = 0;
                for (std::size_t col = 0; col < block; ++col)
                    value = (value + matrix[(start + 1 + row) * n + start + 1 + col]
                                      * vector[col]) % modulus;
                next_vector[row] = value;
            }
            for (std::size_t row = 0; row < block; ++row) vector[row] = next_vector[row];
        }

        for (std::size_t i = 0; i <= size; ++i) {
            std::int64_t value = 0;
            const auto last_child = i < size - 1 ? i : size - 1;
            for (std::size_t j = 0; j <= last_child; ++j)
                value = (value + toeplitz[i - j] * coefficients[j]) % modulus;
            current[i] = value;
        }
        for (std::size_t i = 0; i <= size; ++i) coefficients[i] = current[i];
    }
    for (std::size_t i = 0; i <= n; ++i) store_i64_le(output, i, coefficients[i]);
    return static_cast<std::int64_t>(output_bytes);
}
