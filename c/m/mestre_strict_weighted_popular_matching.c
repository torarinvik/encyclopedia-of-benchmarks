/* Clean-room bounded implementation of Mestre's strict weighted profile. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MS_A = 4, MS_J = 5, MS_N = 9, MS_PARSEABLE = 31, MS_INF = 1000000000 };

static int ms_category(int applicants, const int64_t weights[MS_A],
                       int categories[MS_A], int applicant_category[MS_A]) {
    int count = 0;
    for (int a = 0; a < applicants; ++a) {
        bool seen = false;
        for (int c = 0; c < count; ++c) if (categories[c] == weights[a]) seen = true;
        if (!seen) categories[count++] = (int)weights[a];
    }
    for (int i = 0; i < count; ++i) for (int j = i + 1; j < count; ++j)
        if (categories[j] > categories[i]) { int t = categories[i]; categories[i] = categories[j]; categories[j] = t; }
    for (int a = 0; a < applicants; ++a) {
        applicant_category[a] = 0;
        while (categories[applicant_category[a]] != weights[a]) ++applicant_category[a];
    }
    return count;
}

static int ms_lambda_min(int a, int target, const int rows[MS_A][MS_N],
                         const int row_length[MS_A], const int f_category[MS_N],
                         const int label[MS_N]) {
    int best = MS_INF;
    for (int i = 0; i < row_length[a]; ++i) {
        int job = rows[a][i];
        if (job == target) break;
        if (f_category[job] >= 0 && label[job] < best) best = label[job];
    }
    return best;
}

static bool ms_augment(int a, int applicant_count, const int edges[MS_A][2],
                       const int edge_count[MS_A], int owner[MS_N], bool seen[MS_N]) {
    for (int k = 0; k < edge_count[a]; ++k) {
        int job = edges[a][k];
        if (seen[job]) continue;
        seen[job] = true;
        int previous = owner[job];
        if (previous < 0 || ms_augment(previous, applicant_count, edges, edge_count, owner, seen)) {
            owner[job] = a;
            return true;
        }
    }
    (void)applicant_count;
    return false;
}

static int64_t ms_solve(int applicants, int jobs, const int64_t weights[MS_A],
                        const int lengths[MS_A], const int listed[MS_A][MS_J]) {
    int rows[MS_A][MS_N] = {{0}}, row_length[MS_A] = {0};
    for (int a = 0; a < applicants; ++a) {
        for (int j = 0; j < lengths[a]; ++j) rows[a][row_length[a]++] = listed[a][j];
        rows[a][row_length[a]++] = jobs + a;
    }

    int categories[MS_A] = {0}, category[MS_A] = {0};
    const int category_count = ms_category(applicants, weights, categories, category);
    int f[MS_A] = {-1}, second[MS_A] = {-1};
    int f_category[MS_N]; bool higher[MS_N] = {false};
    for (int j = 0; j < MS_N; ++j) f_category[j] = -1;
    for (int c = 0; c < category_count; ++c) {
        for (int a = 0; a < applicants; ++a) if (category[a] == c) {
            for (int i = 0; i < row_length[a]; ++i) if (!higher[rows[a][i]]) { f[a] = rows[a][i]; break; }
        }
        for (int a = 0; a < applicants; ++a) if (category[a] == c) {
            f_category[f[a]] = c;
            higher[f[a]] = true;
        }
    }
    for (int a = 0; a < applicants; ++a) {
        second[a] = -1;
        for (int i = 0; i < row_length[a]; ++i) {
            int job = rows[a][i];
            if (f_category[job] < 0 || f_category[job] > category[a]) { second[a] = job; break; }
        }
    }

    int label[MS_N]; bool keep_f[MS_A] = {false}, keep_s[MS_A] = {false};
    for (int j = 0; j < MS_N; ++j) label[j] = MS_INF;
    for (int a = 0; a < applicants; ++a) { keep_f[a] = true; keep_s[a] = second[a] >= 0; }
    for (int c = 0; c < category_count; ++c) {
        const int64_t weight = categories[c];
        if (c == 0) {
            for (int a = 0; a < applicants; ++a) if (category[a] == c) label[f[a]] = (int)weight;
            continue;
        }
        for (int a = 0; a < applicants; ++a) if (category[a] == c)
            if (ms_lambda_min(a, f[a], rows, row_length, f_category, label) < weight) return 0;
        for (int job = 0; job < MS_N; ++job) if (f_category[job] == c) {
            int group[MS_A], size = 0;
            for (int a = 0; a < applicants; ++a) if (category[a] == c && f[a] == job) group[size++] = a;
            if (size == 1) {
                const int a = group[0];
                int earlier = ms_lambda_min(a, f[a], rows, row_length, f_category, label);
                label[job] = earlier >= MS_INF ? (int)weight : (int)(earlier - weight < weight ? earlier - weight : weight);
            } else {
                label[job] = (int)weight;
                for (int i = 0; i < size; ++i) {
                    int a = group[i];
                    if (ms_lambda_min(a, job, rows, row_length, f_category, label) < 2 * weight) keep_f[a] = false;
                }
            }
        }
        for (int a = 0; a < applicants; ++a) if (category[a] == c && second[a] >= 0)
            if (ms_lambda_min(a, second[a], rows, row_length, f_category, label) < weight) keep_s[a] = false;
    }

    bool is_f[MS_N] = {false};
    for (int a = 0; a < applicants; ++a) is_f[f[a]] = true;
    for (int p = 0; p < MS_N; ++p) if (is_f[p]) {
        bool eligible = false;
        for (int a = 0; a < applicants; ++a) if (f[a] == p && keep_f[a]) eligible = true;
        if (!eligible) return 0;
    }
    int edges[MS_A][2] = {{0}}, edge_count[MS_A] = {0};
    for (int a = 0; a < applicants; ++a) {
        if (keep_f[a]) edges[a][edge_count[a]++] = f[a];
        if (keep_s[a] && second[a] >= 0 && !is_f[second[a]]) edges[a][edge_count[a]++] = second[a];
        if (edge_count[a] == 0) return 0;
    }
    int owner[MS_N]; for (int j = 0; j < MS_N; ++j) owner[j] = -1;
    for (int a = 0; a < applicants; ++a) {
        bool seen[MS_N] = {false};
        if (!ms_augment(a, applicants, edges, edge_count, owner, seen)) return 0;
    }
    return 1;
}

int64_t mestre_strict_weighted_popular_matching(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MS_PARSEABLE) return -1;
    const int64_t a64 = input[0], j64 = input[1];
    if (a64 < 1 || a64 > MS_A || j64 < 1 || j64 > MS_J) return -1;
    const int applicants = (int)a64, jobs = (int)j64;
    if (length < (size_t)(2 + 2 * applicants)) return -1;
    int64_t weights[MS_A] = {0}; int lengths[MS_A] = {0}, total = 0;
    for (int a = 0; a < applicants; ++a) {
        weights[a] = input[2 + a];
        if (weights[a] < 1 || weights[a] > 1000) return -1;
        int64_t size = input[2 + applicants + a];
        if (size < 1 || size > jobs) return -1;
        lengths[a] = (int)size; total += lengths[a];
    }
    if (length != (size_t)(2 + 2 * applicants + total)) return -1;
    int listed[MS_A][MS_J] = {{0}}; size_t cursor = (size_t)(2 + 2 * applicants);
    for (int a = 0; a < applicants; ++a) for (int i = 0; i < lengths[a]; ++i) {
        int64_t value = input[cursor++];
        if (value < 0 || value >= jobs) return -1;
        for (int k = 0; k < i; ++k) if (listed[a][k] == value) return -1;
        listed[a][i] = (int)value;
    }
    return ms_solve(applicants, jobs, weights, lengths, listed);
}
