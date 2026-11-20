#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t N = 4, F = 3, INITIAL_COPIES = 4, COPIES = 644;
constexpr std::size_t CANDIDATES = 648, POINTS = 7, PARSEABLE = 63, OUTPUT_BYTES = 5208;
constexpr std::int64_t NEG = std::numeric_limits<std::int64_t>::min() / 4;

void put(std::uint8_t* out, std::size_t at, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[at + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}

std::int64_t assign_state(std::size_t n, std::size_t f,
    const std::int64_t d[POINTS][POINTS], const std::int64_t fee[F],
    const std::int64_t cap[F], const std::int64_t* types, std::size_t copies,
    std::int64_t assignment[N]) {
    std::size_t multiplicity[F]{};
    for (std::size_t i = 0; i < copies; ++i) ++multiplicity[static_cast<std::size_t>(types[i])];
    std::size_t combinations = 1;
    for (std::size_t j = 0; j < n; ++j) combinations *= f;
    auto best = std::numeric_limits<std::int64_t>::max();
    std::int64_t best_types[N]{};
    for (std::size_t code = 0; code < combinations; ++code) {
        auto rem = code;
        std::int64_t candidate[N]{};
        std::size_t loads[F]{};
        std::int64_t service = 0;
        for (std::size_t j = n; j-- > 0;) {
            const auto kind = rem % f;
            rem /= f;
            candidate[j] = static_cast<std::int64_t>(kind);
            ++loads[kind];
            service += d[j][n + kind];
        }
        bool feasible = true;
        for (std::size_t kind = 0; kind < f; ++kind)
            if (loads[kind] > multiplicity[kind] * static_cast<std::size_t>(cap[kind])) feasible = false;
        if (feasible && service < best) {
            best = service;
            for (std::size_t j = 0; j < n; ++j) best_types[j] = candidate[j];
        }
    }
    std::size_t copy_load[CANDIDATES]{};
    for (std::size_t j = 0; j < n; ++j) {
        assignment[j] = -1;
        for (std::size_t i = 0; i < copies; ++i) {
            const auto kind = static_cast<std::size_t>(types[i]);
            if (kind == static_cast<std::size_t>(best_types[j]) && copy_load[i] < static_cast<std::size_t>(cap[kind])) {
                assignment[j] = static_cast<std::int64_t>(i);
                ++copy_load[i];
                break;
            }
        }
    }
    for (std::size_t i = 0; i < copies; ++i) best += fee[static_cast<std::size_t>(types[i])];
    return best;
}

void insert_type(std::int64_t* types, std::size_t& count, std::int64_t kind) {
    auto at = count;
    while (at > 0 && types[at - 1] > kind) { types[at] = types[at - 1]; --at; }
    types[at] = kind;
    ++count;
}

std::int64_t hunt(std::size_t n, std::size_t f,
    const std::int64_t d[POINTS][POINTS], const std::int64_t fee[F],
    const std::int64_t cap[F], const std::int64_t* types, std::size_t copies,
    const std::int64_t* assignment, std::size_t target, std::size_t l,
    std::size_t* loads, std::int64_t* profits, bool take[COPIES][N + 1],
    bool* selected) {
    for (std::size_t i = 0; i < copies; ++i) { loads[i] = 0; profits[i] = fee[static_cast<std::size_t>(types[i])]; }
    for (std::size_t j = 0; j < n; ++j) {
        const auto copy = static_cast<std::size_t>(assignment[j]);
        ++loads[copy];
        const auto old = static_cast<std::size_t>(types[copy]);
        profits[copy] += d[j][n + old] - d[j][n + target];
    }
    const auto limit = std::min(n, l * static_cast<std::size_t>(cap[target]));
    std::int64_t dp[N + 1], next[N + 1];
    for (std::size_t w = 0; w <= limit; ++w) dp[w] = NEG;
    dp[0] = 0;
    for (std::size_t i = 0; i < copies; ++i) {
        for (std::size_t w = 0; w <= limit; ++w) { next[w] = dp[w]; take[i][w] = false; }
        for (std::size_t w = 0; w <= limit; ++w) {
            if (dp[w] == NEG || w + loads[i] > limit) continue;
            const auto nw = w + loads[i];
            const auto value = dp[w] + profits[i];
            if (value > next[nw]) { next[nw] = value; take[i][nw] = true; }
        }
        for (std::size_t w = 0; w <= limit; ++w) dp[w] = next[w];
    }
    auto best = NEG;
    std::size_t best_weight = 0;
    for (std::size_t w = 0; w <= limit; ++w) if (dp[w] > best) { best = dp[w]; best_weight = w; }
    for (std::size_t i = 0; i < copies; ++i) selected[i] = false;
    for (std::size_t i = copies; i-- > 0;) {
        if (take[i][best_weight]) { selected[i] = true; best_weight -= loads[i]; }
    }
    (void)f;
    return best;
}
} // namespace

