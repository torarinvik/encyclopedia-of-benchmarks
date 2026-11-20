#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr int kN = 8;
constexpr int kEdges = 28;
constexpr std::size_t kMaxInput = 87;
constexpr std::size_t kMaxOutput = 80;
constexpr std::int64_t kPrime = 65521;

std::int64_t norm(std::int64_t value) {
    value %= kPrime;
    return value < 0 ? value + kPrime : value;
}

std::int64_t power(std::int64_t base, std::uint64_t exponent) {
    std::int64_t result = 1;
    std::int64_t factor = norm(base);
    while (exponent != 0) {
        if ((exponent & 1U) != 0) result = result * factor % kPrime;
        factor = factor * factor % kPrime;
        exponent >>= 1U;
    }
    return result;
}

void store_word(std::array<std::uint8_t, kMaxOutput>& bytes,
                std::size_t word, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        bytes[word * 8 + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8U;
    }
}

bool eliminate(std::array<std::int64_t, kN * kN>& inverse,
               std::array<bool, kN>& active_rows,
               std::array<bool, kN>& active_columns,
               int n, int pivot_row, int pivot_column) {
    const auto old = inverse;
    const auto pivot = old[pivot_row * kN + pivot_column];
    if (pivot == 0) return false;
    const auto inverse_pivot = power(pivot, static_cast<std::uint64_t>(kPrime - 2));
    for (int row = 0; row < n; ++row) {
        for (int column = 0; column < n; ++column) {
            const int index = row * kN + column;
            if (active_rows[row] && row != pivot_row && active_columns[column] &&
                column != pivot_column) {
                const auto correction = old[row * kN + pivot_column] *
                                        old[pivot_row * kN + column] % kPrime;
                inverse[index] = norm(old[index] - correction * inverse_pivot);
            } else {
                inverse[index] = 0;
            }
        }
    }
    active_rows[pivot_row] = false;
    active_columns[pivot_column] = false;
    return true;
}
} // namespace

extern "C" std::int64_t tutte_matrix_randomized_perfect_matching(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInput) return -1;
    const auto n_value = input[0];
    const auto edge_count_value = input[1];
    if (n_value < 2 || n_value > kN || (n_value & 1) != 0 ||
        edge_count_value < 0 || edge_count_value > kEdges) return -1;
    const int n = static_cast<int>(n_value);
    const int edge_count = static_cast<int>(edge_count_value);
    if (edge_count > n * (n - 1) / 2 || length != static_cast<std::size_t>(2 + 3 * edge_count)) return -1;

    std::array<std::int64_t, kN * kN> matrix{};
    std::int64_t previous_u = -1, previous_v = -1;
    for (int edge = 0; edge < edge_count; ++edge) {
        const auto u_value = input[2 + 3 * edge];
        const auto v_value = input[3 + 3 * edge];
        const auto substitution = input[4 + 3 * edge];
        if (u_value < 0 || v_value <= u_value || v_value >= n ||
            u_value < previous_u || (u_value == previous_u && v_value <= previous_v) ||
            substitution < 1 || substitution >= kPrime) return -1;
        const int u = static_cast<int>(u_value), v = static_cast<int>(v_value);
        matrix[u * kN + v] = substitution;
        matrix[v * kN + u] = kPrime - substitution;
        previous_u = u_value;
        previous_v = v_value;
    }

    std::array<std::int64_t, kN * (2 * kN)> augmented{};
    for (int row = 0; row < n; ++row) {
        for (int column = 0; column < n; ++column)
            augmented[row * (2 * kN) + column] = matrix[row * kN + column];
        augmented[row * (2 * kN) + n + row] = 1;
    }
    bool singular = false;
    for (int column = 0; column < n; ++column) {
        int pivot_row = column;
        while (pivot_row < n && augmented[pivot_row * (2 * kN) + column] == 0) ++pivot_row;
        if (pivot_row == n) { singular = true; break; }
        if (pivot_row != column) {
            for (int j = 0; j < 2 * n; ++j)
                std::swap(augmented[column * (2 * kN) + j], augmented[pivot_row * (2 * kN) + j]);
        }
        const auto inverse_pivot = power(augmented[column * (2 * kN) + column],
                                         static_cast<std::uint64_t>(kPrime - 2));
        for (int j = 0; j < 2 * n; ++j)
            augmented[column * (2 * kN) + j] =
                augmented[column * (2 * kN) + j] * inverse_pivot % kPrime;
        for (int row = 0; row < n; ++row) {
            if (row == column) continue;
            const auto factor = augmented[row * (2 * kN) + column];
            if (factor == 0) continue;
            for (int j = 0; j < 2 * n; ++j)
                augmented[row * (2 * kN) + j] = norm(
                    augmented[row * (2 * kN) + j] -
                    factor * augmented[column * (2 * kN) + j]);
        }
    }

    std::array<std::int64_t, 2 + kN> result{};
    std::size_t result_size = 2;
    if (!singular) {
        std::array<std::int64_t, kN * kN> inverse{};
        for (int row = 0; row < n; ++row)
            for (int column = 0; column < n; ++column)
                inverse[row * kN + column] = augmented[row * (2 * kN) + n + column];
        std::array<bool, kN> active_rows{}, active_columns{};
        for (int i = 0; i < n; ++i) active_rows[i] = active_columns[i] = true;
        bool failed = false;
        for (int vertex = 0; vertex < n; ++vertex) {
            if (!active_columns[vertex]) continue;
            int partner = -1;
            for (int candidate = 0; candidate < n; ++candidate) {
                if (active_rows[candidate] && candidate != vertex &&
                    matrix[vertex * kN + candidate] != 0 &&
                    inverse[candidate * kN + vertex] != 0) {
                    partner = candidate;
                    break;
                }
            }
            if (partner < 0 || result_size + 2 > result.size()) { failed = true; break; }
            result[result_size++] = vertex;
            result[result_size++] = partner;
            if (!eliminate(inverse, active_rows, active_columns, n, partner, vertex) ||
                !eliminate(inverse, active_rows, active_columns, n, vertex, partner)) {
                failed = true;
                break;
            }
        }
        if (failed) result_size = 2;
        else { result[0] = 1; result[1] = n / 2; }
    }
    const auto output_bytes = result_size * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::array<std::uint8_t, kMaxOutput> staged{};
    for (std::size_t word = 0; word < result_size; ++word) store_word(staged, word, result[word]);
    for (std::size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(output_bytes);
}
