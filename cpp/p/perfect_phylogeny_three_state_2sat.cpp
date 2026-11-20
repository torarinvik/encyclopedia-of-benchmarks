#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_TAXA = 8;
constexpr int MAX_CHARACTERS = 8;
constexpr int MAX_LITERALS = 48;
constexpr std::size_t MAX_INPUT = 67;
using Graph = std::array<std::array<std::uint8_t, MAX_LITERALS>, MAX_LITERALS>;

void add_clause(Graph &graph, Graph &reverse, int left, int right) {
    const int from_left = left ^ 1;
    const int from_right = right ^ 1;
    graph[from_left][right] = 1;
    reverse[right][from_left] = 1;
    graph[from_right][left] = 1;
    reverse[left][from_right] = 1;
}

void finish_dfs(int vertex, int count, const Graph &graph,
                std::array<bool, MAX_LITERALS> &seen,
                std::array<int, MAX_LITERALS> &order, int &order_count) {
    seen[vertex] = true;
    for (int next = 0; next < count; ++next)
        if (graph[vertex][next] && !seen[next])
            finish_dfs(next, count, graph, seen, order, order_count);
    order[order_count++] = vertex;
}

void component_dfs(int vertex, int count, const Graph &reverse,
                   std::array<int, MAX_LITERALS> &component, int label) {
    component[vertex] = label;
    for (int next = 0; next < count; ++next)
        if (reverse[vertex][next] && component[next] < 0)
            component_dfs(next, count, reverse, component, label);
}
} // namespace

extern "C" std::int64_t perfect_phylogeny_three_state_2sat(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > MAX_INPUT) return -1;
    const auto taxa_raw = input[0], characters_raw = input[1];
    if (taxa_raw < 1 || taxa_raw > MAX_TAXA || characters_raw < 0 || characters_raw > MAX_CHARACTERS)
        return -1;
    const int taxa = static_cast<int>(taxa_raw);
    const int characters = static_cast<int>(characters_raw);
    if (length != 2u + static_cast<std::size_t>(taxa * characters)) return -1;

    std::array<std::array<std::uint16_t, 3>, MAX_CHARACTERS> masks{};
    for (int taxon = 0; taxon < taxa; ++taxon) {
        for (int character = 0; character < characters; ++character) {
            const auto state = input[2 + taxon * characters + character];
            if (state < 0 || state > 2) return -1;
            masks[character][static_cast<std::size_t>(state)] |=
                static_cast<std::uint16_t>(1u << taxon);
        }
    }

    Graph graph{}, reverse{};
    for (int character = 0; character < characters; ++character) {
        const int v0 = 3 * character, v1 = v0 + 1, v2 = v0 + 2;
        add_clause(graph, reverse, 2 * v0, 2 * v1);
        add_clause(graph, reverse, 2 * v0, 2 * v2);
        add_clause(graph, reverse, 2 * v1, 2 * v2);
        int present = 0, missing = -1;
        for (int state = 0; state < 3; ++state) {
            if (masks[character][static_cast<std::size_t>(state)]) ++present;
            else missing = state;
        }
        if (present == 2) {
            const int absent_literal = 2 * (3 * character + missing) + 1;
            add_clause(graph, reverse, absent_literal, absent_literal);
        }
    }
    const auto universe = static_cast<std::uint16_t>((1u << taxa) - 1u);
    for (int left_character = 0; left_character < characters; ++left_character) {
        for (int right_character = left_character + 1; right_character < characters; ++right_character) {
            for (int left_state = 0; left_state < 3; ++left_state) {
                const auto left = masks[left_character][left_state];
                for (int right_state = 0; right_state < 3; ++right_state) {
                    const auto right = masks[right_character][right_state];
                    const auto both = static_cast<std::uint16_t>(left & right);
                    const auto left_only = static_cast<std::uint16_t>(left & universe & ~right);
                    const auto right_only = static_cast<std::uint16_t>(right & universe & ~left);
                    const auto neither = static_cast<std::uint16_t>(universe & ~(left | right));
                    if (both && left_only && right_only && neither) {
                        const int left_variable = 3 * left_character + left_state;
                        const int right_variable = 3 * right_character + right_state;
                        add_clause(graph, reverse, 2 * left_variable + 1,
                                   2 * right_variable + 1);
                    }
                }
            }
        }
    }

    const int literal_count = 6 * characters;
    std::array<bool, MAX_LITERALS> seen{};
    std::array<int, MAX_LITERALS> order{};
    int order_count = 0;
    for (int literal = 0; literal < literal_count; ++literal)
        if (!seen[literal]) finish_dfs(literal, literal_count, graph, seen, order, order_count);
    std::array<int, MAX_LITERALS> component{};
    component.fill(-1);
    int label = 0;
    while (order_count > 0) {
        const int literal = order[--order_count];
        if (component[literal] < 0)
            component_dfs(literal, literal_count, reverse, component, label++);
    }
    for (int variable = 0; variable < 3 * characters; ++variable)
        if (component[2 * variable] == component[2 * variable + 1]) return 0;
    return 1;
}