extern "C" std::int64_t capacitated_facility_location_t_hunt_local_search(
    const std::int64_t* in, std::size_t len, std::uint8_t* out, std::size_t capacity) noexcept {
    if (!in || len < 10 || len > PARSEABLE) return -1;
    const auto n0 = in[0], f0 = in[1], q0 = in[2];
    if (n0 < 1 || n0 > N || f0 < 1 || f0 > F || q0 < 1 || q0 > INITIAL_COPIES) return -1;
    const auto n = static_cast<std::size_t>(n0), f = static_cast<std::size_t>(f0), q = static_cast<std::size_t>(q0);
    const auto p = n + f;
    if (len != 3 + p * p + 2 * f + q) return -1;
    std::int64_t d[POINTS][POINTS]{}, fee[F]{}, cap[F]{};
    std::int64_t types[CANDIDATES]{};
    std::size_t at = 3;
    for (std::size_t i = 0; i < p; ++i) for (std::size_t j = 0; j < p; ++j) {
        const auto x = in[at++]; if (x < 0 || x > 20) return -1; d[i][j] = x;
    }
    for (std::size_t i = 0; i < p; ++i) {
        if (d[i][i] != 0) return -1;
        for (std::size_t j = 0; j < p; ++j) {
            if (i != j && d[i][j] == 0) return -1;
            if (d[i][j] != d[j][i]) return -1;
            for (std::size_t k = 0; k < p; ++k) if (d[i][j] > d[i][k] + d[k][j]) return -1;
        }
    }
    for (std::size_t i = 0; i < f; ++i) { fee[i] = in[at++]; if (fee[i] < 0 || fee[i] > 20) return -1; }
    for (std::size_t i = 0; i < f; ++i) { cap[i] = in[at++]; if (cap[i] < 1 || cap[i] > n0) return -1; }
    std::size_t copies = q, total_capacity = 0;
    for (std::size_t i = 0; i < q; ++i) {
        types[i] = in[at++]; if (types[i] < 0 || types[i] >= f0) return -1;
        total_capacity += static_cast<std::size_t>(cap[static_cast<std::size_t>(types[i])]);
    }
    if (total_capacity < n) return -1;
    std::sort(types, types + copies);
    std::int64_t assignment[N]{};
    auto current = assign_state(n, f, d, fee, cap, types, copies, assignment);
    std::size_t steps = 0;
    while (steps < 160) {
        bool moved = false;
        for (std::size_t target = 0; target < f; ++target) {
            std::int64_t candidate_types[CANDIDATES]{};
            std::copy(types, types + copies, candidate_types);
            auto candidate_count = copies;
            insert_type(candidate_types, candidate_count, static_cast<std::int64_t>(target));
            std::int64_t candidate_assignment[N]{};
            auto candidate_cost = assign_state(n, f, d, fee, cap, candidate_types,
                                               candidate_count, candidate_assignment);
            if (candidate_cost < current) {
                std::copy(candidate_types, candidate_types + candidate_count, types);
                copies = candidate_count; current = candidate_cost;
                std::copy(candidate_assignment, candidate_assignment + n, assignment);
                ++steps; moved = true; break;
            }
            std::size_t loads[COPIES]{}; std::int64_t profits[COPIES]{};
            bool take[COPIES][N + 1]{}; bool selected[COPIES]{};
            for (std::size_t l = 1; l <= n; ++l) {
                const auto profit = hunt(n, f, d, fee, cap, types, copies, assignment,
                                         target, l, loads, profits, take, selected);
                if (profit <= static_cast<std::int64_t>(l) * fee[target]) continue;
                std::size_t drop_count = 0;
                for (std::size_t i = 0; i < copies; ++i) if (!selected[i]) candidate_types[drop_count++] = types[i];
                candidate_count = drop_count;
                for (std::size_t i = 0; i < l; ++i) insert_type(candidate_types, candidate_count, static_cast<std::int64_t>(target));
                candidate_cost = assign_state(n, f, d, fee, cap, candidate_types,
                                              candidate_count, candidate_assignment);
                if (candidate_cost < current) {
                    std::copy(candidate_types, candidate_types + candidate_count, types);
                    copies = candidate_count; current = candidate_cost;
                    std::copy(candidate_assignment, candidate_assignment + n, assignment);
                    ++steps; moved = true; break;
                }
            }
            if (moved) break;
        }
        if (!moved) break;
    }
    const auto bytes = 8 * (3 + copies + n);
    if (!out || capacity < bytes) return -2;
    at = 0;
    put(out, at, current); at += 8; put(out, at, static_cast<std::int64_t>(steps)); at += 8;
    put(out, at, static_cast<std::int64_t>(copies)); at += 8;
    for (std::size_t i = 0; i < copies; ++i) { put(out, at, types[i]); at += 8; }
    for (std::size_t j = 0; j < n; ++j) { put(out, at, assignment[j]); at += 8; }
    return static_cast<std::int64_t>(bytes);
}
