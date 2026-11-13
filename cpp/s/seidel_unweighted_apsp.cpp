#include <array>
#include <cstddef>
#include <cstdint>

namespace {
using Matrix = std::array<std::array<int, 8>, 8>;

Matrix distances(const Matrix& adjacency, std::size_t n) {
    Matrix squared{}, expanded{}, result{};
    std::array<int, 8> degree{};
    bool complete = true;
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = 0; j < n; ++j) {
            degree[i] += adjacency[i][j];
            if (i != j && !adjacency[i][j]) complete = false;
            for (std::size_t k = 0; k < n; ++k)
                squared[i][j] += adjacency[i][k] * adjacency[k][j];
        }
    }
    if (complete) {
        for (std::size_t i = 0; i < n; ++i)
            for (std::size_t j = 0; j < n; ++j) result[i][j] = i != j;
        return result;
    }
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < n; ++j)
            expanded[i][j] = i != j && (adjacency[i][j] || squared[i][j] > 0);
    const auto coarse = distances(expanded, n);
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = 0; j < n; ++j) {
            if (i == j) continue;
            int neighbor_sum = 0;
            for (std::size_t k = 0; k < n; ++k) neighbor_sum += coarse[i][k] * adjacency[k][j];
            result[i][j] = 2 * coarse[i][j] - (neighbor_sum < coarse[i][j] * degree[j]);
        }
    }
    return result;
}
}

extern "C" std::int64_t seidel_unweighted_apsp(const std::int64_t* input, std::size_t length,
                                                std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 66) return -1;
    if (input[0] < 1 || input[0] > 8) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + n * n) return -1;
    Matrix adjacency{};
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = 0; j < n; ++j) {
            const auto value = input[1 + i * n + j];
            if (value < 0 || value > 1 || (i == j && value != 0)) return -1;
            adjacency[i][j] = static_cast<int>(value);
        }
    }
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < i; ++j)
            if (adjacency[i][j] != adjacency[j][i]) return -1;
    std::array<bool, 8> seen{};
    std::array<std::size_t, 8> queue{};
    std::size_t head = 0, tail = 1;
    seen[0] = true;
    while (head < tail) {
        const auto vertex = queue[head++];
        for (std::size_t other = 0; other < n; ++other) {
            if (adjacency[vertex][other] && !seen[other]) {
                seen[other] = true;
                queue[tail++] = other;
            }
        }
    }
    if (tail != n) return -1;
    const auto bytes = 8 * n * n;
    if (output == nullptr || capacity < bytes) return -2;
    const auto result = distances(adjacency, n);
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = 0; j < n; ++j) {
            auto bits = static_cast<std::uint64_t>(result[i][j]);
            for (std::size_t byte = 0; byte < 8; ++byte) {
                output[8 * (i * n + j) + byte] = static_cast<std::uint8_t>(bits & 255);
                bits >>= 8;
            }
        }
    }
    return static_cast<std::int64_t>(bytes);
}
