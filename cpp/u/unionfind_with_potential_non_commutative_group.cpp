#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 32;
constexpr std::size_t max_q = 64;
constexpr std::int64_t modulus = 998'244'353;
using Matrix = std::array<std::int64_t, 4>;

std::int64_t normalize(std::int64_t value) noexcept {
    value %= modulus;
    return value < 0 ? value + modulus : value;
}

Matrix multiply(const Matrix &left, const Matrix &right) noexcept {
    Matrix result{};
    for (std::size_t row = 0; row < 2; ++row)
        for (std::size_t column = 0; column < 2; ++column)
            for (std::size_t inner = 0; inner < 2; ++inner)
                result[2 * row + column] = normalize(result[2 * row + column] +
                    left[2 * row + inner] * right[2 * inner + column]);
    return result;
}

Matrix inverse(const Matrix &matrix) noexcept {
    return {matrix[3], normalize(-matrix[1]), normalize(-matrix[2]), matrix[0]};
}

std::size_t find_root(std::array<std::size_t, max_n> &parent,
    std::array<Matrix, max_n> &difference, std::size_t item) noexcept {
    if (parent[item] != item) {
        const auto old_parent = parent[item];
        const auto root = find_root(parent, difference, old_parent);
        difference[item] = multiply(difference[old_parent], difference[item]);
        parent[item] = root;
    }
    return parent[item];
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t unionfind_with_potential_non_commutative_group(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 9 || length > 2 + 7 * max_q) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        q_value < 1 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (length != 2 + 7 * q) return -1;
    for (std::size_t operation = 0; operation < q; ++operation) {
        const auto position = 2 + 7 * operation;
        const auto kind = input[position], u = input[position + 1], v = input[position + 2];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value) return -1;
        if (kind == 0) {
            const Matrix matrix{input[position + 3], input[position + 4],
                                input[position + 5], input[position + 6]};
            for (const auto entry : matrix) if (entry < 0 || entry >= modulus) return -1;
            if (normalize(matrix[0] * matrix[3] - matrix[1] * matrix[2]) != 1) return -1;
        } else if (kind == 1) {
            for (std::size_t cell = 0; cell < 4; ++cell)
                if (input[position + 3 + cell] != 0) return -1;
        } else return -1;
    }
    const auto required = 32 * q;
    if (output == nullptr || capacity < required) return -2;

    std::array<std::size_t, max_n> parent{};
    std::array<std::size_t, max_n> set_size{};
    std::array<Matrix, max_n> difference{};
    for (std::size_t item = 0; item < n; ++item) {
        parent[item] = item;
        set_size[item] = 1;
        difference[item] = {1, 0, 0, 1};
    }
    for (std::size_t operation = 0; operation < q; ++operation) {
        const auto position = 2 + 7 * operation;
        const auto kind = input[position];
        const auto u = static_cast<std::size_t>(input[position + 1]);
        const auto v = static_cast<std::size_t>(input[position + 2]);
        std::array<std::int64_t, 4> row{};
        const auto root_u = find_root(parent, difference, u);
        const auto root_v = find_root(parent, difference, v);
        if (kind == 1) {
            if (root_u == root_v) row = multiply(inverse(difference[v]), difference[u]);
            else row.fill(-1);
        } else {
            const Matrix relation{input[position + 3], input[position + 4],
                                  input[position + 5], input[position + 6]};
            if (root_u == root_v) {
                row[0] = multiply(inverse(difference[v]), difference[u]) == relation;
            } else if (set_size[root_u] < set_size[root_v]) {
                difference[root_u] = multiply(multiply(difference[v], relation), inverse(difference[u]));
                parent[root_u] = root_v;
                set_size[root_v] += set_size[root_u];
                row[0] = 1;
            } else {
                difference[root_v] = multiply(multiply(difference[u], inverse(relation)), inverse(difference[v]));
                parent[root_v] = root_u;
                set_size[root_u] += set_size[root_v];
                row[0] = 1;
            }
        }
        for (std::size_t cell = 0; cell < 4; ++cell) store_i64_le(output, 32 * operation + 8 * cell, row[cell]);
    }
    return static_cast<std::int64_t>(required);
}
