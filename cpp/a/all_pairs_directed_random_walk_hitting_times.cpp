#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t kMaxN = 8;
constexpr std::size_t kMaxInputLength = 115;
constexpr std::int64_t kMod = 1'000'000'007;
using Matrix = std::array<std::array<std::int64_t, 2 * kMaxN + 1>, kMaxN>;

std::int64_t norm(std::int64_t value) {
    value %= kMod;
    return value < 0 ? value + kMod : value;
}

std::int64_t power(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    base = norm(base);
    while (exponent) {
        if (exponent & 1) result = result * base % kMod;
        base = base * base % kMod;
        exponent >>= 1;
    }
    return result;
}

bool reaches_all(const std::array<std::array<bool, kMaxN>, kMaxN>& graph,
                 std::size_t n, bool reverse) {
    std::array<bool, kMaxN> seen{};
    std::array<std::size_t, kMaxN> queue{};
    std::size_t head = 0, tail = 0;
    seen[0] = true;
    queue[tail++] = 0;
    while (head < tail) {
        const auto from = queue[head++];
        for (std::size_t to = 0; to < n; ++to) {
            const bool edge = reverse ? graph[to][from] : graph[from][to];
            if (edge && !seen[to]) {
                seen[to] = true;
                queue[tail++] = to;
            }
        }
    }
    return tail == n;
}

bool eliminate(Matrix& matrix, std::size_t size, std::size_t rhs_count) {
    const auto width = size + rhs_count;
    for (std::size_t column = 0; column < size; ++column) {
        auto pivot = column;
        while (pivot < size && norm(matrix[pivot][column]) == 0) ++pivot;
        if (pivot == size) return false;
        if (pivot != column) std::swap(matrix[pivot], matrix[column]);
        const auto inverse = power(matrix[column][column], kMod - 2);
        for (std::size_t j = 0; j < width; ++j)
            matrix[column][j] = matrix[column][j] * inverse % kMod;
        for (std::size_t row = 0; row < size; ++row) {
            if (row == column) continue;
            const auto factor = norm(matrix[row][column]);
            if (!factor) continue;
            for (std::size_t j = 0; j < width; ++j)
                matrix[row][j] = norm(matrix[row][j] - factor * matrix[column][j] % kMod);
        }
    }
    return true;
}

void store_i64_le(std::uint8_t* output, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t all_pairs_directed_random_walk_hitting_times(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const auto n_value = input[0], m_value = input[1];
    if (n_value < 3 || n_value > static_cast<std::int64_t>(kMaxN)) return -1;
    if (m_value < 0 || m_value > n_value * (n_value - 1)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    if (length != 2 + 2 * m) return -1;

    std::array<std::array<bool, kMaxN>, kMaxN> graph{};
    std::array<std::size_t, kMaxN> degree{};
    for (std::size_t e = 0; e < m; ++e) {
        const auto u_value = input[2 + 2 * e], v_value = input[3 + 2 * e];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
                || u_value == v_value) return -1;
        const auto u = static_cast<std::size_t>(u_value);
        const auto v = static_cast<std::size_t>(v_value);
        if (graph[u][v]) return -1;
        graph[u][v] = true;
        ++degree[u];
    }
    for (std::size_t i = 0; i < n; ++i) if (!degree[i]) return -1;
    if (!reaches_all(graph, n, false) || !reaches_all(graph, n, true)) return -1;
    const auto output_bytes = 8 * n * n;
    if (output == nullptr || capacity < output_bytes) return -2;

    Matrix stationary{};
    for (std::size_t destination = 0; destination + 1 < n; ++destination)
        for (std::size_t source = 0; source < n; ++source) {
            const auto transition = graph[source][destination]
                ? power(static_cast<std::int64_t>(degree[source]), kMod - 2) : 0;
            stationary[destination][source] = norm(transition - (source == destination));
        }
    for (std::size_t source = 0; source < n; ++source) stationary[n - 1][source] = 1;
    stationary[n - 1][n] = 1;
    if (!eliminate(stationary, n, 1)) return -1;
    std::array<std::int64_t, kMaxN> reciprocal{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto pi = norm(stationary[i][n]);
        if (!pi) return -1;
        reciprocal[i] = power(pi, kMod - 2);
    }

    Matrix reduced{};
    for (std::size_t row = 0; row + 1 < n; ++row) {
        for (std::size_t column = 0; column + 1 < n; ++column) {
            const auto transition = graph[row][column]
                ? power(static_cast<std::int64_t>(degree[row]), kMod - 2) : 0;
            reduced[row][column] = norm((row == column) - transition);
        }
        for (std::size_t target = 0; target < n; ++target)
            reduced[row][n - 1 + target] = norm(1 - (row == target ? reciprocal[target] : 0));
    }
    if (!eliminate(reduced, n - 1, n)) return -1;
    std::array<std::array<std::int64_t, kMaxN>, kMaxN> y{}, answer{};
    for (std::size_t row = 0; row + 1 < n; ++row)
        for (std::size_t target = 0; target < n; ++target)
            y[row][target] = norm(reduced[row][n - 1 + target]);
    for (std::size_t source = 0; source < n; ++source)
        for (std::size_t target = 0; target < n; ++target)
            answer[source][target] = norm(y[source][target] - y[target][target]);
    for (std::size_t source = 0; source < n; ++source)
        for (std::size_t target = 0; target < n; ++target)
            store_i64_le(output + 8 * (source * n + target), answer[source][target]);
    return static_cast<std::int64_t>(output_bytes);
}
