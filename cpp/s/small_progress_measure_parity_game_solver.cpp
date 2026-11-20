#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t max_vertices = 8;
constexpr std::size_t max_edges = 20;
constexpr std::size_t max_input = 59;
using Rank = std::array<std::uint8_t, 3>;

int compare(const Rank& a, bool a_top, const Rank& b, bool b_top) {
    if (a_top != b_top) return a_top ? 1 : -1;
    if (a_top) return 0;
    for (std::size_t i = 0; i < 3; ++i) {
        if (a[i] != b[i]) return a[i] < b[i] ? -1 : 1;
    }
    return 0;
}

std::pair<Rank, bool> progress(const Rank& target, bool target_top, std::uint8_t priority,
                               const Rank& bounds) {
    Rank result = target;
    if (target_top) return {result, true};
    const std::size_t included = priority < 1 ? 0 : priority < 3 ? 1 : priority < 5 ? 2 : 3;
    for (std::size_t i = included; i < 3; ++i) result[i] = 0;
    if (priority % 2 == 0) return {result, false};
    for (std::size_t i = included; i > 0; --i) {
        const auto digit = i - 1;
        if (result[digit] < bounds[digit]) {
            ++result[digit];
            for (std::size_t suffix = digit + 1; suffix < included; ++suffix) result[suffix] = 0;
            return {result, false};
        }
        result[digit] = 0;
    }
    return {Rank{0, 0, 0}, true};
}
}

extern "C" std::int64_t small_progress_measure_parity_game_solver(
        const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 6 || length > max_input) return -1;
    const auto n_raw = input[0];
    const auto m_raw = input[1];
    if (n_raw < 1 || n_raw > static_cast<std::int64_t>(max_vertices)
            || m_raw < n_raw || m_raw > static_cast<std::int64_t>(max_edges)) return -1;
    const auto n = static_cast<std::size_t>(n_raw);
    const auto m = static_cast<std::size_t>(m_raw);
    if (length != 2 + 2 * n + 2 * m) return -1;

    std::array<std::uint8_t, max_vertices> owners{};
    std::array<std::uint8_t, max_vertices> priorities{};
    std::array<std::uint16_t, max_vertices> adjacency{};
    std::array<std::uint8_t, max_vertices> outdegree{};
    Rank bounds{};
    std::array<Rank, max_vertices> measures{};
    std::array<bool, max_vertices> top{};

    std::size_t cursor = 2;
    for (std::size_t v = 0; v < n; ++v) {
        const auto owner = input[cursor++];
        const auto priority = input[cursor++];
        if (owner < 0 || owner > 1 || priority < 0 || priority > 5) return -1;
        owners[v] = static_cast<std::uint8_t>(owner);
        priorities[v] = static_cast<std::uint8_t>(priority);
        if (priority == 1) ++bounds[0];
        if (priority == 3) ++bounds[1];
        if (priority == 5) ++bounds[2];
    }
    for (std::size_t e = 0; e < m; ++e) {
        const auto source_raw = input[cursor++];
        const auto destination_raw = input[cursor++];
        if (source_raw < 0 || source_raw >= n_raw || destination_raw < 0 || destination_raw >= n_raw)
            return -1;
        const auto source = static_cast<std::size_t>(source_raw);
        const auto destination = static_cast<std::size_t>(destination_raw);
        const auto bit = static_cast<std::uint16_t>(1u << destination);
        if ((adjacency[source] & bit) != 0) return -1;
        adjacency[source] |= bit;
        ++outdegree[source];
    }
    for (std::size_t v = 0; v < n; ++v) if (outdegree[v] == 0) return -1;

    for (;;) {
        bool changed = false;
        for (std::size_t v = 0; v < n; ++v) {
            Rank best{};
            bool best_top = owners[v] == 1;
            bool has_best = false;
            for (std::size_t w = 0; w < n; ++w) {
                if ((adjacency[v] & (static_cast<std::uint16_t>(1u << w))) == 0) continue;
                auto [candidate, candidate_top] = progress(measures[w], top[w], priorities[v], bounds);
                const int order = compare(candidate, candidate_top, best, best_top);
                if (!has_best || (owners[v] == 0 ? order < 0 : order > 0)) {
                    best = candidate;
                    best_top = candidate_top;
                    has_best = true;
                }
            }
            if (compare(measures[v], top[v], best, best_top) < 0) {
                measures[v] = best;
                top[v] = best_top;
                changed = true;
            }
        }
        if (!changed) break;
    }

    std::int64_t winners = 0;
    for (std::size_t v = 0; v < n; ++v) if (!top[v]) winners |= std::int64_t{1} << v;
    return winners;
}
