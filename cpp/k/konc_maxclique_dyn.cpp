// Clean-room bounded MaxCliqueDyn-style colored branch and bound.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr int MAX_VERTICES = 24;
constexpr std::size_t MAX_PARSEABLE_INPUT = 26;
struct Candidate { int vertex = 0; int bound = 0; };
struct Search {
    std::array<std::uint64_t, MAX_VERTICES> adjacency{};
    std::array<int, MAX_VERTICES> chosen{};
    int chosen_count = 0;
    int best = 0;
    std::array<int, MAX_VERTICES + 2> steps{};
    std::array<int, MAX_VERTICES + 2> prior_child_steps{};
    int total_color_calls = 0;
};

void degree_order(const Search& search, const int* vertices, int count,
                  Candidate* ordered) {
    std::array<std::pair<int, int>, MAX_VERTICES> items{};
    int maximum_degree = 0;
    for (int i = 0; i < count; ++i) {
        int degree = 0;
        for (int j = 0; j < count; ++j)
            degree += static_cast<int>((search.adjacency[vertices[i]] >> vertices[j]) & 1U);
        items[static_cast<std::size_t>(i)] = {degree, vertices[i]};
        maximum_degree = std::max(maximum_degree, degree);
    }
    std::sort(items.begin(), items.begin() + count, [](auto left, auto right) {
        return left.first != right.first ? left.first > right.first : left.second < right.second;
    });
    for (int i = 0; i < count; ++i)
        ordered[i] = {items[static_cast<std::size_t>(i)].second,
                      std::min(i, maximum_degree) + 1};
}

void expand(Search& search, const Candidate* candidates, int count, int level) {
    search.steps[static_cast<std::size_t>(level)] +=
        search.steps[static_cast<std::size_t>(level - 1)] -
        search.prior_child_steps[static_cast<std::size_t>(level)];
    search.prior_child_steps[static_cast<std::size_t>(level)] =
        search.steps[static_cast<std::size_t>(level - 1)];
    while (count > 0) {
        if (search.chosen_count + candidates[count - 1].bound <= search.best) return;
        const int vertex = candidates[count - 1].vertex;
        search.chosen[static_cast<std::size_t>(search.chosen_count++)] = vertex;
        std::array<int, MAX_VERTICES> neighbors{};
        int neighbor_count = 0;
        for (int i = 0; i + 1 < count; ++i) {
            const int other = candidates[i].vertex;
            if (search.adjacency[static_cast<std::size_t>(vertex)] & (std::uint64_t{1} << other))
                neighbors[static_cast<std::size_t>(neighbor_count++)] = other;
        }
        if (neighbor_count > 0) {
            const int prior_steps = search.steps[static_cast<std::size_t>(level)]++;
            ++search.total_color_calls;
            if (static_cast<std::int64_t>(prior_steps) * 1000
                < static_cast<std::int64_t>(search.total_color_calls) * 25) {
                std::array<Candidate, MAX_VERTICES> reordered{};
                degree_order(search, neighbors.data(), neighbor_count, reordered.data());
                for (int i = 0; i < neighbor_count; ++i)
                    neighbors[static_cast<std::size_t>(i)] = reordered[static_cast<std::size_t>(i)].vertex;
            }

            std::array<std::uint64_t, MAX_VERTICES> class_masks{};
            std::array<int, MAX_VERTICES> colors{};
            int class_count = 0;
            for (int i = 0; i < neighbor_count; ++i) {
                int color = 0;
                while (color < class_count
                       && (class_masks[static_cast<std::size_t>(color)]
                           & search.adjacency[static_cast<std::size_t>(neighbors[static_cast<std::size_t>(i)])]))
                    ++color;
                if (color == class_count) ++class_count;
                colors[static_cast<std::size_t>(i)] = color + 1;
                class_masks[static_cast<std::size_t>(color)] |=
                    std::uint64_t{1} << neighbors[static_cast<std::size_t>(i)];
            }
            const int minimum_color = std::max(search.best - search.chosen_count + 1, 1);
            std::array<Candidate, MAX_VERTICES> child{};
            int child_count = 0;
            for (int color = minimum_color; color <= class_count; ++color)
                for (int i = 0; i < neighbor_count; ++i)
                    if (colors[static_cast<std::size_t>(i)] == color)
                        child[static_cast<std::size_t>(child_count++)] =
                            {neighbors[static_cast<std::size_t>(i)], color};
            expand(search, child.data(), child_count, level + 1);
        } else if (search.chosen_count > search.best) {
            search.best = search.chosen_count;
        }
        --search.chosen_count;
        --count;
    }
}
} // namespace

extern "C" std::int64_t konc_maxclique_dyn(const std::int64_t* input,
                                           std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > MAX_PARSEABLE_INPUT) return -1;
    const std::int64_t n64 = input[0];
    if (n64 < 0 || n64 > MAX_VERTICES || length != 1 + static_cast<std::size_t>(n64)) return -1;
    const int n = static_cast<int>(n64);
    const std::uint64_t domain = (std::uint64_t{1} << n) - 1;
    Search search;
    for (int vertex = 0; vertex < n; ++vertex) {
        const auto row = input[1 + static_cast<std::size_t>(vertex)];
        if (row < 0 || (static_cast<std::uint64_t>(row) & ~domain)) return -1;
        search.adjacency[static_cast<std::size_t>(vertex)] = static_cast<std::uint64_t>(row);
        if (search.adjacency[static_cast<std::size_t>(vertex)] & (std::uint64_t{1} << vertex)) return -1;
    }
    for (int left = 0; left < n; ++left)
        for (int right = left + 1; right < n; ++right)
            if (((search.adjacency[static_cast<std::size_t>(left)] >> right) & 1U)
                != ((search.adjacency[static_cast<std::size_t>(right)] >> left) & 1U)) return -1;
    if (n == 0) return 0;
    std::array<int, MAX_VERTICES> vertices{};
    std::array<Candidate, MAX_VERTICES> roots{};
    for (int i = 0; i < n; ++i) vertices[static_cast<std::size_t>(i)] = i;
    degree_order(search, vertices.data(), n, roots.data());
    expand(search, roots.data(), n, 1);
    return search.best;
}
