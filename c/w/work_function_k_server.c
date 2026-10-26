/* Clean-room bounded work-function algorithm for finite k-server metrics. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_POINTS = 6, MAX_SERVERS = 3, MAX_REQUESTS = 8, MAX_CONFIGS = 20,
       MAX_INPUT = 50, MAX_OUTPUT = 208 };

typedef struct { int64_t point[MAX_SERVERS]; } config_t;

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { out[offset + byte] = (uint8_t)(bits & 255u); bits >>= 8; }
}

static void sort_config(int64_t *x, size_t k) {
    for (size_t i = 0; i < k; ++i) for (size_t j = i + 1; j < k; ++j)
        if (x[j] < x[i]) { int64_t tmp = x[i]; x[i] = x[j]; x[j] = tmp; }
}

static size_t find_config(const config_t *configs, size_t count, const int64_t *x, size_t k) {
    for (size_t i = 0; i < count; ++i) {
        size_t j = 0; while (j < k && configs[i].point[j] == x[j]) ++j;
        if (j == k) return i;
    }
    return count;
}

static int64_t config_distance(const int64_t *a, const int64_t *b, size_t k,
                               int64_t metric[MAX_POINTS][MAX_POINTS]) {
    if (k == 1) return metric[a[0]][b[0]];
    if (k == 2) {
        int64_t x = metric[a[0]][b[0]] + metric[a[1]][b[1]];
        int64_t y = metric[a[0]][b[1]] + metric[a[1]][b[0]];
        return x < y ? x : y;
    }
    const size_t perm[6][3] = {{0,1,2},{0,2,1},{1,0,2},{1,2,0},{2,0,1},{2,1,0}};
    int64_t best = INT64_MAX;
    for (size_t p = 0; p < 6; ++p) {
        int64_t cost = metric[a[0]][b[perm[p][0]]] + metric[a[1]][b[perm[p][1]]] + metric[a[2]][b[perm[p][2]]];
        if (cost < best) best = cost;
    }
    return best;
}

int64_t work_function_k_server(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    int64_t p64 = input[0], k64 = input[1], n64 = input[2];
    if (p64 < 2 || p64 > MAX_POINTS || k64 < 1 || k64 > MAX_SERVERS || k64 > p64 ||
        n64 < 0 || n64 > MAX_REQUESTS) return -1;
    size_t p = (size_t)p64, k = (size_t)k64, n = (size_t)n64;
    size_t matrix_start = 3, initial_start = matrix_start + p*p, requests_start = initial_start + k;
    if (length != requests_start + n) return -1;
    int64_t metric[MAX_POINTS][MAX_POINTS] = {{0}};
    for (size_t i = 0; i < p; ++i) for (size_t j = 0; j < p; ++j) {
        int64_t d = input[matrix_start + i*p + j];
        if (d < 0 || d > 1000 || (i == j && d != 0) || (i != j && d == 0)) return -1;
        metric[i][j] = d;
    }
    for (size_t i = 0; i < p; ++i) for (size_t j = 0; j < p; ++j) {
        if (metric[i][j] != metric[j][i]) return -1;
        for (size_t z = 0; z < p; ++z) if (metric[i][j] > metric[i][z] + metric[z][j]) return -1;
    }
    int64_t initial[MAX_SERVERS] = {0};
    for (size_t i = 0; i < k; ++i) {
        int64_t x = input[initial_start + i];
        if (x < 0 || x >= p64) return -1;
        initial[i] = x;
        for (size_t j = 0; j < i; ++j) if (initial[j] == x) return -1;
    }
    sort_config(initial, k);
    int64_t requests[MAX_REQUESTS] = {0};
    for (size_t t = 0; t < n; ++t) {
        int64_t r = input[requests_start + t];
        if (r < 0 || r >= p64) return -1;
        requests[t] = r;
    }
    const size_t output_bytes = 8 * (2 + n*k);
    if (output == NULL || capacity < output_bytes) return -2;

    config_t configs[MAX_CONFIGS] = {{{0}}};
    size_t config_count = 0;
    for (size_t a = 0; a < p; ++a) {
        if (k == 1) { configs[config_count++].point[0] = (int64_t)a; continue; }
        for (size_t b = a + 1; b < p; ++b) {
            if (k == 2) { configs[config_count].point[0] = (int64_t)a; configs[config_count++].point[1] = (int64_t)b; continue; }
            for (size_t c = b + 1; c < p; ++c) {
                configs[config_count].point[0] = (int64_t)a;
                configs[config_count].point[1] = (int64_t)b;
                configs[config_count++].point[2] = (int64_t)c;
            }
        }
    }
    int64_t work[MAX_CONFIGS], next_work[MAX_CONFIGS];
    for (size_t x = 0; x < config_count; ++x)
        work[x] = config_distance(initial, configs[x].point, k, metric);
    int64_t staged[2 + MAX_REQUESTS*MAX_SERVERS];
    staged[0] = (int64_t)n; staged[1] = (int64_t)k;
    int64_t current[MAX_SERVERS] = {0};
    for (size_t i = 0; i < k; ++i) current[i] = initial[i];
    for (size_t t = 0; t < n; ++t) {
        const int64_t request = requests[t];
        for (size_t x = 0; x < config_count; ++x) {
            next_work[x] = INT64_MAX;
            for (size_t y = 0; y < config_count; ++y) {
                int contains = 0;
                for (size_t j = 0; j < k; ++j) if (configs[y].point[j] == request) contains = 1;
                if (!contains) continue;
                int64_t value = work[y] + config_distance(configs[y].point, configs[x].point, k, metric);
                if (value < next_work[x]) next_work[x] = value;
            }
        }
        int64_t best_score = INT64_MAX, best_next[MAX_SERVERS] = {0};
        size_t best_slot = 0;
        int already_served = 0;
        for (size_t j = 0; j < k; ++j) if (current[j] == request) already_served = 1;
        for (size_t j = 0; j < k; ++j) best_next[j] = current[j];
        if (!already_served) {
            for (size_t slot = 0; slot < k; ++slot) {
                int64_t candidate[MAX_SERVERS] = {0};
                for (size_t j = 0; j < k; ++j) candidate[j] = j == slot ? request : current[j];
                sort_config(candidate, k);
                size_t index = find_config(configs, config_count, candidate, k);
                int64_t score = work[index] + metric[current[slot]][request];
                if (score < best_score || (score == best_score && slot < best_slot)) {
                    best_score = score; best_slot = slot;
                    for (size_t j = 0; j < k; ++j) best_next[j] = candidate[j];
                }
            }
        }
        for (size_t j = 0; j < k; ++j) staged[2 + t*k + j] = best_next[j];
        for (size_t j = 0; j < k; ++j) current[j] = best_next[j];
        for (size_t x = 0; x < config_count; ++x) work[x] = next_work[x];
    }
    for (size_t i = 0; i < 2 + n*k; ++i) store_i64_le(output, 8*i, staged[i]);
    return (int64_t)output_bytes;
}
