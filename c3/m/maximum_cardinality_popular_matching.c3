// Bounded clean-room strict-list maximum-cardinality popular matching.
const MP_A = 6, MP_P = 6, MP_PARSEABLE = 45;

fn bool mp_augment(usz applicant, usz posts, long* first, long* second,
                   long* owner, long* assignment, bool* seen) {
    long edge0 = first[applicant], edge1 = -1;
    usz count = 1;
    if (second[applicant] < posts.long()) { edge1 = second[applicant]; count++; }
    if (count == 2 && edge1 < edge0) { long temp = edge0; edge0 = edge1; edge1 = temp; }
    for (usz i = 0; i < count; i++) {
        long post = i == 0 ? edge0 : edge1;
        if (seen[post.usz()]) continue;
        seen[post.usz()] = true;
        long previous = owner[post.usz()];
        if (previous < 0 || mp_augment(previous.usz(), posts, first, second, owner, assignment, seen)) {
            owner[post.usz()] = applicant.long();
            assignment[applicant] = post;
            return true;
        }
    }
    return false;
}

fn long mp_solve(usz applicants, usz posts, long* preferences, long* lengths) {
    long[6] first = {}, second = {};
    bool[6] first_post = {};
    for (usz a = 0; a < applicants; a++) {
        first[a] = preferences[a * MP_P];
        first_post[first[a].usz()] = true;
    }
    for (usz a = 0; a < applicants; a++) {
        second[a] = posts.long() + a.long();
        for (usz j = 0; j < lengths[a].usz(); j++) {
            long candidate = preferences[a * MP_P + j];
            if (!first_post[candidate.usz()]) { second[a] = candidate; break; }
        }
    }
    bool[6] active_a = {}, active_p = {};
    long[6] assignment = {};
    for (usz a = 0; a < applicants; a++) {
        active_a[a] = second[a] < posts.long();
        assignment[a] = -1;
    }
    for (usz p = 0; p < posts; p++) active_p[p] = true;

    while (true) {
        long[6] degree = {}, sole = {};
        for (usz p = 0; p < MP_P; p++) sole[p] = -1;
        for (usz a = 0; a < applicants; a++) if (active_a[a]) {
            for (usz k = 0; k < 2; k++) {
                long edge = k == 0 ? first[a] : second[a];
                if (active_p[edge.usz()]) { degree[edge.usz()]++; sole[edge.usz()] = a.long(); }
            }
        }
        usz forced = MP_P;
        for (usz p = 0; p < posts; p++) if (active_p[p] && degree[p] == 1) { forced = p; break; }
        if (forced == MP_P) break;
        usz a = sole[forced].usz();
        assignment[a] = forced.long();
        active_a[a] = false;
        active_p[forced] = false;
    }

    long[6] degree = {}, neighbors0 = {}, neighbors1 = {}, neighbor_count = {};
    usz active_count = 0, residual_posts = 0;
    for (usz a = 0; a < applicants; a++) if (active_a[a]) {
        active_count++;
        for (usz k = 0; k < 2; k++) {
            long edge = k == 0 ? first[a] : second[a];
            if (!active_p[edge.usz()]) return 0;
            if (neighbor_count[edge.usz()] == 0) neighbors0[edge.usz()] = a.long();
            else if (neighbor_count[edge.usz()] == 1) neighbors1[edge.usz()] = a.long();
            neighbor_count[edge.usz()]++;
            degree[edge.usz()]++;
        }
    }
    for (usz p = 0; p < posts; p++) if (active_p[p] && degree[p] > 0) {
        residual_posts++;
        if (degree[p] != 2 || neighbor_count[p] != 2) return 0;
    }
    if (residual_posts < active_count || residual_posts != active_count) return 0;

    bool[6] visited = {};
    for (usz root = 0; root < applicants; root++) if (active_a[root] && !visited[root]) {
        long post = first[root] < second[root] ? first[root] : second[root];
        assignment[root] = post;
        visited[root] = true;
        usz current_a = root, current_p = post.usz();
        while (true) {
            usz next_a = neighbors0[current_p] != current_a.long()
                ? neighbors0[current_p].usz() : neighbors1[current_p].usz();
            if (next_a == root) break;
            if (visited[next_a]) return 0;
            long next_p = first[next_a] == current_p.long() ? second[next_a] : first[next_a];
            assignment[next_a] = next_p;
            visited[next_a] = true;
            current_a = next_a; current_p = next_p.usz();
        }
    }

    long[6] owner = {};
    for (usz p = 0; p < MP_P; p++) owner[p] = -1;
    for (usz a = 0; a < applicants; a++) if (assignment[a] >= 0) owner[assignment[a].usz()] = a.long();
    for (usz a = 0; a < applicants; a++) if (second[a] >= posts.long() && assignment[a] < 0) {
        bool[6] seen = {};
        mp_augment(a, posts, &first[0], &second[0], &owner[0], &assignment[0], &seen[0]);
    }
    for (usz a = 0; a < applicants; a++) if (assignment[a] < 0) assignment[a] = posts.long() + a.long();
    for (usz p = 0; p < posts; p++) if (first_post[p] && owner[p] < 0) {
        usz a = 0;
        while (first[a] != p.long()) a++;
        long old = assignment[a];
        if (old < posts.long()) owner[old.usz()] = -1;
        assignment[a] = p.long(); owner[p] = a.long();
    }
    long result = 0;
    for (usz a = 0; a < applicants; a++) if (assignment[a] < posts.long()) result++;
    result
}

long maximum_cardinality_popular_matching(long* input, usz length) @export("maximum_cardinality_popular_matching") {
    if (input == null || length < 2 || length > MP_PARSEABLE) return -1;
    long a_value = input[0], p_value = input[1];
    if (a_value < 1 || a_value > MP_A.long() || p_value < 1 || p_value > MP_P.long()) return -1;
    usz applicants = a_value.usz(), posts = p_value.usz();
    if (length < 2 + applicants) return -1;
    long[6] lengths = {};
    usz total = 0;
    for (usz a = 0; a < applicants; a++) {
        long size = input[2 + a];
        if (size < 1 || size > posts.long()) return -1;
        lengths[a] = size; total += size.usz();
    }
    if (length != 2 + applicants + total) return -1;
    long[36] preferences = {};
    usz cursor = 2 + applicants;
    for (usz a = 0; a < applicants; a++) for (usz j = 0; j < lengths[a].usz(); j++) {
        long value = input[cursor++];
        if (value < 0 || value >= posts.long()) return -1;
        for (usz k = 0; k < j; k++) if (preferences[a * MP_P + k] == value) return -1;
        preferences[a * MP_P + j] = value;
    }
    mp_solve(applicants, posts, &preferences[0], &lengths[0])
}
