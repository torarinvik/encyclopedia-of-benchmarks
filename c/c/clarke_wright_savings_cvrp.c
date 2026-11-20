#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <limits.h>

typedef struct { int64_t saving; int i, j; } Saving;

static bool saving_before(Saving a, Saving b) {
    return a.saving > b.saving ||
        (a.saving == b.saving && (a.i < b.i || (a.i == b.i && a.j < b.j)));
}

static void reverse_route(int route[7], int length) {
    for (int left = 0, right = length - 1; left < right; ++left, --right) {
        int t = route[left]; route[left] = route[right]; route[right] = t;
    }
}

static int compare_routes(const int a[7], int an, const int b[7], int bn) {
    int shared = an < bn ? an : bn;
    for (int i = 0; i < shared; ++i) {
        if (a[i] < b[i]) return -1;
        if (a[i] > b[i]) return 1;
    }
    return an < bn ? -1 : an > bn ? 1 : 0;
}

static void put_i64(uint8_t *out, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (int i = 0; i < 8; ++i) out[i] = (uint8_t)(bits >> (8 * i));
}

int64_t clarke_wright_savings_cvrp(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 74) return -1;
    int64_t n64 = input[0], capacity64 = input[1];
    if (n64 < 0 || n64 > 7 || capacity64 < 1 || capacity64 > 100) return -1;
    int n = (int)n64, vehicle_capacity = (int)capacity64, width = n + 1;
    if (length != (size_t)(2 + n + width * width)) return -1;

    int64_t demand[8] = {0}, distance[8][8] = {{0}};
    for (int customer = 1; customer <= n; ++customer) {
        int64_t value = input[1 + customer];
        if (value < 1 || value > vehicle_capacity) return -1;
        demand[customer] = value;
    }
    size_t offset = (size_t)(2 + n);
    for (int i = 0; i < width; ++i) for (int j = 0; j < width; ++j) {
        int64_t value = input[offset + (size_t)i * width + j];
        if (value < 0 || value > 1000 || (i == j && value != 0)) return -1;
        distance[i][j] = value;
    }
    for (int i = 0; i < width; ++i) for (int j = i + 1; j < width; ++j)
        if (distance[i][j] != distance[j][i]) return -1;

    int route[7][7] = {{0}}, route_length[7] = {0}, active[7] = {0};
    int64_t load[7] = {0};
    for (int slot = 0; slot < n; ++slot) {
        route[slot][0] = slot + 1; route_length[slot] = 1;
        load[slot] = demand[slot + 1]; active[slot] = 1;
    }
    Saving pairs[21]; int pair_count = 0;
    for (int i = 1; i <= n; ++i) for (int j = i + 1; j <= n; ++j)
        pairs[pair_count++] = (Saving){distance[0][i] + distance[0][j] - distance[i][j], i, j};
    for (int i = 0; i < pair_count; ++i) for (int j = i + 1; j < pair_count; ++j)
        if (saving_before(pairs[j], pairs[i])) { Saving t = pairs[i]; pairs[i] = pairs[j]; pairs[j] = t; }

    for (int p = 0; p < pair_count && pairs[p].saving > 0; ++p) {
        int ri = -1, rj = -1, pi = -1, pj = -1;
        for (int r = 0; r < n; ++r) if (active[r]) for (int at = 0; at < route_length[r]; ++at) {
            if (route[r][at] == pairs[p].i) { ri = r; pi = at; }
            if (route[r][at] == pairs[p].j) { rj = r; pj = at; }
        }
        if (ri == rj || ri < 0 || rj < 0) continue;
        if ((pi != 0 && pi != route_length[ri] - 1)
                || (pj != 0 && pj != route_length[rj] - 1)
                || load[ri] + load[rj] > vehicle_capacity) continue;
        if (pi == 0) reverse_route(route[ri], route_length[ri]);
        if (pj == route_length[rj] - 1) reverse_route(route[rj], route_length[rj]);
        for (int at = 0; at < route_length[rj]; ++at)
            route[ri][route_length[ri] + at] = route[rj][at];
        route_length[ri] += route_length[rj]; load[ri] += load[rj];
        active[rj] = 0; route_length[rj] = 0; load[rj] = 0;
    }

    int final_routes[7][7] = {{0}}, final_length[7] = {0}, route_count = 0;
    for (int r = 0; r < n; ++r) if (active[r]) {
        bool reverse_first = false;
        for (int at = 0; at < route_length[r]; ++at) {
            int a = route[r][at], b = route[r][route_length[r] - 1 - at];
            if (a != b) { reverse_first = a > b; break; }
        }
        if (reverse_first) reverse_route(route[r], route_length[r]);
        for (int at = 0; at < route_length[r]; ++at) final_routes[route_count][at] = route[r][at];
        final_length[route_count++] = route_length[r];
    }
    for (int i = 0; i < route_count; ++i) for (int j = i + 1; j < route_count; ++j)
        if (compare_routes(final_routes[i], final_length[i], final_routes[j], final_length[j]) > 0) {
            int tmp[7]; for (int k = 0; k < 7; ++k) tmp[k] = final_routes[i][k];
            for (int k = 0; k < 7; ++k) final_routes[i][k] = final_routes[j][k];
            for (int k = 0; k < 7; ++k) final_routes[j][k] = tmp[k];
            int t = final_length[i]; final_length[i] = final_length[j]; final_length[j] = t;
        }

    int64_t words[15]; int word_count = 0;
    words[word_count++] = route_count;
    for (int r = 0; r < route_count; ++r) {
        words[word_count++] = final_length[r];
        for (int at = 0; at < final_length[r]; ++at) words[word_count++] = final_routes[r][at];
    }
    size_t bytes = (size_t)word_count * 8;
    if (!output || capacity < bytes) return -2;
    for (int i = 0; i < word_count; ++i) put_i64(output + (size_t)i * 8, words[i]);
    return (int64_t)bytes;
}
