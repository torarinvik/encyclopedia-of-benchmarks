#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_N = 32, MAX_M = 64, MAX_INPUT = 131, MAX_OUTPUT = 1592;

void put_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (int byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t tree_decomposition_width_2(
    const std::int64_t *values, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (!values || length < 2 || length > MAX_INPUT || values[0] < 1 ||
        values[0] > MAX_N || values[1] < 0 || values[1] > MAX_M) return -1;
    const int n = static_cast<int>(values[0]), m = static_cast<int>(values[1]);
    if (m > n * (n - 1) / 2 || length != static_cast<std::size_t>(2 + 2 * m)) return -1;

    bool adjacent[MAX_N][MAX_N]{};
    for (int edge = 0; edge < m; ++edge) {
        const auto left0 = values[2 + 2 * edge], right0 = values[3 + 2 * edge];
        if (left0 < 0 || left0 >= right0 || right0 >= n) return -1;
        const int left = static_cast<int>(left0), right = static_cast<int>(right0);
        if (adjacent[left][right]) return -1;
        adjacent[left][right] = adjacent[right][left] = true;
    }

    bool active[MAX_N]{};
    std::int64_t bag_values[MAX_N][3]{}, later[MAX_N][2]{}, parent[MAX_N]{};
    int bag_size[MAX_N]{}, later_count[MAX_N]{}, order[MAX_N]{}, position[MAX_N]{};
    for (int vertex = 0; vertex < n; ++vertex) active[vertex] = true;

    for (int step = 0; step < n; ++step) {
        int chosen = -1, neighbors[2]{}, count = 0;
        for (int vertex = 0; vertex < n; ++vertex) {
            if (!active[vertex]) continue;
            int degree = 0;
            for (int other = 0; other < n; ++other)
                degree += active[other] && adjacent[vertex][other];
            if (degree <= 2) {
                chosen = vertex;
                for (int other = 0; other < n; ++other)
                    if (active[other] && adjacent[vertex][other]) neighbors[count++] = other;
                break;
            }
        }
        if (chosen < 0) return -1;
        order[step] = chosen;
        later_count[step] = count;
        bag_size[step] = count + 1;
        bag_values[step][0] = chosen;
        for (int i = 0; i < count; ++i) {
            later[step][i] = neighbors[i];
            bag_values[step][i + 1] = neighbors[i];
        }
        for (int i = 0; i < bag_size[step]; ++i)
            for (int j = i + 1; j < bag_size[step]; ++j)
                if (bag_values[step][j] < bag_values[step][i]) {
                    const auto temporary = bag_values[step][i];
                    bag_values[step][i] = bag_values[step][j];
                    bag_values[step][j] = temporary;
                }
        if (count == 2) adjacent[neighbors[0]][neighbors[1]] = adjacent[neighbors[1]][neighbors[0]] = true;
        active[chosen] = false;
    }

    for (int step = 0; step < n; ++step) position[order[step]] = step;
    for (int step = 0; step < n; ++step) {
        parent[step] = n;
        if (later_count[step] > 0) {
            int selected = static_cast<int>(later[step][0]);
            if (later_count[step] == 2 && position[later[step][1]] < position[selected])
                selected = static_cast<int>(later[step][1]);
            parent[step] = position[selected];
        }
    }

    const std::size_t bytes = 8 * static_cast<std::size_t>(6 * n + 7);
    if (bytes > MAX_OUTPUT || !output || capacity < bytes) return -2;
    std::uint8_t staged[MAX_OUTPUT]{};
    put_i64(staged, 0, n + 1);
    put_i64(staged, 8, 2);
    put_i64(staged, 16, n);
    std::size_t cursor = 24;
    for (int bag = 0; bag <= n; ++bag) {
        const int count = bag == n ? 0 : bag_size[bag];
        put_i64(staged, cursor, count);
        cursor += 8;
        for (int slot = 0; slot < 3; ++slot) {
            put_i64(staged, cursor, slot < count ? bag_values[bag][slot] : -1);
            cursor += 8;
        }
    }
    for (int child = 0; child < n; ++child) {
        put_i64(staged, cursor, child);
        put_i64(staged, cursor + 8, parent[child]);
        cursor += 16;
    }
    for (std::size_t byte = 0; byte < bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(bytes);
}
