/* Bounded clean-room strict-list maximum-cardinality popular matching. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MP_A = 6, MP_P = 6, MP_PARSEABLE = 45 };

static bool mp_augment(int applicant, int posts, const int first[MP_A],
                       const int second[MP_A], int owner[MP_P],
                       int assignment[MP_A], bool seen[MP_P]) {
    int edge[2], count = 1;
    edge[0] = first[applicant];
    if (second[applicant] < posts) edge[count++] = second[applicant];
    if (count == 2 && edge[1] < edge[0]) { int t = edge[0]; edge[0] = edge[1]; edge[1] = t; }
    for (int i = 0; i < count; ++i) {
        const int post = edge[i];
        if (seen[post]) continue;
        seen[post] = true;
        const int previous = owner[post];
        if (previous < 0 || mp_augment(previous, posts, first, second, owner, assignment, seen)) {
            owner[post] = applicant;
            assignment[applicant] = post;
            return true;
        }
    }
    return false;
}

static int mp_solve(int applicants, int posts, const int preferences[MP_A][MP_P],
                    const int lengths[MP_A]) {
    int first[MP_A], second[MP_A];
    bool first_post[MP_P] = {false};
    for (int a = 0; a < applicants; ++a) {
        first[a] = preferences[a][0];
        first_post[first[a]] = true;
    }
    for (int a = 0; a < applicants; ++a) {
        second[a] = posts + a;
        for (int j = 0; j < lengths[a]; ++j) {
            const int candidate = preferences[a][j];
            if (!first_post[candidate]) { second[a] = candidate; break; }
        }
    }

    bool active_a[MP_A] = {false}, active_p[MP_P] = {true, true, true, true, true, true};
    int assignment[MP_A];
    for (int a = 0; a < applicants; ++a) { active_a[a] = second[a] < posts; assignment[a] = -1; }
    for (int p = posts; p < MP_P; ++p) active_p[p] = false;

    for (;;) {
        int degree[MP_P] = {0}, sole[MP_P];
        for (int p = 0; p < MP_P; ++p) sole[p] = -1;
        for (int a = 0; a < applicants; ++a) if (active_a[a]) {
            const int edge[2] = {first[a], second[a]};
            for (int k = 0; k < 2; ++k) if (active_p[edge[k]]) {
                ++degree[edge[k]]; sole[edge[k]] = a;
            }
        }
        int forced = -1;
        for (int p = 0; p < posts; ++p)
            if (active_p[p] && degree[p] == 1) { forced = p; break; }
        if (forced < 0) break;
        const int a = sole[forced];
        assignment[a] = forced;
        active_a[a] = false;
        active_p[forced] = false;
    }

    int degree[MP_P] = {0}, neighbor[MP_P][2] = {{0}}, neighbor_count[MP_P] = {0};
    int active_applicants = 0, residual_posts = 0;
    for (int a = 0; a < applicants; ++a) if (active_a[a]) {
        ++active_applicants;
        const int edge[2] = {first[a], second[a]};
        for (int k = 0; k < 2; ++k) {
            const int p = edge[k];
            if (!active_p[p]) return 0;
            if (neighbor_count[p] < 2) neighbor[p][neighbor_count[p]++] = a;
            ++degree[p];
        }
    }
    for (int p = 0; p < posts; ++p) if (active_p[p] && degree[p] > 0) {
        ++residual_posts;
        if (degree[p] != 2 || neighbor_count[p] != 2) return 0;
    }
    if (residual_posts < active_applicants || residual_posts != active_applicants) return 0;

    bool visited[MP_A] = {false};
    for (int root = 0; root < applicants; ++root) if (active_a[root] && !visited[root]) {
        int post = first[root] < second[root] ? first[root] : second[root];
        assignment[root] = post; visited[root] = true;
        int current_a = root, current_p = post;
        for (;;) {
            const int next_a = neighbor[current_p][0] != current_a ? neighbor[current_p][0] : neighbor[current_p][1];
            if (next_a == root) break;
            if (visited[next_a]) return 0;
            const int next_p = first[next_a] == current_p ? second[next_a] : first[next_a];
            assignment[next_a] = next_p; visited[next_a] = true;
            current_a = next_a; current_p = next_p;
        }
    }

    int owner[MP_P];
    for (int p = 0; p < MP_P; ++p) owner[p] = -1;
    for (int a = 0; a < applicants; ++a) if (assignment[a] >= 0) owner[assignment[a]] = a;
    for (int a = 0; a < applicants; ++a) if (second[a] >= posts && assignment[a] < 0) {
        bool seen[MP_P] = {false};
        (void)mp_augment(a, posts, first, second, owner, assignment, seen);
    }
    for (int a = 0; a < applicants; ++a) if (assignment[a] < 0) assignment[a] = posts + a;
    for (int p = 0; p < posts; ++p) if (first_post[p] && owner[p] < 0) {
        int a = 0; while (first[a] != p) ++a;
        const int old = assignment[a];
        if (old < posts) owner[old] = -1;
        assignment[a] = p; owner[p] = a;
    }
    int result = 0;
    for (int a = 0; a < applicants; ++a) if (assignment[a] < posts) ++result;
    return result;
}

int64_t maximum_cardinality_popular_matching(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MP_PARSEABLE) return -1;
    const int64_t a64 = input[0], p64 = input[1];
    if (a64 < 1 || a64 > MP_A || p64 < 1 || p64 > MP_P) return -1;
    const int applicants = (int)a64, posts = (int)p64;
    if (length < (size_t)(2 + applicants)) return -1;
    int lengths[MP_A] = {0}, total = 0;
    for (int a = 0; a < applicants; ++a) {
        const int64_t value = input[2 + a];
        if (value < 1 || value > posts) return -1;
        lengths[a] = (int)value; total += lengths[a];
    }
    if (length != (size_t)(2 + applicants + total)) return -1;
    int preferences[MP_A][MP_P] = {{0}};
    size_t cursor = (size_t)(2 + applicants);
    for (int a = 0; a < applicants; ++a) {
        for (int j = 0; j < lengths[a]; ++j) {
            const int64_t value = input[cursor++];
            if (value < 0 || value >= posts) return -1;
            for (int k = 0; k < j; ++k) if (preferences[a][k] == value) return -1;
            preferences[a][j] = (int)value;
        }
    }
    return mp_solve(applicants, posts, preferences, lengths);
}
