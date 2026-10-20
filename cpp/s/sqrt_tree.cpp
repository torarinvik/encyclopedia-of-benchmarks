// Adapted from cp-algorithms Sqrt Tree; CC BY-SA 4.0, see package LICENSE.txt.
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxItems = 256;
constexpr std::size_t kMaxQueries = 256;
constexpr std::size_t kMaxLevels = 16;
constexpr std::size_t kMaxNodes = 2 * kMaxItems;
constexpr std::size_t kMaxBetween = 2 * kMaxItems;
constexpr std::size_t kMaxInputValues = 2 + kMaxItems + 2 * kMaxQueries;
constexpr std::int64_t kValueLimit = 1'000'000'000;

struct State {
    const std::int64_t* values{};
    std::int64_t prefix[kMaxLevels * kMaxItems]{};
    std::int64_t suffix[kMaxLevels * kMaxItems]{};
    std::int64_t between[kMaxLevels * kMaxBetween]{};
    std::size_t used_values[kMaxLevels]{};
    std::size_t used_between[kMaxLevels]{};
    std::size_t left[kMaxNodes]{};
    std::size_t right[kMaxNodes]{};
    std::size_t depth[kMaxNodes]{};
    std::size_t value_offset[kMaxNodes]{};
    std::size_t between_offset[kMaxNodes]{};
    std::size_t block_size[kMaxNodes]{};
    std::size_t block_count[kMaxNodes]{};
    std::size_t child_start[kMaxNodes]{};
    std::size_t children[kMaxNodes]{};
    std::size_t node_count{};
    std::size_t child_count{};
};

std::size_t create_node(State& state, std::size_t left, std::size_t right, std::size_t depth) {
    const auto node = state.node_count++;
    state.left[node] = left;
    state.right[node] = right;
    state.depth[node] = depth;
    return node;
}

void build_node(State& state, std::size_t node) {
    const auto left = state.left[node];
    const auto right = state.right[node];
    const auto length = right - left;
    const auto depth = state.depth[node];
    if (length <= 2) return;
    std::size_t block_size = 1;
    while (block_size * block_size < length) ++block_size;
    const auto block_count = (length + block_size - 1) / block_size;
    const auto value_offset = state.used_values[depth];
    const auto between_offset = state.used_between[depth];
    state.value_offset[node] = value_offset;
    state.between_offset[node] = between_offset;
    state.block_size[node] = block_size;
    state.block_count[node] = block_count;
    state.used_values[depth] += length;
    state.used_between[depth] += block_count * block_count;

    std::int64_t block_min[kMaxItems]{};
    for (std::size_t block = 0; block < block_count; ++block) {
        const auto start = left + block * block_size;
        const auto end = std::min(start + block_size, right);
        const auto first = value_offset + start - left;
        state.prefix[depth * kMaxItems + first] = state.values[start];
        for (auto index = start + 1; index < end; ++index) {
            const auto slot = value_offset + index - left;
            state.prefix[depth * kMaxItems + slot] =
                std::min(state.prefix[depth * kMaxItems + slot - 1], state.values[index]);
        }
        const auto last = value_offset + end - 1 - left;
        state.suffix[depth * kMaxItems + last] = state.values[end - 1];
        for (auto index = end - 1; index > start; --index) {
            const auto slot = value_offset + index - 1 - left;
            state.suffix[depth * kMaxItems + slot] =
                std::min(state.values[index - 1], state.suffix[depth * kMaxItems + slot + 1]);
        }
        block_min[block] = state.prefix[depth * kMaxItems + last];
    }
    for (std::size_t first = 0; first < block_count; ++first) {
        auto aggregate = block_min[first];
        for (auto last = first; last < block_count; ++last) {
            if (last != first) aggregate = std::min(aggregate, block_min[last]);
            state.between[depth * kMaxBetween + between_offset + first * block_count + last] = aggregate;
        }
    }

    const auto child_start = state.child_count;
    state.child_start[node] = child_start;
    for (std::size_t block = 0; block < block_count; ++block) {
        const auto start = left + block * block_size;
        const auto end = std::min(start + block_size, right);
        const auto child = create_node(state, start, end, depth + 1);
        state.children[state.child_count++] = child;
    }
    for (std::size_t block = 0; block < block_count; ++block)
        build_node(state, state.children[child_start + block]);
}

std::int64_t query_node(const State& state, std::size_t node, std::size_t left, std::size_t right) {
    const auto node_left = state.left[node];
    const auto node_right = state.right[node];
    if (node_right - node_left <= 2) {
        auto answer = state.values[left];
        for (auto index = left + 1; index <= right; ++index) answer = std::min(answer, state.values[index]);
        return answer;
    }
    const auto block_size = state.block_size[node];
    const auto left_block = (left - node_left) / block_size;
    const auto right_block = (right - node_left) / block_size;
    if (left_block == right_block)
        return query_node(state, state.children[state.child_start[node] + left_block], left, right);
    const auto depth = state.depth[node];
    const auto offset = state.value_offset[node];
    auto answer = state.suffix[depth * kMaxItems + offset + left - node_left];
    if (left_block + 1 < right_block) {
        const auto count = state.block_count[node];
        const auto middle = state.between_offset[node] + (left_block + 1) * count + right_block - 1;
        answer = std::min(answer, state.between[depth * kMaxBetween + middle]);
    }
    return std::min(answer, state.prefix[depth * kMaxItems + offset + right - node_left]);
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
} // namespace

extern "C" std::int64_t sqrt_tree(const std::int64_t* input, std::size_t length,
                                  std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInputValues) return -1;
    const auto item_count_value = input[0];
    const auto query_count_value = input[1];
    if (item_count_value < 1 || item_count_value > static_cast<std::int64_t>(kMaxItems) ||
        query_count_value < 0 || query_count_value > static_cast<std::int64_t>(kMaxQueries)) return -1;
    const auto item_count = static_cast<std::size_t>(item_count_value);
    const auto query_count = static_cast<std::size_t>(query_count_value);
    if (length != 2 + item_count + 2 * query_count) return -1;
    for (std::size_t index = 0; index < item_count; ++index)
        if (input[2 + index] < -kValueLimit || input[2 + index] > kValueLimit) return -1;
    const auto query_offset = 2 + item_count;
    for (std::size_t query = 0; query < query_count; ++query) {
        const auto left = input[query_offset + 2 * query];
        const auto right = input[query_offset + 2 * query + 1];
        if (left < 0 || right < left || right >= item_count_value) return -1;
    }
    const auto required = 8 * query_count;
    if (output_capacity < required || (required != 0 && output == nullptr)) return -2;

    State state{};
    state.values = input + 2;
    const auto root = create_node(state, 0, item_count, 0);
    build_node(state, root);
    for (std::size_t query = 0; query < query_count; ++query) {
        const auto left = static_cast<std::size_t>(input[query_offset + 2 * query]);
        const auto right = static_cast<std::size_t>(input[query_offset + 2 * query + 1]);
        store_i64_le(output, 8 * query, query_node(state, root, left, right));
    }
    return static_cast<std::int64_t>(required);
}
