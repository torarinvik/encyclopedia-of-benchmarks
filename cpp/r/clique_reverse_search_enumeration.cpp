#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 8;
constexpr std::size_t kMaxInput = kMaxN + 1;
constexpr std::size_t kMaxCliques = 256;
constexpr std::size_t kMaxOutputBytes = 8 + kMaxCliques;

struct SearchState {
    std::size_t n{};
    std::uint16_t adjacency[kMaxN]{};
    std::uint8_t masks[kMaxCliques]{};
    std::size_t count{};
};

void visit(SearchState &state, std::uint16_t clique)
{
    state.masks[state.count++] = static_cast<std::uint8_t>(clique);
    std::size_t minimum = state.n;
    for (std::size_t vertex = 0; vertex < state.n; ++vertex) {
        if ((clique & (std::uint16_t{1} << vertex)) != 0) { minimum = vertex; break; }
    }
    for (std::size_t vertex = 0; vertex < minimum; ++vertex) {
        const auto bit = static_cast<std::uint16_t>(std::uint16_t{1} << vertex);
        if ((clique & bit) == 0 && (state.adjacency[vertex] & clique) == clique)
            visit(state, static_cast<std::uint16_t>(clique | bit));
    }
}

void store_i64_le(std::uint8_t *output, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t clique_reverse_search_enumeration(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept
{
    if (input == nullptr || length < 2 || length > kMaxInput) return -1;
    const auto n_value = input[0];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(kMaxN) ||
        length != static_cast<std::size_t>(n_value) + 1) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    SearchState state{};
    state.n = n;
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        const auto raw = input[vertex + 1];
        if (raw < 0 || raw >= (std::int64_t{1} << n) ||
            (raw & (std::int64_t{1} << vertex)) != 0) return -1;
        state.adjacency[vertex] = static_cast<std::uint16_t>(raw);
    }
    for (std::size_t left = 0; left < n; ++left) {
        for (std::size_t right = left + 1; right < n; ++right) {
            const bool edge_left = (state.adjacency[left] & (std::uint16_t{1} << right)) != 0;
            const bool edge_right = (state.adjacency[right] & (std::uint16_t{1} << left)) != 0;
            if (edge_left != edge_right) return -1;
        }
    }
    visit(state, 0);
    const auto required = 8 + state.count;
    if (output == nullptr || capacity < required) return -2;
    std::uint8_t staged[kMaxOutputBytes]{};
    store_i64_le(staged, static_cast<std::int64_t>(state.count));
    for (std::size_t index = 0; index < state.count; ++index) staged[8 + index] = state.masks[index];
    for (std::size_t byte = 0; byte < required; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(required);
}
