#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_side = 8;
constexpr int max_vertices = 2 * max_side;
constexpr std::size_t max_parseable_input_length = max_side + 3;

bool augment_left(int left, int left_count, int right_count,
                 const std::array<std::uint16_t, max_side>& rows,
                 const std::array<std::int8_t, max_vertices>& states,
                 std::array<std::int8_t, max_side>& match_right,
                 std::array<bool, max_side>& seen) {
    for (int right = 0; right < right_count; ++right) {
        if ((rows[left] & (std::uint16_t{1} << right)) == 0 || seen[right]
            || states[left_count + right] != -1) continue;
        seen[right] = true;
        const int owner = match_right[right];
        if (owner == -1 || augment_left(owner, left_count, right_count, rows,
                                         states, match_right, seen)) {
            match_right[right] = static_cast<std::int8_t>(left);
            return true;
        }
    }
    return false;
}

int maximum_matching(int left_count, int right_count,
                     const std::array<std::uint16_t, max_side>& rows,
                     const std::array<std::int8_t, max_vertices>& states,
                     std::array<std::int8_t, max_side>& match_right) {
    match_right.fill(-1);
    int size = 0;
    for (int left = 0; left < left_count; ++left) {
        if (states[left] != -1) continue;
        std::array<bool, max_side> seen{};
        if (augment_left(left, left_count, right_count, rows, states, match_right, seen)) ++size;
    }
    return size;
}

int bit_count(std::uint32_t value) {
    int count = 0;
    while (value != 0) { count += static_cast<int>(value & 1u); value >>= 1; }
    return count;
}

std::uint32_t alternating_cover(int left_count, int right_count,
                                const std::array<std::uint16_t, max_side>& rows,
                                const std::array<std::int8_t, max_side>& match_right) {
    std::array<bool, max_side> matched_left{};
    std::array<bool, max_side> reached_left{};
    std::array<bool, max_side> reached_right{};
    std::array<int, max_side> queue{};
    int head = 0, tail = 0;
    for (int right = 0; right < right_count; ++right)
        if (match_right[right] >= 0) matched_left[match_right[right]] = true;
    for (int left = 0; left < left_count; ++left) {
        if (!matched_left[left]) { reached_left[left] = true; queue[tail++] = left; }
    }
    while (head < tail) {
        const int left = queue[head++];
        for (int right = 0; right < right_count; ++right) {
            if ((rows[left] & (std::uint16_t{1} << right)) == 0 || reached_right[right]
                || match_right[right] < 0) continue;
            reached_right[right] = true;
            const int owner = match_right[right];
            if (!reached_left[owner]) { reached_left[owner] = true; queue[tail++] = owner; }
        }
    }
    std::uint32_t result = 0;
    for (int left = 0; left < left_count; ++left) if (!reached_left[left]) result |= 1u << left;
    for (int right = 0; right < right_count; ++right)
        if (reached_right[right]) result |= 1u << (left_count + right);
    return result;
}

int minimum_completion_size(int left_count, int right_count,
                            const std::array<std::uint16_t, max_side>& rows,
                            const std::array<std::int8_t, max_vertices>& input_states) {
    auto states = input_states;
    bool changed;
    do {
        changed = false;
        for (int left = 0; left < left_count; ++left) {
            for (int right = 0; right < right_count; ++right) {
                if ((rows[left] & (std::uint16_t{1} << right)) == 0) continue;
                const int rv = left_count + right;
                if (states[left] == 0 && states[rv] == 0) return -1;
                if (states[left] == 0 && states[rv] == -1) { states[rv] = 1; changed = true; }
                else if (states[rv] == 0 && states[left] == -1) { states[left] = 1; changed = true; }
            }
        }
    } while (changed);
    int forced_in = 0;
    for (int i = 0; i < left_count + right_count; ++i) if (states[i] == 1) ++forced_in;
    std::array<std::int8_t, max_side> match_right{};
    return forced_in + maximum_matching(left_count, right_count, rows, states, match_right);
}

std::uint32_t canonical_cover(int left_count, int right_count,
                              const std::array<std::uint16_t, max_side>& rows, int optimum) {
    std::array<std::int8_t, max_vertices> states{};
    states.fill(-1);
    for (int vertex = 0; vertex < left_count + right_count; ++vertex) {
        states[vertex] = 0;
        if (minimum_completion_size(left_count, right_count, rows, states) != optimum)
            states[vertex] = 1;
    }
    std::uint32_t result = 0;
    for (int vertex = 0; vertex < left_count + right_count; ++vertex)
        if (states[vertex] == 1) result |= 1u << vertex;
    return result;
}
} // namespace

extern "C" std::int64_t bipartite_minimum_vertex_cover(const std::int64_t* input,
                                                         std::size_t length) {
    if (input == nullptr || length < 2 || length > max_parseable_input_length) return -1;
    const auto left_value = input[0], right_value = input[1];
    if (left_value < 0 || left_value > max_side || right_value < 0 || right_value > max_side) return -1;
    const int left_count = static_cast<int>(left_value), right_count = static_cast<int>(right_value);
    if (length != static_cast<std::size_t>(left_count + 2)) return -1;
    const std::uint16_t domain = static_cast<std::uint16_t>((1u << right_count) - 1u);
    std::array<std::uint16_t, max_side> rows{};
    for (int left = 0; left < left_count; ++left) {
        const auto row = input[2 + left];
        if (row < 0 || (static_cast<std::uint64_t>(row) & ~static_cast<std::uint64_t>(domain)) != 0) return -1;
        rows[left] = static_cast<std::uint16_t>(row);
    }
    std::array<std::int8_t, max_vertices> free_states{};
    free_states.fill(-1);
    std::array<std::int8_t, max_side> match_right{};
    const int matching_size = maximum_matching(left_count, right_count, rows, free_states, match_right);
    const int optimum = bit_count(alternating_cover(left_count, right_count, rows, match_right));
    if (optimum != matching_size) return -1;
    return static_cast<std::int64_t>(canonical_cover(left_count, right_count, rows, optimum));
}
