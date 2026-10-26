#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxLeaves = 7;
constexpr std::size_t kMaxEdges = 11;
constexpr std::size_t kMaxInput = 23;
constexpr std::size_t kMaxStates = 945;
constexpr std::size_t kMaxDegree = 8;

void store_i64_le(std::uint8_t *output, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

std::size_t bit_count(std::uint16_t value, std::size_t n)
{
    std::size_t count = 0;
    for (std::size_t bit = 0; bit < n; ++bit) count += (value >> bit) & 1U;
    return count;
}

bool valid_tree(const std::int64_t *input, std::size_t offset, std::size_t n, std::size_t edges)
{
    std::uint16_t splits[kMaxEdges]{};
    std::uint16_t internal[kMaxEdges]{};
    std::size_t internal_count = 0;
    const auto universe = static_cast<std::uint16_t>((1U << n) - 1U);
    for (std::size_t i = 0; i < edges; ++i) {
        const auto raw = input[offset + i];
        if (raw <= 0 || static_cast<std::uint64_t>(raw) >= universe || (raw & 1) != 0) return false;
        splits[i] = static_cast<std::uint16_t>(raw);
        for (std::size_t earlier = 0; earlier < i; ++earlier) if (splits[earlier] == splits[i]) return false;
        const auto count = bit_count(splits[i], n);
        if (count == 1 || count == n - 1) {
            if (count == n - 1 && splits[i] != static_cast<std::uint16_t>(universe ^ 1U)) return false;
        } else if (count >= 2 && count <= n - 2) {
            internal[internal_count++] = splits[i];
        } else {
            return false;
        }
    }
    if (internal_count != n - 3) return false;
    for (std::size_t leaf = 1; leaf < n; ++leaf) {
        const auto pendant = static_cast<std::uint16_t>(1U << leaf);
        std::size_t found = 0;
        for (std::size_t edge = 0; edge < edges; ++edge) found += splits[edge] == pendant;
        if (found != 1) return false;
    }
    std::size_t root_pendant = 0;
    for (std::size_t edge = 0; edge < edges; ++edge) root_pendant += splits[edge] == (universe ^ 1U);
    if (root_pendant != 1) return false;
    for (std::size_t i = 0; i < internal_count; ++i) {
        for (std::size_t j = i + 1; j < internal_count; ++j) {
            const auto common = internal[i] & internal[j];
            if (common != 0 && common != internal[i] && common != internal[j]) return false;
        }
    }
    return true;
}

void sort_state(std::uint16_t *state, std::size_t count)
{
    for (std::size_t i = 1; i < count; ++i) {
        const auto value = state[i];
        std::size_t j = i;
        while (j > 0 && state[j - 1] > value) { state[j] = state[j - 1]; --j; }
        state[j] = value;
    }
}

bool same_state(const std::uint16_t *left, const std::uint16_t *right, std::size_t edges)
{
    for (std::size_t i = 0; i < edges; ++i) if (left[i] != right[i]) return false;
    return true;
}

std::uint16_t *enumerate_states(std::size_t leaves, std::uint16_t *a, std::uint16_t *b,
                               std::size_t &state_count)
{
    auto *current = a;
    auto *next = b;
    current[0] = 2; current[1] = 4; current[2] = 6;
    state_count = 1;
    std::size_t old_edges = 3;
    for (std::size_t size = 4; size <= leaves; ++size) {
        const auto new_edges = old_edges + 2;
        const auto new_bit = static_cast<std::uint16_t>(1U << (size - 1));
        std::size_t next_count = 0;
        for (std::size_t state_index = 0; state_index < state_count; ++state_index) {
            const auto *old = current + state_index * kMaxEdges;
            for (std::size_t selected_index = 0; selected_index < old_edges; ++selected_index) {
                const auto selected = old[selected_index];
                std::uint16_t candidate[kMaxEdges]{};
                std::size_t candidate_count = 0;
                for (std::size_t edge = 0; edge < old_edges; ++edge) {
                    const auto split = old[edge];
                    if (split == selected) {
                        candidate[candidate_count++] = split;
                        candidate[candidate_count++] = static_cast<std::uint16_t>(split | new_bit);
                    } else if ((selected & split) == selected) {
                        candidate[candidate_count++] = static_cast<std::uint16_t>(split | new_bit);
                    } else {
                        candidate[candidate_count++] = split;
                    }
                }
                candidate[candidate_count++] = new_bit;
                sort_state(candidate, candidate_count);
                std::size_t found = 0;
                while (found < next_count && !same_state(next + found * kMaxEdges, candidate, new_edges)) ++found;
                if (found == next_count) {
                    if (next_count >= kMaxStates) return nullptr;
                    auto *destination = next + next_count * kMaxEdges;
                    for (std::size_t edge = 0; edge < new_edges; ++edge) destination[edge] = candidate[edge];
                    ++next_count;
                }
            }
        }
        auto *swap = current;
        current = next;
        next = swap;
        state_count = next_count;
        old_edges = new_edges;
    }
    return current;
}
} // namespace

