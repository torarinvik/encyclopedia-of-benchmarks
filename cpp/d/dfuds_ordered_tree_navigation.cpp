#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 31;
constexpr std::size_t kMaxQ = 32;
constexpr std::size_t kMaxInput = 129;
constexpr std::size_t kMaxBits = 2 * kMaxN;
constexpr std::size_t kMaxOutputWords = 4 + kMaxQ;

bool bit_at(std::uint64_t bits, std::size_t position) noexcept {
    return ((bits >> (position - 1)) & 1U) != 0;
}

std::size_t find_close(std::uint64_t bits, std::size_t length,
                       std::size_t open_position) noexcept {
    int balance = 0;
    for (std::size_t position = open_position; position <= length; ++position) {
        balance += bit_at(bits, position) ? 1 : -1;
        if (balance == 0) return position;
    }
    return length + 1;
}

std::size_t find_open(std::uint64_t bits, std::size_t position) noexcept {
    if (bit_at(bits, position)) return position;
    int balance = 0;
    for (std::size_t candidate = position; candidate > 0; --candidate) {
        balance += bit_at(bits, candidate) ? -1 : 1;
        if (balance == 0) return candidate;
    }
    return 0;
}

std::size_t previous_zero(std::uint64_t bits, std::size_t position) noexcept {
    for (std::size_t candidate = position; candidate > 1; --candidate)
        if (!bit_at(bits, candidate - 1)) return candidate - 1;
    return 0;
}

void write_i64_le(std::uint8_t* output, std::size_t offset,
                  std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t dfuds_ordered_tree_navigation(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInput) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(kMaxN) ||
        q_value < 0 || q_value > static_cast<std::int64_t>(kMaxQ)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto q = static_cast<std::size_t>(q_value);
    if (length != 2 + n - 1 + 3 * q) return -1;

    std::array<std::size_t, kMaxN> parent{};
    for (std::size_t vertex = 1; vertex < n; ++vertex) {
        const auto value = input[1 + vertex];
        if (value < 0 || static_cast<std::uint64_t>(value) >= vertex) return -1;
        parent[vertex] = static_cast<std::size_t>(value);
    }
    const std::size_t query_base = n + 1;
    for (std::size_t index = 0; index < q; ++index) {
        const auto offset = query_base + 3 * index;
        const auto opcode = input[offset], node = input[offset + 1], argument = input[offset + 2];
        if (node < 0 || node >= n_value) return -1;
        if (opcode == 0 || opcode == 2) {
            if (argument != 0) return -1;
        } else if (opcode == 1) {
            if (argument < 0 || static_cast<std::uint64_t>(argument) > n) return -1;
        } else return -1;
    }

    std::array<std::size_t, kMaxN> order{}, stack_node{}, next_child{};
    std::size_t order_count = 1, depth = 1;
    next_child[0] = 1;
    while (depth > 0) {
        const auto frame = depth - 1;
        const auto node = stack_node[frame];
        auto child = next_child[frame];
        while (child < n && parent[child] != node) ++child;
        if (child < n) {
            next_child[frame] = child + 1;
            order[order_count++] = child;
            stack_node[depth] = child;
            next_child[depth] = 1;
            ++depth;
        } else {
            --depth;
        }
    }
    if (order_count != n) return -1;

    std::array<std::size_t, kMaxN> descriptor{};
    std::array<int, kMaxBits + 2> position_to_node{};
    position_to_node.fill(-1);
    std::uint64_t packed = 1;
    std::size_t bit_length = 1;
    for (std::size_t node = 0; node < n; ++node) {
        std::size_t degree = 0;
        for (std::size_t child = 1; child < n; ++child)
            if (parent[child] == order[node]) ++degree;
        descriptor[node] = bit_length + 1;
        position_to_node[descriptor[node]] = static_cast<int>(node);
        for (std::size_t child = 0; child < degree; ++child)
            packed |= UINT64_C(1) << bit_length++;
        ++bit_length;
    }
    if (bit_length != 2 * n) return -1;

    std::array<std::int64_t, kMaxOutputWords> words{};
    words[0] = n_value;
    words[1] = static_cast<std::int64_t>(bit_length);
    words[2] = static_cast<std::int64_t>(packed);
    words[3] = q_value;
    for (std::size_t index = 0; index < q; ++index) {
        const auto offset = query_base + 3 * index;
        const auto opcode = input[offset];
        const auto node = static_cast<std::size_t>(input[offset + 1]);
        const auto argument = input[offset + 2];
        const auto start = descriptor[node];
        std::size_t degree = 0;
        while (start + degree <= bit_length && bit_at(packed, start + degree)) ++degree;
        std::int64_t answer = -1;
        if (opcode == 0) {
            answer = static_cast<std::int64_t>(degree);
        } else if (opcode == 1) {
            if (static_cast<std::uint64_t>(argument) < degree) {
                const auto target = start + degree - (static_cast<std::size_t>(argument) + 1);
                const auto child_start = find_close(packed, bit_length, target) + 1;
                if (child_start > kMaxBits + 1 || position_to_node[child_start] < 0) return -1;
                answer = position_to_node[child_start];
            }
        } else if (node != 0) {
            const auto matched_open = find_open(packed, start - 1);
            const auto parent_position = previous_zero(packed, matched_open) + 1;
            if (parent_position == 1) answer = 0;
            else if (parent_position <= kMaxBits + 1 && position_to_node[parent_position] >= 0)
                answer = position_to_node[parent_position];
            else return -1;
        }
        words[4 + index] = answer;
    }

    const auto output_words = 4 + q, required = 8 * output_words;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < output_words; ++index)
        write_i64_le(output, 8 * index, words[index]);
    return static_cast<std::int64_t>(required);
}
