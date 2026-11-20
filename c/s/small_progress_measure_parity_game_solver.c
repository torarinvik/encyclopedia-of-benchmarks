#include <stddef.h>
#include <stdint.h>

#define SPM_MAX_VERTICES 8
#define SPM_MAX_EDGES 20
#define SPM_MAX_INPUT 59

static int spm_compare(const uint8_t left[3], uint8_t left_top,
                       const uint8_t right[3], uint8_t right_top) {
    if (left_top != right_top) return left_top ? 1 : -1;
    if (left_top) return 0;
    for (int i = 0; i < 3; ++i) {
        if (left[i] < right[i]) return -1;
        if (left[i] > right[i]) return 1;
    }
    return 0;
}

static void spm_progress(const uint8_t target[3], uint8_t target_top, int priority,
                         const uint8_t bounds[3], uint8_t result[3], uint8_t *result_top) {
    for (int i = 0; i < 3; ++i) result[i] = target[i];
    *result_top = target_top;
    if (target_top) return;
    int included = priority < 1 ? 0 : priority < 3 ? 1 : priority < 5 ? 2 : 3;
    for (int i = included; i < 3; ++i) result[i] = 0;
    if ((priority & 1) == 0) return;
    for (int i = included - 1; i >= 0; --i) {
        if (result[i] < bounds[i]) {
            ++result[i];
            for (int suffix = i + 1; suffix < included; ++suffix) result[suffix] = 0;
            return;
        }
        result[i] = 0;
    }
    *result_top = 1;
}

int64_t small_progress_measure_parity_game_solver(const int64_t *input, size_t length) {
    if (input == NULL || length < 6 || length > SPM_MAX_INPUT) return -1;
    const int64_t n_raw = input[0], m_raw = input[1];
    if (n_raw < 1 || n_raw > SPM_MAX_VERTICES || m_raw < n_raw || m_raw > SPM_MAX_EDGES)
        return -1;
    const int n = (int)n_raw, m = (int)m_raw;
    if (length != (size_t)(2 + 2 * n + 2 * m)) return -1;

    uint8_t owners[SPM_MAX_VERTICES] = {0};
    uint8_t priorities[SPM_MAX_VERTICES] = {0};
    uint16_t adjacency[SPM_MAX_VERTICES] = {0};
    int outdegree[SPM_MAX_VERTICES] = {0};
    uint8_t bounds[3] = {0};
    uint8_t measure[SPM_MAX_VERTICES][3] = {{0}};
    uint8_t top[SPM_MAX_VERTICES] = {0};

    size_t cursor = 2;
    for (int v = 0; v < n; ++v) {
        const int64_t owner = input[cursor++], priority = input[cursor++];
        if (owner < 0 || owner > 1 || priority < 0 || priority > 5) return -1;
        owners[v] = (uint8_t)owner;
        priorities[v] = (uint8_t)priority;
        if (priority == 1) ++bounds[0];
        if (priority == 3) ++bounds[1];
        if (priority == 5) ++bounds[2];
    }
    for (int e = 0; e < m; ++e) {
        const int64_t source_raw = input[cursor++], destination_raw = input[cursor++];
        if (source_raw < 0 || source_raw >= n || destination_raw < 0 || destination_raw >= n)
            return -1;
        const int source = (int)source_raw, destination = (int)destination_raw;
        const uint16_t bit = (uint16_t)(UINT16_C(1) << destination);
        if ((adjacency[source] & bit) != 0) return -1;
        adjacency[source] |= bit;
        ++outdegree[source];
    }
    for (int v = 0; v < n; ++v) if (outdegree[v] == 0) return -1;

    for (;;) {
        int changed = 0;
        for (int v = 0; v < n; ++v) {
            uint8_t best[3] = {0, 0, 0};
            uint8_t best_top = owners[v] == 1 ? 0 : 1;
            int has_best = 0;
            for (int w = 0; w < n; ++w) {
                if ((adjacency[v] & (uint16_t)(UINT16_C(1) << w)) == 0) continue;
                uint8_t candidate[3], candidate_top;
                spm_progress(measure[w], top[w], priorities[v], bounds,
                             candidate, &candidate_top);
                if (!has_best || (owners[v] == 0
                        ? spm_compare(candidate, candidate_top, best, best_top) < 0
                        : spm_compare(candidate, candidate_top, best, best_top) > 0)) {
                    for (int i = 0; i < 3; ++i) best[i] = candidate[i];
                    best_top = candidate_top;
                    has_best = 1;
                }
            }
            if (spm_compare(measure[v], top[v], best, best_top) < 0) {
                for (int i = 0; i < 3; ++i) measure[v][i] = best[i];
                top[v] = best_top;
                changed = 1;
            }
        }
        if (!changed) break;
    }

    int64_t even_winners = 0;
    for (int v = 0; v < n; ++v) if (!top[v]) even_winners |= INT64_C(1) << v;
    return even_winners;
}
