#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_cases = 4;
constexpr std::size_t max_vectors = 8;
constexpr int max_bits = 30;
constexpr std::size_t max_input_values = 1 + max_cases * (2 + 2 * max_vectors) + 1;
constexpr std::size_t max_output_words = max_cases * (1 + max_vectors);
constexpr std::uint32_t max_vector = 0x3fffffffU;

bool insert_independent(std::array<std::uint32_t, max_bits> &basis, std::uint32_t value) {
    auto row = value;
    for (int bit = max_bits - 1; bit >= 0; --bit) {
        if (((row >> bit) & 1U) == 0) continue;
        if (basis[static_cast<std::size_t>(bit)] != 0) row ^= basis[static_cast<std::size_t>(bit)];
        else {
            basis[static_cast<std::size_t>(bit)] = row;
            return true;
        }
    }
    return false;
}

std::size_t intersection_basis(const std::array<std::uint32_t, max_vectors> &left,
    std::size_t n, const std::array<std::uint32_t, max_vectors> &right, std::size_t m,
    std::array<std::uint32_t, max_vectors> &output) {
    std::array<std::uint32_t, max_bits> right_basis{};
    std::array<std::uint32_t, max_bits> right_coeff{};
    for (std::size_t index = 0; index < m; ++index) {
        auto row = right[index];
        auto coefficients = std::uint32_t{1} << index;
        for (int bit = max_bits - 1; bit >= 0; --bit) {
            const auto slot = static_cast<std::size_t>(bit);
            if (((row >> bit) & 1U) == 0) continue;
            if (right_basis[slot] != 0) {
                row ^= right_basis[slot];
                coefficients ^= right_coeff[slot];
            } else {
                right_basis[slot] = row;
                right_coeff[slot] = coefficients;
                break;
            }
        }
    }

    std::array<std::uint32_t, max_bits> quotient_basis{};
    std::array<std::uint32_t, max_bits> quotient_left_coeff{};
    std::array<std::uint32_t, max_bits> quotient_right_coeff{};
    std::array<std::uint32_t, max_vectors> intersection{};
    std::size_t intersection_count = 0;
    for (std::size_t index = 0; index < n; ++index) {
        auto row = left[index];
        std::uint32_t right_mask = 0;
        for (int bit = max_bits - 1; bit >= 0; --bit) {
            const auto slot = static_cast<std::size_t>(bit);
            if (((row >> bit) & 1U) != 0 && right_basis[slot] != 0) {
                row ^= right_basis[slot];
                right_mask ^= right_coeff[slot];
            }
        }
        auto left_mask = std::uint32_t{1} << index;
        for (int bit = max_bits - 1; bit >= 0; --bit) {
            const auto slot = static_cast<std::size_t>(bit);
            if (((row >> bit) & 1U) == 0) continue;
            if (quotient_basis[slot] != 0) {
                row ^= quotient_basis[slot];
                left_mask ^= quotient_left_coeff[slot];
                right_mask ^= quotient_right_coeff[slot];
            } else {
                quotient_basis[slot] = row;
                quotient_left_coeff[slot] = left_mask;
                quotient_right_coeff[slot] = right_mask;
                break;
            }
        }
        if (row == 0) {
            std::uint32_t common = 0;
            for (std::size_t source = 0; source < n; ++source)
                if (((left_mask >> source) & 1U) != 0) common ^= left[source];
            intersection[intersection_count++] = common;
        }
    }

    std::array<std::uint32_t, max_bits> rref{};
    for (std::size_t index = 0; index < intersection_count; ++index) {
        auto row = intersection[index];
        for (int bit = max_bits - 1; bit >= 0; --bit) {
            const auto slot = static_cast<std::size_t>(bit);
            if (((row >> bit) & 1U) == 0) continue;
            if (rref[slot] != 0) row ^= rref[slot];
            else {
                rref[slot] = row;
                for (int pivot = 0; pivot < max_bits; ++pivot) {
                    const auto other = static_cast<std::size_t>(pivot);
                    if (pivot != bit && ((rref[other] >> bit) & 1U) != 0)
                        rref[other] ^= row;
                }
                break;
            }
        }
    }
    std::size_t output_count = 0;
    for (int bit = max_bits - 1; bit >= 0; --bit)
        if (rref[static_cast<std::size_t>(bit)] != 0)
            output[output_count++] = rref[static_cast<std::size_t>(bit)];
    return output_count;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t intersection_of_f2_vector_spaces(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_input_values) return -1;
    const auto case_count_value = input[0];
    if (case_count_value < 1 || case_count_value > static_cast<std::int64_t>(max_cases)) return -1;
    const auto case_count = static_cast<std::size_t>(case_count_value);
    std::array<std::int64_t, max_output_words> staged{};
    std::size_t used = 0, cursor = 1;
    for (std::size_t case_index = 0; case_index < case_count; ++case_index) {
        if (cursor >= length) return -1;
        const auto n_value = input[cursor++];
        if (n_value < 0 || n_value > static_cast<std::int64_t>(max_vectors)) return -1;
        const auto n = static_cast<std::size_t>(n_value);
        if (cursor + n > length) return -1;
        std::array<std::uint32_t, max_vectors> left{};
        std::array<std::uint32_t, max_bits> left_check{};
        for (std::size_t index = 0; index < n; ++index) {
            const auto value = input[cursor++];
            if (value < 0 || value > max_vector ||
                !insert_independent(left_check, static_cast<std::uint32_t>(value))) return -1;
            left[index] = static_cast<std::uint32_t>(value);
        }
        if (cursor >= length) return -1;
        const auto m_value = input[cursor++];
        if (m_value < 0 || m_value > static_cast<std::int64_t>(max_vectors)) return -1;
        const auto m = static_cast<std::size_t>(m_value);
        if (cursor + m > length) return -1;
        std::array<std::uint32_t, max_vectors> right{};
        std::array<std::uint32_t, max_bits> right_check{};
        for (std::size_t index = 0; index < m; ++index) {
            const auto value = input[cursor++];
            if (value < 0 || value > max_vector ||
                !insert_independent(right_check, static_cast<std::uint32_t>(value))) return -1;
            right[index] = static_cast<std::uint32_t>(value);
        }
        std::array<std::uint32_t, max_vectors> basis{};
        const auto dimension = intersection_basis(left, n, right, m, basis);
        staged[used++] = static_cast<std::int64_t>(dimension);
        for (std::size_t index = 0; index < dimension; ++index)
            staged[used++] = static_cast<std::int64_t>(basis[index]);
    }
    if (cursor != length) return -1;
    const auto required = 8 * used;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < used; ++index)
        store_i64_le(output, 8 * index, staged[index]);
    return static_cast<std::int64_t>(required);
}
