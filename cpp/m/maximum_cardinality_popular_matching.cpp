// Bounded clean-room strict-list maximum-cardinality popular matching.
#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <initializer_list>

namespace {
constexpr int Amax = 6, Pmax = 6;
using Prefs = std::array<std::array<int, Pmax>, Amax>;
using Six = std::array<int, Amax>;

bool augment(int applicant, int posts, const Six& first, const Six& second,
             std::array<int, Pmax>& owner, Six& assignment,
             std::array<bool, Pmax>& seen) {
    std::array<int, 2> edges{first[applicant], -1};
    int count = 1;
    if (second[applicant] < posts) edges[count++] = second[applicant];
    if (count == 2 && edges[1] < edges[0]) std::swap(edges[0], edges[1]);
    for (int i = 0; i < count; ++i) {
        const int post = edges[i];
        if (seen[post]) continue;
        seen[post] = true;
        const int previous = owner[post];
        if (previous < 0 || augment(previous, posts, first, second, owner, assignment, seen)) {
            owner[post] = applicant;
            assignment[applicant] = post;
            return true;
        }
    }
    return false;
}

std::int64_t solve(int applicants, int posts, const Prefs& preferences,
                   const Six& lengths) {
    Six first{}, second{};
    std::array<bool, Pmax> first_post{};
    for (int a = 0; a < applicants; ++a) {
        first[a] = preferences[a][0];
        first_post[first[a]] = true;
    }
    for (int a = 0; a < applicants; ++a) {
        second[a] = posts + a;
        for (int j = 0; j < lengths[a]; ++j) {
            const int p = preferences[a][j];
            if (!first_post[p]) { second[a] = p; break; }
        }
    }

    std::array<bool, Amax> active_a{};
    std::array<bool, Pmax> active_p{};
    Six assignment{};
    assignment.fill(-1);
    for (int a = 0; a < applicants; ++a) active_a[a] = second[a] < posts;
    for (int p = 0; p < posts; ++p) active_p[p] = true;

    for (;;) {
        std::array<int, Pmax> degree{}, sole{};
        sole.fill(-1);
        for (int a = 0; a < applicants; ++a) if (active_a[a]) {
            for (int p : {first[a], second[a]}) if (active_p[p]) {
                ++degree[p]; sole[p] = a;
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

    std::array<int, Pmax> degree{};
    std::array<std::array<int, 2>, Pmax> neighbors{};
    std::array<int, Pmax> neighbor_count{};
    int active_count = 0, residual_posts = 0;
    for (int a = 0; a < applicants; ++a) if (active_a[a]) {
        ++active_count;
        for (int p : {first[a], second[a]}) {
            if (!active_p[p]) return 0;
            if (neighbor_count[p] < 2) neighbors[p][neighbor_count[p]++] = a;
            ++degree[p];
        }
    }
    for (int p = 0; p < posts; ++p) if (active_p[p] && degree[p] > 0) {
        ++residual_posts;
        if (degree[p] != 2 || neighbor_count[p] != 2) return 0;
    }
    if (residual_posts < active_count || residual_posts != active_count) return 0;

    std::array<bool, Amax> visited{};
    for (int root = 0; root < applicants; ++root) if (active_a[root] && !visited[root]) {
        int post = std::min(first[root], second[root]);
        assignment[root] = post;
        visited[root] = true;
        int current_a = root, current_p = post;
        for (;;) {
            const int next_a = neighbors[current_p][0] != current_a
                ? neighbors[current_p][0] : neighbors[current_p][1];
            if (next_a == root) break;
            if (visited[next_a]) return 0;
            const int next_p = first[next_a] == current_p ? second[next_a] : first[next_a];
            assignment[next_a] = next_p;
            visited[next_a] = true;
            current_a = next_a;
            current_p = next_p;
        }
    }

    std::array<int, Pmax> owner{};
    owner.fill(-1);
    for (int a = 0; a < applicants; ++a) if (assignment[a] >= 0) owner[assignment[a]] = a;
    for (int a = 0; a < applicants; ++a) if (second[a] >= posts && assignment[a] < 0) {
        std::array<bool, Pmax> seen{};
        augment(a, posts, first, second, owner, assignment, seen);
    }
    for (int a = 0; a < applicants; ++a) if (assignment[a] < 0) assignment[a] = posts + a;
    for (int p = 0; p < posts; ++p) if (first_post[p] && owner[p] < 0) {
        int a = 0;
        while (first[a] != p) ++a;
        const int old = assignment[a];
        if (old < posts) owner[old] = -1;
        assignment[a] = p;
        owner[p] = a;
    }
    int result = 0;
    for (int a = 0; a < applicants; ++a) result += assignment[a] < posts;
    return result;
}
} // namespace

extern "C" std::int64_t maximum_cardinality_popular_matching(
    const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 2 || length > 45) return -1;
    if (input[0] < 1 || input[0] > Amax || input[1] < 1 || input[1] > Pmax) return -1;
    const int applicants = static_cast<int>(input[0]);
    const int posts = static_cast<int>(input[1]);
    if (length < static_cast<std::size_t>(2 + applicants)) return -1;
    Six lengths{};
    int total = 0;
    for (int a = 0; a < applicants; ++a) {
        const auto size = input[2 + a];
        if (size < 1 || size > posts) return -1;
        lengths[a] = static_cast<int>(size);
        total += lengths[a];
    }
    if (length != static_cast<std::size_t>(2 + applicants + total)) return -1;
    Prefs preferences{};
    std::size_t cursor = static_cast<std::size_t>(2 + applicants);
    for (int a = 0; a < applicants; ++a) {
        for (int j = 0; j < lengths[a]; ++j) {
            const auto value = input[cursor++];
            if (value < 0 || value >= posts) return -1;
            for (int k = 0; k < j; ++k) if (preferences[a][k] == value) return -1;
            preferences[a][j] = static_cast<int>(value);
        }
    }
    return solve(applicants, posts, preferences, lengths);
}
