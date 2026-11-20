// Bounded clean-room tied-list maximum-cardinality popular matching.
const MP_A = 4, MP_P = 4, MP_R = 8, MP_N = 12;

fn bool mp_augment(usz applicant, usz right_count, bool* edges,
                   long* left, long* right, bool* seen) {
    for (usz post = 0; post < right_count; post++) {
        if (!edges[applicant * MP_R + post] || seen[post]) continue;
        seen[post] = true;
        long previous = right[post];
        if (previous < 0 || mp_augment(previous.usz(), right_count, edges, left, right, seen)) {
            right[post] = applicant.long();
            left[applicant] = post.long();
            return true;
        }
    }
    false
}

fn bool mp_maximum(usz applicants, usz right_count, bool* edges,
                   long* initial, long* left, long* right) {
    for (usz a = 0; a < MP_A; a++) left[a] = initial == null ? -1 : initial[a];
    for (usz p = 0; p < MP_R; p++) right[p] = -1;
    for (usz a = 0; a < applicants; a++) if (left[a] >= 0) {
        usz p = left[a].usz();
        if (p >= right_count || right[p] >= 0 || !edges[a * MP_R + p]) return false;
        right[p] = a.long();
    }
    while (true) {
        bool changed = false;
        for (usz a = 0; a < applicants; a++) if (left[a] < 0) {
            bool[8] seen = {};
            if (mp_augment(a, right_count, edges, left, right, &seen[0])) changed = true;
        }
        if (!changed) return true;
    }
}

fn long mp_solve(usz applicants, usz posts, long* ranks, long* max_rank) {
    usz right_count = posts + applicants;
    bool[32] first_edges = {};
    for (usz a = 0; a < applicants; a++) for (usz p = 0; p < posts; p++)
        first_edges[a * MP_R + p] = ranks[a * MP_P + p] == 1;
    long[4] first_left = {};
    long[8] first_right = {};
    if (!mp_maximum(applicants, right_count, &first_edges[0], null, &first_left[0], &first_right[0])) return 0;
    usz first_size = 0;
    for (usz a = 0; a < applicants; a++) if (first_left[a] >= 0) first_size++;

    long[12] state = {};
    long[12] queue = {};
    for (usz i = 0; i < applicants + right_count; i++) state[i] = -1;
    usz tail = 0;
    for (usz a = 0; a < applicants; a++) if (first_left[a] < 0) {
        state[a] = 0; queue[tail++] = a.long();
    }
    for (usz p = 0; p < posts; p++) if (first_right[p] < 0) {
        usz node = applicants + p;
        state[node] = 0; queue[tail++] = node.long();
    }
    for (usz a = 0; a < applicants; a++) {
        usz node = applicants + posts + a;
        state[node] = 0; queue[tail++] = node.long();
    }
    for (usz head = 0; head < tail; head++) {
        usz node = queue[head].usz();
        if (node < applicants) {
            usz a = node;
            if (state[node] == 0) {
                for (usz p = 0; p < posts; p++) if (ranks[a * MP_P + p] == 1 && first_left[a] != p.long()) {
                    usz target = applicants + p;
                    if (state[target] < 0) { state[target] = 1; queue[tail++] = target.long(); }
                }
            } else if (first_left[a] >= 0) {
                usz target = applicants + first_left[a].usz();
                if (state[target] < 0) { state[target] = 0; queue[tail++] = target.long(); }
            }
        } else {
            usz p = node - applicants;
            if (p < posts) {
                if (state[node] == 0) {
                    for (usz a = 0; a < applicants; a++)
                        if (ranks[a * MP_P + p] == 1 && first_left[a] != p.long() && state[a] < 0) {
                            state[a] = 1; queue[tail++] = a.long();
                        }
                } else if (first_right[p] >= 0) {
                    usz target = first_right[p].usz();
                    if (state[target] < 0) { state[target] = 0; queue[tail++] = target.long(); }
                }
            }
        }
    }

    long[12] classes = {};
    for (usz i = 0; i < applicants + right_count; i++) classes[i] = state[i] < 0 ? 2 : state[i];
    bool[32] allowed = {};
    for (usz a = 0; a < applicants; a++) {
        long best_even = posts.long() + 1;
        for (usz p = 0; p < posts; p++)
            if (ranks[a * MP_P + p] > 0 && classes[applicants + p] == 0
                && ranks[a * MP_P + p] < best_even) best_even = ranks[a * MP_P + p];
        long last_rank = max_rank[a] + 1;
        if (classes[applicants + posts + a] == 0 && last_rank < best_even) best_even = last_rank;
        for (usz p = 0; p < posts; p++) {
            long rank = ranks[a * MP_P + p];
            bool reduced = rank == 1 || (rank > 0 && rank == best_even && classes[applicants + p] == 0);
            if (!reduced) continue;
            long ac = classes[a], pc = classes[applicants + p];
            if ((ac == 1 && (pc == 1 || pc == 2)) || (ac == 2 && pc == 1)) continue;
            allowed[a * MP_R + p] = true;
        }
        if (last_rank == best_even && classes[applicants + posts + a] == 0) {
            usz p = posts + a;
            long ac = classes[a], pc = classes[applicants + p];
            if (!((ac == 1 && (pc == 1 || pc == 2)) || (ac == 2 && pc == 1))) allowed[a * MP_R + p] = true;
        }
    }
    for (usz a = 0; a < applicants; a++)
        if (first_left[a] >= 0 && !allowed[a * MP_R + first_left[a].usz()]) return 0;

    long[4] popular_left = {};
    long[8] temp_right = {};
    if (!mp_maximum(applicants, right_count, &allowed[0], &first_left[0], &popular_left[0], &temp_right[0])) return 0;
    usz rank_one = 0;
    for (usz a = 0; a < applicants; a++) {
        if (popular_left[a] < 0) return 0;
        usz p = popular_left[a].usz();
        if (p < posts && ranks[a * MP_P + p] == 1) rank_one++;
    }
    if (rank_one != first_size) return 0;

    bool[32] real_edges = {};
    long[4] initial_real = { -1, -1, -1, -1 };
    for (usz a = 0; a < applicants; a++) {
        if (popular_left[a] < posts.long()) initial_real[a] = popular_left[a];
        for (usz p = 0; p < posts; p++) real_edges[a * MP_R + p] = allowed[a * MP_R + p];
    }
    long[4] real_left = {};
    if (!mp_maximum(applicants, right_count, &real_edges[0], &initial_real[0], &real_left[0], &temp_right[0])) return 0;
    rank_one = 0;
    for (usz a = 0; a < applicants; a++) if (real_left[a] >= 0) {
        usz p = real_left[a].usz();
        if (p < posts && ranks[a * MP_P + p] == 1) rank_one++;
    }
    if (rank_one != first_size) return 0;
    long[4] final_left = {};
    if (!mp_maximum(applicants, right_count, &allowed[0], &real_left[0], &final_left[0], &temp_right[0])) return 0;
    long result = 0;
    rank_one = 0;
    for (usz a = 0; a < applicants; a++) {
        if (final_left[a] < 0) return 0;
        usz p = final_left[a].usz();
        if (p < posts) {
            result++;
            if (ranks[a * MP_P + p] == 1) rank_one++;
        }
    }
    if (rank_one != first_size) return 0;
    result
}

