#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 4;
constexpr std::size_t kMaxInput = 2;
constexpr std::size_t kMaxWords = 97;

struct SearchState {
    std::size_t n{};
    std::int64_t permutation[kMaxN]{};
    std::int64_t staged[kMaxWords]{};
    std::size_t cursor{};
};

void visit(SearchState &state)
{
    for (std::size_t index = 0; index < state.n; ++index)
        state.staged[state.cursor++] = state.permutation[index];

    std::size_t reverse_point = state.n;
    for (std::size_t index = 0; index + 1 < state.n; ++index) {
        if (state.permutation[index] > state.permutation[index + 1]) {
            reverse_point = index + 1;
            break;
        }
    }

    for (std::size_t child = 1; child < reverse_point; ++child) {
        const auto temporary = state.permutation[child - 1];
        state.permutation[child - 1] = state.permutation[child];
        state.permutation[child] = temporary;
        visit(state);
        state.permutation[child] = state.permutation[child - 1];
        state.permutation[child - 1] = temporary;
    }

    if (reverse_point + 2 <= state.n &&
        state.permutation[reverse_point - 1] < state.permutation[reverse_point + 1]) {
        const auto left = reverse_point;
        const auto temporary = state.permutation[left];
        state.permutation[left] = state.permutation[left + 1];
        state.permutation[left + 1] = temporary;
        visit(state);
        state.permutation[left + 1] = state.permutation[left];
        state.permutation[left] = temporary;
    }
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t reverse_search_permutation_enumeration(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept
{
    if (input == nullptr || length < 1 || length > kMaxInput) return -1;
    if (length != 1 || input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    std::size_t count = 1;
    for (std::size_t factor = 2; factor <= n; ++factor) count *= factor;
    const auto words = 1 + n * count;
    const auto required = words * 8;
    if (output == nullptr || capacity < required) return -2;

    SearchState state{};
    state.n = n;
    state.cursor = 1;
    state.staged[0] = static_cast<std::int64_t>(count);
    for (std::size_t index = 0; index < n; ++index)
        state.permutation[index] = static_cast<std::int64_t>(index + 1);
    visit(state);
    for (std::size_t word = 0; word < words; ++word)
        store_i64_le(output, word * 8, state.staged[word]);
    return static_cast<std::int64_t>(required);
}
