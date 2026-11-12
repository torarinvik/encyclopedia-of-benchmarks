#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, MAX_M = 64, MAX_INPUT = 131, MAX_OUTPUT = 1592 };

static void put_i64(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)bits;
        bits >>= 8;
    }
}

int64_t tree_decomposition_width_2(const int64_t *values, size_t length,
                                   uint8_t *output, size_t capacity)
{
    if (!values || length < 2 || length > MAX_INPUT ||
        values[0] < 1 || values[0] > MAX_N || values[1] < 0 || values[1] > MAX_M) return -1;
    const int n = (int)values[0], m = (int)values[1];
    if (m > n * (n - 1) / 2 || length != (size_t)(2 + 2 * m)) return -1;

    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    for (int edge = 0; edge < m; ++edge) {
        const int64_t left0 = values[2 + 2 * edge], right0 = values[3 + 2 * edge];
        if (left0 < 0 || right0 < 0 || left0 >= right0 || right0 >= n) return -1;
        const int left = (int)left0, right = (int)right0;
        if (adjacent[left][right]) return -1;
        adjacent[left][right] = adjacent[right][left] = 1;
    }

    uint8_t active[MAX_N] = {0};
    int64_t order[MAX_N] = {0}, bag_values[MAX_N][3] = {{0}};
    int64_t later_neighbors[MAX_N][2] = {{0}}, parents[MAX_N] = {0};
    int bag_sizes[MAX_N] = {0}, later_counts[MAX_N] = {0}, position[MAX_N] = {0};
    for (int vertex = 0; vertex < n; ++vertex) active[vertex] = 1;

    for (int step = 0; step < n; ++step) {
        int chosen = -1, neighbors[2] = {0}, neighbor_count = 0;
        for (int vertex = 0; vertex < n; ++vertex) {
            if (!active[vertex]) continue;
            int degree = 0;
            for (int other = 0; other < n; ++other)
                degree += active[other] && adjacent[vertex][other];
            if (degree <= 2) {
                chosen = vertex;
                for (int other = 0; other < n; ++other)
                    if (active[other] && adjacent[vertex][other]) neighbors[neighbor_count++] = other;
                break;
            }
        }
        if (chosen < 0) return -1;

        order[step] = chosen;
        later_counts[step] = neighbor_count;
        bag_sizes[step] = neighbor_count + 1;
        bag_values[step][0] = chosen;
        for (int i = 0; i < neighbor_count; ++i) {
            later_neighbors[step][i] = neighbors[i];
            bag_values[step][i + 1] = neighbors[i];
        }
        for (int i = 0; i < bag_sizes[step]; ++i)
            for (int j = i + 1; j < bag_sizes[step]; ++j)
                if (bag_values[step][j] < bag_values[step][i]) {
                    const int64_t temporary = bag_values[step][i];
                    bag_values[step][i] = bag_values[step][j];
                    bag_values[step][j] = temporary;
                }
        if (neighbor_count == 2) {
            const int left = neighbors[0], right = neighbors[1];
            adjacent[left][right] = adjacent[right][left] = 1;
        }
        active[chosen] = 0;
    }

    for (int step = 0; step < n; ++step) position[order[step]] = step;
    for (int step = 0; step < n; ++step) {
        parents[step] = n;
        if (later_counts[step] > 0) {
            parents[step] = later_neighbors[step][0];
            if (later_counts[step] == 2 &&
                position[later_neighbors[step][1]] < position[parents[step]])
                parents[step] = later_neighbors[step][1];
            parents[step] = position[parents[step]];
        }
    }

    const size_t bytes = 8 * (size_t)(6 * n + 7);
    if (bytes > MAX_OUTPUT || !output || capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT] = {0};
    put_i64(staged, 0, n + 1);
    put_i64(staged, 8, 2);
    put_i64(staged, 16, n);
    size_t cursor = 24;
    for (int bag = 0; bag <= n; ++bag) {
        const int count = bag == n ? 0 : bag_sizes[bag];
        put_i64(staged, cursor, count);
        cursor += 8;
        for (int slot = 0; slot < 3; ++slot) {
            put_i64(staged, cursor, slot < count ? bag_values[bag][slot] : -1);
            cursor += 8;
        }
    }
    for (int child = 0; child < n; ++child) {
        put_i64(staged, cursor, child);
        put_i64(staged, cursor + 8, parents[child]);
        cursor += 16;
    }
    for (size_t byte = 0; byte < bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)bytes;
}