long ties_maximum_cardinality_popular_matching(long* input, usz length) @export("ties_maximum_cardinality_popular_matching") {
    if (input == null || length < 3 || length > 52) return -1;
    long av = input[0], pv = input[1], ev = input[2];
    if (av < 1 || av > MP_A.long() || pv < 1 || pv > MP_P.long() || ev < av || ev > av * pv) return -1;
    usz applicants = av.usz(), posts = pv.usz(), edge_count = ev.usz();
    if (length != 3 + 3 * edge_count) return -1;
    long[16] ranks = {};
    long[4] max_rank = {};
    usz cursor = 3;
    for (usz i = 0; i < edge_count; i++) {
        long a64 = input[cursor++], p64 = input[cursor++], r64 = input[cursor++];
        if (a64 < 0 || a64 >= av || p64 < 0 || p64 >= pv || r64 < 1 || r64 > pv) return -1;
        usz a = a64.usz(), p = p64.usz(), rank = r64.usz();
        if (ranks[a * MP_P + p] != 0) return -1;
        ranks[a * MP_P + p] = r64;
        if (r64 > max_rank[a]) max_rank[a] = r64;
    }
    bool has_tie = false;
    for (usz a = 0; a < applicants; a++) {
        long[5] counts = {};
        if (max_rank[a] == 0) return -1;
        for (usz p = 0; p < posts; p++) if (ranks[a * MP_P + p] > 0) counts[ranks[a * MP_P + p].usz()]++;
        for (usz rank = 1; rank <= max_rank[a].usz(); rank++) if (counts[rank] == 0) return -1;
        for (usz rank = 1; rank <= max_rank[a].usz(); rank++) if (counts[rank] > 1) has_tie = true;
    }
    if (!has_tie) return -1;
    mp_solve(applicants, posts, &ranks[0], &max_rank[0])
}