extern "C" std::int64_t nni_phylogeny_distance(const std::int64_t *input, std::size_t length,
                                                 std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 7 || length > kMaxInput) return -1;
    if (input[0] < 3 || input[0] > static_cast<std::int64_t>(kMaxLeaves)) return -1;
    const auto leaves = static_cast<std::size_t>(input[0]);
    const auto edges = 2 * leaves - 3;
    if (length != 1 + 2 * edges || !valid_tree(input, 1, leaves, edges)
        || !valid_tree(input, 1 + edges, leaves, edges)) return -1;

    std::uint16_t states_a[kMaxStates * kMaxEdges]{};
    std::uint16_t states_b[kMaxStates * kMaxEdges]{};
    std::size_t state_count = 0;
    auto *states = enumerate_states(leaves, states_a, states_b, state_count);
    if (states == nullptr) return -1;
    std::uint16_t start[kMaxEdges]{}, goal[kMaxEdges]{};
    for (std::size_t i = 0; i < edges; ++i) {
        start[i] = static_cast<std::uint16_t>(input[1 + i]);
        goal[i] = static_cast<std::uint16_t>(input[1 + edges + i]);
    }
    sort_state(start, edges); sort_state(goal, edges);
    std::size_t start_index = state_count, goal_index = state_count;
    for (std::size_t i = 0; i < state_count; ++i) {
        if (same_state(states + i * kMaxEdges, start, edges)) start_index = i;
        if (same_state(states + i * kMaxEdges, goal, edges)) goal_index = i;
    }
    if (start_index == state_count || goal_index == state_count) return -1;

    std::uint16_t neighbors[kMaxStates * kMaxDegree]{};
    std::uint8_t degree[kMaxStates]{};
    for (std::size_t left = 0; left < state_count; ++left) {
        for (std::size_t right = left + 1; right < state_count; ++right) {
            std::size_t common = 0;
            for (std::size_t i = 0; i < edges; ++i) {
                const auto left_size = bit_count(states[left * kMaxEdges + i], leaves);
                if (left_size < 2 || left_size > leaves - 2) continue;
                for (std::size_t j = 0; j < edges; ++j) {
                    const auto right_size = bit_count(states[right * kMaxEdges + j], leaves);
                    if (right_size >= 2 && right_size <= leaves - 2
                        && states[left * kMaxEdges + i] == states[right * kMaxEdges + j]) { ++common; break; }
                }
            }
            if (common + leaves == edges - 1) {
                if (degree[left] >= kMaxDegree || degree[right] >= kMaxDegree) return -1;
                neighbors[left * kMaxDegree + degree[left]++] = static_cast<std::uint16_t>(right);
                neighbors[right * kMaxDegree + degree[right]++] = static_cast<std::uint16_t>(left);
            }
        }
    }
    std::int16_t distance[kMaxStates];
    std::uint16_t queue[kMaxStates];
    for (std::size_t i = 0; i < state_count; ++i) distance[i] = -1;
    std::size_t head = 0, tail = 0;
    distance[start_index] = 0;
    queue[tail++] = static_cast<std::uint16_t>(start_index);
    while (head < tail) {
        const auto current = queue[head++];
        if (current == goal_index) break;
        for (std::size_t i = 0; i < degree[current]; ++i) {
            const auto next = neighbors[current * kMaxDegree + i];
            if (distance[next] < 0) {
                distance[next] = static_cast<std::int16_t>(distance[current] + 1);
                queue[tail++] = next;
            }
        }
    }
    if (distance[goal_index] < 0) return -1;
    if (output == nullptr || capacity < 8) return -2;
    std::uint8_t staged[8]{};
    store_i64_le(staged, distance[goal_index]);
    for (std::size_t byte = 0; byte < 8; ++byte) output[byte] = staged[byte];
    return 8;
}
