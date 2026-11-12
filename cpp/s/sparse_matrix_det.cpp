#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::int64_t kMod = 998244353;
constexpr int kMaxN = 8;
constexpr int kMaxK = 64;
constexpr std::size_t kMaxParseableInput = 2 + 3 * kMaxK + 1;
constexpr int kAttempts = 4;

std::int64_t add_mod(std::int64_t a, std::int64_t b) {
    a += b;
    return a >= kMod ? a - kMod : a;
}
std::int64_t sub_mod(std::int64_t a, std::int64_t b) {
    a -= b;
    return a < 0 ? a + kMod : a;
}
std::int64_t mul_mod(std::int64_t a, std::int64_t b) { return a * b % kMod; }
std::int64_t pow_mod(std::int64_t value, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = mul_mod(result, value);
        value = mul_mod(value, value);
        exponent >>= 1;
    }
    return result;
}
std::int64_t next_residue(std::int64_t &state) {
    state = (state * 48271 + 1) % kMod;
    return state;
}

int berlekamp_massey(const std::array<std::int64_t, 2 * kMaxN> &sequence,
                     int length, std::array<std::int64_t, kMaxN + 1> &connection) {
    std::array<std::int64_t, kMaxN + 1> previous{};
    std::array<std::int64_t, kMaxN + 1> temporary{};
    connection.fill(0);
    connection[0] = previous[0] = 1;
    int degree = 0, shift = 1, previous_degree = 0;
    std::int64_t last_discrepancy = 1;
    for (int index = 0; index < length; ++index) {
        std::int64_t discrepancy = sequence[index];
        for (int i = 1; i <= degree; ++i)
            discrepancy = add_mod(discrepancy, mul_mod(connection[i], sequence[index - i]));
        if (discrepancy == 0) { ++shift; continue; }
        temporary = connection;
        const auto scale = mul_mod(discrepancy, pow_mod(last_discrepancy, kMod - 2));
        for (int i = 0; i <= previous_degree; ++i)
            if (i + shift <= kMaxN)
                connection[i + shift] = sub_mod(connection[i + shift], mul_mod(scale, previous[i]));
        if (2 * degree <= index) {
            const int old_degree = degree;
            degree = index + 1 - degree;
            previous = temporary;
            previous_degree = old_degree;
            last_discrepancy = discrepancy;
            shift = 1;
        } else {
            ++shift;
        }
    }
    return degree;
}

std::int64_t dense_determinant(const std::array<int, kMaxK> &row,
        const std::array<int, kMaxK> &column,
        const std::array<std::int64_t, kMaxK> &entry, int n, int k) {
    std::array<std::array<std::int64_t, kMaxN>, kMaxN> matrix{};
    for (int e = 0; e < k; ++e) matrix[row[e]][column[e]] = entry[e];
    std::int64_t determinant = 1;
    for (int c = 0; c < n; ++c) {
        int pivot = c;
        while (pivot < n && matrix[pivot][c] == 0) ++pivot;
        if (pivot == n) return 0;
        if (pivot != c) {
            std::swap(matrix[pivot], matrix[c]);
            determinant = kMod - determinant;
        }
        const auto pivot_value = matrix[c][c];
        determinant = mul_mod(determinant, pivot_value);
        const auto inverse = pow_mod(pivot_value, kMod - 2);
        for (int i = c + 1; i < n; ++i) {
            if (matrix[i][c] == 0) continue;
            const auto factor = mul_mod(matrix[i][c], inverse);
            for (int j = c + 1; j < n; ++j)
                matrix[i][j] = sub_mod(matrix[i][j], mul_mod(factor, matrix[c][j]));
            matrix[i][c] = 0;
        }
    }
    return determinant;
}

std::int64_t sparse_wiedemann(const std::array<int, kMaxK> &row,
        const std::array<int, kMaxK> &column,
        const std::array<std::int64_t, kMaxK> &entry, int n, int k,
        std::int64_t seed, bool &success) {
    std::array<std::int64_t, kMaxN> diagonal{}, left{}, vector{}, next{}, weighted{};
    std::array<std::int64_t, 2 * kMaxN> sequence{};
    std::int64_t diagonal_product = 1;
    for (int i = 0; i < n; ++i) {
        diagonal[i] = next_residue(seed);
        if (diagonal[i] == 0) diagonal[i] = 1;
        left[i] = next_residue(seed);
        vector[i] = next_residue(seed);
        diagonal_product = mul_mod(diagonal_product, diagonal[i]);
    }
    for (int step = 0; step < 2 * n; ++step) {
        std::int64_t dot = 0;
        for (int i = 0; i < n; ++i) dot = add_mod(dot, mul_mod(left[i], vector[i]));
        sequence[step] = dot;
        for (int i = 0; i < n; ++i) weighted[i] = mul_mod(diagonal[i], vector[i]);
        next.fill(0);
        for (int e = 0; e < k; ++e)
            next[row[e]] = add_mod(next[row[e]], mul_mod(entry[e], weighted[column[e]]));
        vector = next;
    }
    std::array<std::int64_t, kMaxN + 1> connection{};
    if (berlekamp_massey(sequence, 2 * n, connection) != n) {
        success = false;
        return 0;
    }
    auto constant = connection[n];
    if ((n & 1) && constant != 0) constant = kMod - constant;
    success = true;
    return mul_mod(constant, pow_mod(diagonal_product, kMod - 2));
}

void store_i64_le(std::uint8_t *output, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t sparse_matrix_det(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxParseableInput) return -1;
    const auto n_value = input[0], k_value = input[1];
    if (n_value < 1 || n_value > kMaxN || k_value < 1 || k_value > kMaxK) return -1;
    const int n = static_cast<int>(n_value), k = static_cast<int>(k_value);
    if (length != static_cast<std::size_t>(2 + 3 * k)) return -1;
    std::array<std::array<bool, kMaxN>, kMaxN> seen{};
    std::array<int, kMaxK> row{}, column{};
    std::array<std::int64_t, kMaxK> entry{};
    for (int e = 0; e < k; ++e) {
        const auto r = input[2 + 3 * e], c = input[3 + 3 * e], value = input[4 + 3 * e];
        if (r < 0 || r >= n || c < 0 || c >= n || value < 1 || value >= kMod || seen[r][c]) return -1;
        row[e] = static_cast<int>(r); column[e] = static_cast<int>(c); entry[e] = value; seen[r][c] = true;
    }
    std::int64_t determinant = 0;
    bool found = false;
    for (int attempt = 0; attempt < kAttempts; ++attempt) {
        auto seed = INT64_C(104729) + static_cast<std::int64_t>(attempt) * INT64_C(1000003);
        if (seed >= kMod) seed %= kMod;
        determinant = sparse_wiedemann(row, column, entry, n, k, seed, found);
        if (found) break;
    }
    if (!found) determinant = dense_determinant(row, column, entry, n, k);
    if (output == nullptr || capacity < 8) return -2;
    store_i64_le(output, determinant);
    return 8;
}
