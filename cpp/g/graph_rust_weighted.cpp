#include <cstddef>
#include <cstdint>

constexpr int MAX_VERTICES = 64;
constexpr int MAX_EDGES = 256;

static void put_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

extern "C" std::int64_t graph_rust_weighted(const std::int64_t *input, std::size_t length,
                                             std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2) return -1;
    auto nv = input[0], mv = input[1];
    if (nv < 0 || nv > MAX_VERTICES || mv < 0 || mv > MAX_EDGES
            || length != 2 + 3 * static_cast<std::size_t>(mv)) return -1;
    int n = static_cast<int>(nv), m = static_cast<int>(mv);
    for (int edge = 0; edge < m; ++edge) {
        auto u = input[2 + 3 * edge], v = input[3 + 3 * edge], weight = input[4 + 3 * edge];
        if (u < 0 || u >= nv || v < 0 || v >= nv || weight < -2147483648LL || weight > 2147483647LL) return -1;
    }
    std::size_t required = (1 + static_cast<std::size_t>(n) + 4 * static_cast<std::size_t>(m)) * 8;
    if (output == nullptr || capacity < required) return -2;
    std::size_t cursor = 0;
    put_i64(output, cursor++ * 8, nv);
    for (int vertex = 0; vertex < n; ++vertex) {
        std::size_t degree = 0;
        for (int edge = 0; edge < m; ++edge) {
            if (input[2 + 3 * edge] == vertex) ++degree;
            if (input[3 + 3 * edge] == vertex) ++degree;
        }
        put_i64(output, cursor++ * 8, static_cast<std::int64_t>(degree));
        for (int edge = 0; edge < m; ++edge) {
            auto u = input[2 + 3 * edge], v = input[3 + 3 * edge], weight = input[4 + 3 * edge];
            if (u == vertex) {
                put_i64(output, cursor++ * 8, v);
                put_i64(output, cursor++ * 8, weight);
            }
            if (v == vertex) {
                put_i64(output, cursor++ * 8, u);
                put_i64(output, cursor++ * 8, weight);
            }
        }
    }
    return static_cast<std::int64_t>(required);
}
