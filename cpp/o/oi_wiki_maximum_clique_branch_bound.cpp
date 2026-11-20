// Ordered candidate-intersection search with a suffix-optimum bound.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_VERTICES = 24;
constexpr std::size_t MAX_PARSEABLE_INPUT = 26;

struct CliqueSearch {
    std::uint64_t adjacency[MAX_VERTICES]{};
    int suffix_best[MAX_VERTICES]{};
    int best = 0;
};

int bit_count(std::uint64_t bits) {
    int count = 0;
    while (bits != 0) { bits &= bits - 1; ++count; }
    return count;
}

bool search_clique(CliqueSearch& search, std::uint64_t candidates, int chosen) {
    if (candidates == 0) {
        if (chosen > search.best) { search.best = chosen; return true; }
        return false;
    }
    auto remaining = candidates;
    while (remaining != 0) {
        if (chosen + bit_count(remaining) <= search.best) return false;
        const std::uint64_t bit = remaining & (~remaining + std::uint64_t{1});
        int vertex = 0;
        auto scan = bit;
        while ((scan & std::uint64_t{1}) == 0) { scan >>= 1; ++vertex; }
        remaining &= ~bit;
        if (chosen + search.suffix_best[vertex] <= search.best) return false;
        if (search_clique(search, remaining & search.adjacency[vertex], chosen + 1)) return true;
    }
    return false;
}
} // namespace

extern "C" std::int64_t oi_wiki_maximum_clique_branch_bound(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > MAX_PARSEABLE_INPUT) return -1;
    const std::int64_t n64 = input[0];
    if (n64 < 0 || n64 > static_cast<std::int64_t>(MAX_VERTICES)
        || length != 1 + static_cast<std::size_t>(n64)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    const std::uint64_t domain = (std::uint64_t{1} << n) - 1;
    CliqueSearch search;
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        const std::int64_t row = input[1 + vertex];
        if (row < 0 || (static_cast<std::uint64_t>(row) & ~domain) != 0) return -1;
        search.adjacency[vertex] = static_cast<std::uint64_t>(row);
        if ((search.adjacency[vertex] & (std::uint64_t{1} << vertex)) != 0) return -1;
    }
    for (std::size_t left = 0; left < n; ++left) {
        for (std::size_t right = left + 1; right < n; ++right) {
            const bool forward = (search.adjacency[left] & (std::uint64_t{1} << right)) != 0;
            const bool reverse = (search.adjacency[right] & (std::uint64_t{1} << left)) != 0;
            if (forward != reverse) return -1;
        }
    }
    for (std::size_t root = n; root-- > 0;) {
        const std::uint64_t greater = domain & ~((std::uint64_t{1} << (root + 1)) - 1);
        (void)search_clique(search, search.adjacency[root] & greater, 1);
        search.suffix_best[root] = search.best;
    }
    return search.best;
}
