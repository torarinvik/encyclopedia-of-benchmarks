module small_progress_measure_parity_game_solver;

const int SPM_MAX_VERTICES = 8;
const int SPM_MAX_EDGES = 20;
const usz SPM_MAX_INPUT = 59;

fn int spm_compare(long* left, int left_top, long* right, int right_top) {
    if (left_top != right_top) return left_top != 0 ? 1 : -1;
    if (left_top != 0) return 0;
    for (int i = 0; i < 3; i++) {
        if (left[i] < right[i]) return -1;
        if (left[i] > right[i]) return 1;
    }
    return 0;
}

fn void spm_progress(long* target, int target_top, int priority,
                     long* bounds, long* result, int* result_top) {
    for (int i = 0; i < 3; i++) result[i] = target[i];
    *result_top = target_top;
    if (target_top != 0) return;
    int included = priority < 1 ? 0 : priority < 3 ? 1 : priority < 5 ? 2 : 3;
    for (int i = included; i < 3; i++) result[i] = 0;
    if ((priority & 1) == 0) return;
    for (int i = included - 1; i >= 0; i--) {
        if (result[i] < bounds[i]) {
            result[i]++;
            for (int suffix = i + 1; suffix < included; suffix++) result[suffix] = 0;
            return;
        }
        result[i] = 0;
    }
    *result_top = 1;
}

fn long small_progress_measure_parity_game_solver(long* input, usz length)
    @export("small_progress_measure_parity_game_solver") {
    if (input == null || length < 6 || length > SPM_MAX_INPUT) return -1;
    long n_raw = input[0], m_raw = input[1];
    if (n_raw < 1 || n_raw > SPM_MAX_VERTICES || m_raw < n_raw || m_raw > SPM_MAX_EDGES)
        return -1;
    int n = (int)n_raw, m = (int)m_raw;
    if (length != (usz)(2 + 2 * n + 2 * m)) return -1;

    int[8] owners = {0};
    int[8] priorities = {0};
    long[8] adjacency = {0};
    int[8] outdegree = {0};
    long[3] bounds = {0};
    long[24] measures = {0};
    int[8] top = {0};
    usz cursor = 2;
    for (int v = 0; v < n; v++) {
        long owner = input[cursor++], priority = input[cursor++];
        if (owner < 0 || owner > 1 || priority < 0 || priority > 5) return -1;
        owners[v] = (int)owner;
        priorities[v] = (int)priority;
        if (priority == 1) bounds[0]++;
        if (priority == 3) bounds[1]++;
        if (priority == 5) bounds[2]++;
    }
    for (int e = 0; e < m; e++) {
        long source_raw = input[cursor++], destination_raw = input[cursor++];
        if (source_raw < 0 || source_raw >= n || destination_raw < 0 || destination_raw >= n)
            return -1;
        int source = (int)source_raw, destination = (int)destination_raw;
        long bit = 1L << destination;
        if ((adjacency[source] & bit) != 0) return -1;
        adjacency[source] |= bit;
        outdegree[source]++;
    }
    for (int v = 0; v < n; v++) if (outdegree[v] == 0) return -1;

    while (true) {
        int changed = 0;
        for (int v = 0; v < n; v++) {
            long[3] best = {0};
            int best_top = owners[v] == 1 ? 0 : 1;
            int has_best = 0;
            for (int w = 0; w < n; w++) {
                if ((adjacency[v] & (1L << w)) == 0) continue;
                long[3] candidate = {0};
                int candidate_top = 0;
                spm_progress(&measures[w * 3], top[w], priorities[v], bounds,
                             candidate, &candidate_top);
                int order = spm_compare(candidate, candidate_top, best, best_top);
                if (has_best == 0 || (owners[v] == 0 ? order < 0 : order > 0)) {
                    for (int i = 0; i < 3; i++) best[i] = candidate[i];
                    best_top = candidate_top;
                    has_best = 1;
                }
            }
            if (spm_compare(&measures[v * 3], top[v], best, best_top) < 0) {
                for (int i = 0; i < 3; i++) measures[v * 3 + i] = best[i];
                top[v] = best_top;
                changed = 1;
            }
        }
        if (changed == 0) break;
    }
    long winners = 0;
    for (int v = 0; v < n; v++) if (top[v] == 0) winners |= 1L << v;
    return winners;
}
