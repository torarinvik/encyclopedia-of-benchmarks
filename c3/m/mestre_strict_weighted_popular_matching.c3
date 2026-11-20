module mestre_strict_weighted_popular_matching;

const usz MS_A = 4, MS_J = 5, MS_N = 9, MS_PARSEABLE = 31;
const long MS_INF = 1000000000;

fn long ms_lambda_min(usz a, long target, long* row, usz* row_length,
                      long* f_category, long* label) {
    long best = MS_INF;
    for (usz i = 0; i < row_length[a]; ++i) {
        long job = row[a * MS_N + i];
        if (job == target) break;
        if (f_category[job.usz()] >= 0 && label[job.usz()] < best) best = label[job.usz()];
    }
    return best;
}

fn bool ms_augment(usz a, long* edges, long* edge_count, long* owner, bool* seen) {
    for (usz k = 0; k < edge_count[a].usz(); ++k) {
        usz job = edges[a * 2 + k].usz();
        if (seen[job]) continue;
        seen[job] = true;
        long previous = owner[job];
        if (previous < 0 || ms_augment(previous.usz(), edges, edge_count, owner, seen)) {
            owner[job] = a.long();
            return true;
        }
    }
    return false;
}

fn long ms_solve(usz applicants, usz jobs, long* weights, usz* lengths, long* listed) {
    long[MS_A * MS_N] row = {};
    usz[MS_A] row_length = {};
    for (usz a = 0; a < applicants; ++a) {
        for (usz i = 0; i < lengths[a]; ++i) row[a * MS_N + row_length[a]++] = listed[a * MS_J + i];
        row[a * MS_N + row_length[a]++] = jobs.long() + a.long();
    }

    long[MS_A] category_weight = {};
    usz category_count = 0;
    for (usz a = 0; a < applicants; ++a) {
        bool found = false;
        for (usz c = 0; c < category_count; ++c) if (category_weight[c] == weights[a]) found = true;
        if (!found) category_weight[category_count++] = weights[a];
    }
    for (usz i = 0; i < category_count; ++i) for (usz j = i + 1; j < category_count; ++j)
        if (category_weight[j] > category_weight[i]) { long t = category_weight[i]; category_weight[i] = category_weight[j]; category_weight[j] = t; }
    usz[MS_A] category = {};
    for (usz a = 0; a < applicants; ++a) while (category_weight[category[a]] != weights[a]) category[a]++;

    long[MS_A] first = {}, second = {};
    long[MS_N] f_category = {}, label = {};
    bool[MS_N] higher = {};
    for (usz p = 0; p < MS_N; ++p) { f_category[p] = -1; label[p] = MS_INF; }
    for (usz c = 0; c < category_count; ++c) {
        for (usz a = 0; a < applicants; ++a) if (category[a] == c) {
            for (usz i = 0; i < row_length[a]; ++i) {
                long p = row[a * MS_N + i];
                if (!higher[p.usz()]) { first[a] = p; break; }
            }
        }
        for (usz a = 0; a < applicants; ++a) if (category[a] == c) {
            f_category[first[a].usz()] = c.long(); higher[first[a].usz()] = true;
        }
    }
    for (usz a = 0; a < applicants; ++a) {
        second[a] = -1;
        for (usz i = 0; i < row_length[a]; ++i) {
            long p = row[a * MS_N + i];
            if (f_category[p.usz()] < 0 || f_category[p.usz()] > category[a].long()) { second[a] = p; break; }
        }
    }
    bool[MS_A] keep_first = {}, keep_second = {};
    for (usz a = 0; a < applicants; ++a) { keep_first[a] = true; keep_second[a] = second[a] >= 0; }
    for (usz c = 0; c < category_count; ++c) {
        long weight = category_weight[c];
        if (c == 0) {
            for (usz a = 0; a < applicants; ++a) if (category[a] == c) label[first[a].usz()] = weight;
            continue;
        }
        for (usz a = 0; a < applicants; ++a) if (category[a] == c)
            if (ms_lambda_min(a, first[a], &row[0], &row_length[0], &f_category[0], &label[0]) < weight) return 0;
        for (usz p = 0; p < MS_N; ++p) if (f_category[p] == c.long()) {
            usz group[MS_A] = {}, count = 0;
            for (usz a = 0; a < applicants; ++a) if (category[a] == c && first[a] == p.long()) group[count++] = a;
            if (count == 1) {
                usz a = group[0];
                long earlier = ms_lambda_min(a, first[a], &row[0], &row_length[0], &f_category[0], &label[0]);
                label[p] = earlier >= MS_INF ? weight : (earlier - weight < weight ? earlier - weight : weight);
            } else {
                label[p] = weight;
                for (usz i = 0; i < count; ++i) {
                    usz a = group[i];
                    if (ms_lambda_min(a, p.long(), &row[0], &row_length[0], &f_category[0], &label[0]) < 2 * weight) keep_first[a] = false;
                }
            }
        }
        for (usz a = 0; a < applicants; ++a) if (category[a] == c && second[a] >= 0)
            if (ms_lambda_min(a, second[a], &row[0], &row_length[0], &f_category[0], &label[0]) < weight) keep_second[a] = false;
    }
    bool[MS_N] is_first = {};
    for (usz a = 0; a < applicants; ++a) is_first[first[a].usz()] = true;
    for (usz p = 0; p < MS_N; ++p) if (is_first[p]) {
        bool eligible = false;
        for (usz a = 0; a < applicants; ++a) if (first[a] == p.long() && keep_first[a]) eligible = true;
        if (!eligible) return 0;
    }
    long[MS_A * 2] edges = {}, edge_count[MS_A] = {};
    for (usz a = 0; a < applicants; ++a) {
        if (keep_first[a]) edges[a * 2 + edge_count[a]++] = first[a];
        if (keep_second[a] && second[a] >= 0 && !is_first[second[a].usz()]) edges[a * 2 + edge_count[a]++] = second[a];
        if (edge_count[a] == 0) return 0;
    }
    long[MS_N] owner = {};
    for (usz p = 0; p < MS_N; ++p) owner[p] = -1;
    for (usz a = 0; a < applicants; ++a) {
        bool[MS_N] seen = {};
        if (!ms_augment(a, &edges[0], &edge_count[0], &owner[0], &seen[0])) return 0;
    }
    return 1;
}

