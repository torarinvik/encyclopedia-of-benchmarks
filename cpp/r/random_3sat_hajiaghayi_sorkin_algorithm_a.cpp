#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int V = 12, C = 32;
constexpr std::size_t In = 98, Out = 104;
void put(std::uint8_t *out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        out[at + byte] = static_cast<std::uint8_t>(bits & 255);
        bits >>= 8;
    }
}
bool reduce_by_literal(std::array<std::array<int, 3>, C> &clauses,
                       std::array<int, C> &lengths, std::array<bool, C> &active,
                       int count, int literal) {
    for (int c = 0; c < count; ++c) {
        if (!active[c]) continue;
        bool satisfied = false;
        for (int j = 0; j < lengths[c]; ++j) if (clauses[c][j] == literal) satisfied = true;
        if (satisfied) { active[c] = false; continue; }
        int write = 0;
        for (int j = 0; j < lengths[c]; ++j)
            if (clauses[c][j] != -literal) clauses[c][write++] = clauses[c][j];
        lengths[c] = write;
        if (write == 0) return false;
    }
    return true;
}
int choose_free_literal(int n, const std::array<std::array<int, 3>, C> &clauses,
                        const std::array<int, C> &lengths,
                        const std::array<bool, C> &active,
                        const std::array<int, V> &assigned) {
    std::array<int, V> positive{}, negative{};
    for (int c = 0; c < C; ++c) if (active[c]) {
        for (int j = 0; j < lengths[c]; ++j) {
            int lit = clauses[c][j], v = (lit > 0 ? lit : -lit) - 1;
            if (lit > 0) ++positive[v]; else ++negative[v];
        }
    }
    int variable = -1;
    for (int v = 0; v < n; ++v) {
        if (assigned[v] == 0 && (positive[v] == 0 || negative[v] == 0)) { variable = v; break; }
    }
    if (variable < 0) {
        int best_difference = -1, best_total = -1;
        for (int v = 0; v < n; ++v) if (assigned[v] == 0) {
            int difference = positive[v] - negative[v];
            if (difference < 0) difference = -difference;
            int total = positive[v] + negative[v];
            if (difference > best_difference || (difference == best_difference && total > best_total)) {
                best_difference = difference; best_total = total; variable = v;
            }
        }
    }
    if (variable < 0) return 0;
    return positive[variable] < negative[variable] ? variable + 1 : -(variable + 1);
}
}

extern "C" std::int64_t random_3sat_hajiaghayi_sorkin_algorithm_a(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 2 || length > In || input[0] < 3 || input[0] > V || input[1] < 0 || input[1] > C) return -1;
    int n = static_cast<int>(input[0]), m = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(2 + 3 * m)) return -1;
    std::array<std::array<int, 3>, C> clauses{};
    std::array<int, C> lengths{};
    std::array<bool, C> active{};
    for (int c = 0; c < m; ++c) {
        std::array<bool, V> seen{};
        for (int j = 0; j < 3; ++j) {
            auto raw = input[2 + 3 * c + j];
            if (raw == 0 || raw < -n || raw > n) return -1;
            int v = static_cast<int>(raw > 0 ? raw : -raw) - 1;
            if (seen[v]) return -1;
            seen[v] = true; clauses[c][j] = static_cast<int>(raw);
        }
        lengths[c] = 3; active[c] = true;
    }
    std::array<int, V> assigned{};
    int assigned_count = 0;
    bool failed = false;
    while (assigned_count < n && !failed) {
        int chosen = choose_free_literal(n, clauses, lengths, active, assigned);
        if (chosen == 0) { failed = true; break; }
        int v = (chosen > 0 ? chosen : -chosen) - 1;
        assigned[v] = chosen > 0 ? 1 : -1; ++assigned_count;
        if (!reduce_by_literal(clauses, lengths, active, m, chosen)) { failed = true; break; }
        while (!failed) {
            int unit = 0;
            for (int c = 0; c < m; ++c) if (active[c] && lengths[c] == 1) { unit = clauses[c][0]; break; }
            if (unit == 0) break;
            v = (unit > 0 ? unit : -unit) - 1;
            assigned[v] = unit > 0 ? 1 : -1; ++assigned_count;
            if (!reduce_by_literal(clauses, lengths, active, m, unit)) failed = true;
        }
    }
    const std::size_t bytes = 8 * static_cast<std::size_t>(n + 1);
    if (!output || capacity < bytes) return -2;
    std::array<std::uint8_t, Out> staged{};
    put(staged.data(), 0, failed ? 0 : 1);
    for (int v = 0; v < n; ++v) put(staged.data(), 8 * static_cast<std::size_t>(v + 1), assigned[v]);
    for (std::size_t byte = 0; byte < bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(bytes);
}
