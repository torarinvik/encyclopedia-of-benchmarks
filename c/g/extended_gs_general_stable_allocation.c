/* Bounded Extended-GS for concave multi-unit stable allocations. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_EDGES = 4, MAX_INPUT = 19, MAX_OUTPUT_BYTES = 104, INF = 255 };

static int64_t utility(int64_t first, int64_t second, int64_t count)
{
    return count == 0 ? 0 : first + (count == 2 ? second : 0);
}

static void choose_men(size_t men, size_t women, int64_t quota, size_t edges,
                       const int64_t *mf, const int64_t *ms,
                       const int64_t *lower, const int64_t *upper,
                       int64_t *answer)
{
    int64_t best_value = -1;
    size_t codes = 1;
    for (size_t e = 0; e < edges; ++e) codes *= 3;
    for (size_t code = 0; code < codes; ++code) {
        size_t rem = code;
        int64_t candidate[MAX_EDGES] = {0};
        for (size_t e = edges; e-- > 0;) {
            candidate[e] = (int64_t)(rem % 3);
            rem /= 3;
        }
        int feasible = 1;
        for (size_t e = 0; e < edges; ++e)
            if (candidate[e] < lower[e] || candidate[e] > upper[e]) feasible = 0;
        for (size_t i = 0; i < men; ++i) {
            int64_t total = 0;
            for (size_t j = 0; j < women; ++j) total += candidate[i * women + j];
            if (total > quota) feasible = 0;
        }
        if (!feasible) continue;
        int64_t value = 0;
        for (size_t e = 0; e < edges; ++e) value += utility(mf[e], ms[e], candidate[e]);
        if (value > best_value) {
            best_value = value;
            for (size_t e = 0; e < edges; ++e) answer[e] = candidate[e];
        }
    }
}

static void choose_women(size_t men, size_t women, int64_t quota, size_t edges,
                         const int64_t *wf, const int64_t *ws,
                         const int64_t *upper, int64_t *answer)
{
    int64_t best_value = -1;
    size_t codes = 1;
    for (size_t e = 0; e < edges; ++e) codes *= 3;
    for (size_t code = 0; code < codes; ++code) {
        size_t rem = code;
        int64_t candidate[MAX_EDGES] = {0};
        for (size_t e = edges; e-- > 0;) {
            candidate[e] = (int64_t)(rem % 3);
            rem /= 3;
        }
        int feasible = 1;
        for (size_t e = 0; e < edges; ++e)
            if (candidate[e] > upper[e]) feasible = 0;
        for (size_t j = 0; j < women; ++j) {
            int64_t total = 0;
            for (size_t i = 0; i < men; ++i) total += candidate[i * women + j];
            if (total > quota) feasible = 0;
        }
        if (!feasible) continue;
        int64_t value = 0;
        for (size_t e = 0; e < edges; ++e) value += utility(wf[e], ws[e], candidate[e]);
        if (value > best_value) {
            best_value = value;
            for (size_t e = 0; e < edges; ++e) answer[e] = candidate[e];
        }
    }
}

static void put_i64(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t extended_gs_general_stable_allocation(const int64_t *input, size_t length,
                                               uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > 2 || input[1] < 1 || input[1] > 2 || input[2] < 1 || input[2] > 2) return -1;
    const size_t men = (size_t)input[0], women = (size_t)input[1];
    const int64_t quota = input[2];
    const size_t edges = men * women;
    if (length != 3 + 4 * edges) return -1;
    int64_t mf[MAX_EDGES], ms[MAX_EDGES], wf[MAX_EDGES], ws[MAX_EDGES];
    for (size_t e = 0; e < edges; ++e) {
        mf[e] = input[3 + 4 * e]; ms[e] = input[4 + 4 * e];
        wf[e] = input[5 + 4 * e]; ws[e] = input[6 + 4 * e];
        if (mf[e] < 0 || mf[e] > 8 || ms[e] < 0 || ms[e] > mf[e] ||
            wf[e] < 0 || wf[e] > 8 || ws[e] < 0 || ws[e] > wf[e]) return -1;
    }
    int64_t x_w[MAX_EDGES] = {0}, z_m[MAX_EDGES], z_w[MAX_EDGES] = {0};
    int64_t x_m[MAX_EDGES] = {0}, next_w[MAX_EDGES] = {0};
    for (size_t e = 0; e < edges; ++e) z_m[e] = INF;
    int converged = 0;
    for (size_t iteration = 0; iteration < 3 * edges + 2; ++iteration) {
        choose_men(men, women, quota, edges, mf, ms, x_w, z_m, x_m);
        choose_women(men, women, quota, edges, wf, ws, x_m, next_w);
        converged = 1;
        for (size_t e = 0; e < edges; ++e) if (x_m[e] != next_w[e]) converged = 0;
        if (converged) break;
        for (size_t e = 0; e < edges; ++e) {
            if (x_m[e] > next_w[e]) { z_m[e] = next_w[e]; z_w[e] = INF; }
            x_w[e] = next_w[e];
        }
    }
    if (!converged) return -1;
    const size_t output_values = 1 + 3 * edges;
    const size_t output_bytes = 8 * output_values;
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    put_i64(staged, 0, (int64_t)edges);
    for (size_t e = 0; e < edges; ++e) {
        put_i64(staged, 8 * (1 + e), x_m[e]);
        put_i64(staged, 8 * (1 + edges + e), z_m[e]);
        put_i64(staged, 8 * (1 + 2 * edges + e), z_w[e] > x_m[e] ? z_w[e] : x_m[e]);
    }
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