fn long mestre_strict_weighted_popular_matching(long* input, usz length)
        @export("mestre_strict_weighted_popular_matching") {
    if (input == null || length < 2 || length > MS_PARSEABLE) return -1;
    long a_value = input[0], j_value = input[1];
    if (a_value < 1 || a_value > MS_A.long() || j_value < 1 || j_value > MS_J.long()) return -1;
    usz applicants = a_value.usz(), jobs = j_value.usz();
    if (length < 2 + 2 * applicants) return -1;
    long[MS_A] weights = {}; usz[MS_A] lengths = {}; usz total = 0;
    for (usz a = 0; a < applicants; ++a) {
        weights[a] = input[2 + a];
        long size = input[2 + applicants + a];
        if (weights[a] < 1 || weights[a] > 1000 || size < 1 || size > jobs.long()) return -1;
        lengths[a] = size.usz(); total += lengths[a];
    }
    if (length != 2 + 2 * applicants + total) return -1;
    long[MS_A * MS_J] listed = {}; usz cursor = 2 + 2 * applicants;
    for (usz a = 0; a < applicants; ++a) for (usz i = 0; i < lengths[a]; ++i) {
        long value = input[cursor++];
        if (value < 0 || value >= jobs.long()) return -1;
        for (usz k = 0; k < i; ++k) if (listed[a * MS_J + k] == value) return -1;
        listed[a * MS_J + i] = value;
    }
    ms_solve(applicants, jobs, &weights[0], &lengths[0], &listed[0])
}
