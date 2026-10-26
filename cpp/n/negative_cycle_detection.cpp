// Clean-room negative-cycle detection and witness extraction.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 20, max_m = 64, max_input = 2 + 3 * max_m;
void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t negative_cycle_detection(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const std::int64_t n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > static_cast<std::int64_t>(max_n) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(max_m) || length != 2 + 3 * static_cast<std::size_t>(m64)) return -1;
    const std::size_t n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::int64_t from[max_m], to[max_m], weight[max_m];
    for (std::size_t edge = 0; edge < m; ++edge) {
        const std::int64_t u = input[2 + 3 * edge], v = input[3 + 3 * edge], w = input[4 + 3 * edge];
        if (u < 0 || u >= n64 || v < 0 || v >= n64 || w < -1000 || w > 1000) return -1;
        from[edge] = u; to[edge] = v; weight[edge] = w;
    }
    std::int64_t distance[max_n]{};
    std::int64_t predecessor[max_n];
    for (std::size_t v = 0; v < n; ++v) predecessor[v] = -1;
    std::int64_t changed_vertex = -1;
    for (std::size_t pass = 0; pass < n; ++pass) {
        changed_vertex = -1;
        for (std::size_t edge = 0; edge < m; ++edge) {
            const std::size_t u = static_cast<std::size_t>(from[edge]), v = static_cast<std::size_t>(to[edge]);
            const std::int64_t candidate = distance[u] + weight[edge];
            if (candidate < distance[v]) { distance[v] = candidate; predecessor[v] = static_cast<std::int64_t>(u); changed_vertex = static_cast<std::int64_t>(v); }
        }
        if (changed_vertex < 0) break;
    }
    std::int64_t record[max_n + 2]{};
    std::size_t record_length = 1;
    if (changed_vertex >= 0) {
        std::size_t vertex = static_cast<std::size_t>(changed_vertex);
        for (std::size_t step = 0; step < n; ++step) {
            if (predecessor[vertex] < 0) return -1;
            vertex = static_cast<std::size_t>(predecessor[vertex]);
        }
        const std::size_t start = vertex;
        std::size_t cycle[max_n], cycle_length = 0;
        do {
            if (cycle_length >= n || predecessor[vertex] < 0) return -1;
            cycle[cycle_length++] = vertex;
            vertex = static_cast<std::size_t>(predecessor[vertex]);
        } while (vertex != start);
        for (std::size_t left = 0, right = cycle_length - 1; left < right; ++left, --right) {
            const std::size_t temporary = cycle[left]; cycle[left] = cycle[right]; cycle[right] = temporary;
        }
        std::size_t minimum = 0;
        for (std::size_t i = 1; i < cycle_length; ++i) if (cycle[i] < cycle[minimum]) minimum = i;
        record[0] = 1; record[1] = static_cast<std::int64_t>(cycle_length);
        for (std::size_t i = 0; i < cycle_length; ++i) record[2 + i] = static_cast<std::int64_t>(cycle[(minimum + i) % cycle_length]);
        record_length = cycle_length + 2;
    } else record[0] = 0;
    const std::size_t output_length = 8 * record_length;
    if (output == nullptr || capacity < output_length) return -2;
    for (std::size_t i = 0; i < record_length; ++i) store_i64_le(output, 8 * i, record[i]);
    return static_cast<std::int64_t>(output_length);
}
