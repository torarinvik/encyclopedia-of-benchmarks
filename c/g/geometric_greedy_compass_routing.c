#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_INPUT = 84, OUTPUT_VALUES = 10, MAX_OUTPUT = 80 };

static void put64(uint8_t *output, size_t position, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[position + byte] = (uint8_t)(bits >> (8u * byte));
}

static bool angle_better(int64_t da, int64_t la, int64_t db, int64_t lb)
{
    if ((da >= 0) != (db >= 0)) return da >= 0;
    int64_t left = da * da * lb;
    int64_t right = db * db * la;
    return da >= 0 ? left > right : left < right;
}

static bool angle_equal(int64_t da, int64_t la, int64_t db, int64_t lb)
{
    return (da >= 0) == (db >= 0) && da * da * lb == db * db * la;
}

int64_t geometric_greedy_compass_routing(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 12u || length > MAX_INPUT) return -1;
    int64_t n64 = input[0], mode = input[1], source64 = input[2], target64 = input[3];
    if (n64 < 2 || n64 > MAX_N || mode < 0 || mode > 1 || source64 < 0 || target64 < 0 ||
        source64 >= n64 || target64 >= n64) return -1;
    size_t n = (size_t)n64, source = (size_t)source64, target = (size_t)target64;
    if (length != 4u + 2u * n + n * n) return -1;
    int64_t x[MAX_N], y[MAX_N];
    size_t adjacency = 4u + 2u * n;
    for (size_t i = 0; i < n; ++i) {
        x[i] = input[4u + i]; y[i] = input[4u + n + i];
        if (x[i] < -8 || x[i] > 8 || y[i] < -8 || y[i] > 8) return -1;
        for (size_t j = 0; j < i; ++j) if (x[i] == x[j] && y[i] == y[j]) return -1;
    }
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < n; ++j) {
            int64_t a = input[adjacency + i * n + j], b = input[adjacency + j * n + i];
            if ((a != 0 && a != 1) || a != b || (i == j && a != 0)) return -1;
        }
    if (output == NULL || capacity < MAX_OUTPUT) return -2;

    size_t path[MAX_N], path_count = 1;
    bool visited[MAX_N] = {false};
    path[0] = source; visited[source] = true;
    size_t current = source;
    while (current != target && path_count < n) {
        size_t best = n;
        int64_t best_dot = 0, best_len = 1, best_distance = 0;
        int64_t tx = x[target] - x[current], ty = y[target] - y[current];
        for (size_t v = 0; v < n; ++v) {
            if (input[adjacency + current * n + v] != 1) continue;
            bool better = best == n;
            int64_t dx = x[v] - x[current], dy = y[v] - y[current];
            if (mode == 0) {
                int64_t rx = x[v] - x[target], ry = y[v] - y[target];
                int64_t distance = rx * rx + ry * ry;
                if (!better) better = distance < best_distance || (distance == best_distance && v < best);
                if (better) best_distance = distance;
            } else {
                int64_t dot = dx * tx + dy * ty, len = dx * dx + dy * dy;
                if (!better) better = angle_better(dot, len, best_dot, best_len) ||
                    (angle_equal(dot, len, best_dot, best_len) && v < best);
                if (better) { best_dot = dot; best_len = len; }
            }
            if (better) best = v;
        }
        if (best == n || visited[best]) break;
        path[path_count++] = best; visited[best] = true; current = best;
    }
    int64_t record[OUTPUT_VALUES];
    record[0] = current == target ? 1 : 0;
    record[1] = (int64_t)(path_count - 1);
    for (size_t i = 0; i < MAX_N; ++i) record[2 + i] = -1;
    for (size_t i = 0; i < path_count; ++i) record[2 + i] = (int64_t)path[i];
    uint8_t staged[MAX_OUTPUT];
    for (size_t i = 0; i < OUTPUT_VALUES; ++i) put64(staged, 8u * i, record[i]);
    for (size_t i = 0; i < MAX_OUTPUT; ++i) output[i] = staged[i];
    return MAX_OUTPUT;
}
