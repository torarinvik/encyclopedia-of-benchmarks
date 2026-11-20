#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 31, kMaxQ = 32, kMaxInput = 129;
constexpr std::size_t kMaxBits = 2 * kMaxN, kMaxOutputWords = 4 + kMaxQ;

void write_i64_le(std::uint8_t* output, std::size_t offset,
                  std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t bp_ordered_tree_navigation(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInput) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(kMaxN) ||
        q_value < 0 || q_value > static_cast<std::int64_t>(kMaxQ)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (length != 2 + (n - 1) + 3 * q) return -1;

    std::array<std::size_t, kMaxN> parent{};
    for (std::size_t vertex = 1; vertex < n; ++vertex) {
        const auto value = input[1 + vertex];
        if (value < 0 || static_cast<std::uint64_t>(value) >= vertex) return -1;
        parent[vertex] = static_cast<std::size_t>(value);
    }
    const std::size_t query_base = n + 1, bit_length = 2 * n;
    for (std::size_t index = 0; index < q; ++index) {
        const auto offset = query_base + 3 * index;
        const auto opcode = input[offset], first = input[offset + 1], second = input[offset + 2];
        if (opcode == 0 || opcode == 1) {
            if (first < 0 || static_cast<std::uint64_t>(first) > bit_length ||
                second < -static_cast<std::int64_t>(bit_length) || second > static_cast<std::int64_t>(bit_length)) return -1;
        } else if (opcode == 2) {
            if (first < 0 || second < first || static_cast<std::uint64_t>(second) >= bit_length) return -1;
        } else if (opcode >= 3 && opcode <= 5) {
            if (first < 0 || static_cast<std::uint64_t>(first) >= bit_length || second != 0) return -1;
        } else return -1;
    }

    std::array<std::uint8_t, kMaxBits> bits{};
    std::array<std::size_t, kMaxN + 1> stack_node{}, next_child{};
    std::size_t bit_count = 0, depth = 1;
    bits[bit_count++] = 1;
    next_child[0] = 1;
    while (depth > 0) {
        const auto frame = depth - 1, node = stack_node[frame];
        auto child = next_child[frame];
        while (child < n && parent[child] != node) ++child;
        if (child < n) {
            next_child[frame] = child + 1;
            bits[bit_count++] = 1;
            stack_node[depth] = child;
            next_child[depth] = 1;
            ++depth;
        } else {
            bits[bit_count++] = 0;
            --depth;
        }
    }
    if (bit_count != bit_length) return -1;

    std::array<std::int64_t, kMaxBits + 1> excess{};
    std::uint64_t packed = 0;
    for (std::size_t position = 0; position < bit_length; ++position) {
        if (bits[position]) packed |= UINT64_C(1) << position;
        excess[position + 1] = excess[position] + (bits[position] ? 1 : -1);
    }
    for (std::size_t index = 0; index < q; ++index) {
        const auto offset = query_base + 3 * index;
        const auto opcode = input[offset], first = static_cast<std::size_t>(input[offset + 1]);
        if ((opcode == 3 && !bits[first]) || (opcode == 4 && bits[first]) ||
            (opcode == 5 && !bits[first])) return -1;
    }

    std::array<std::int64_t, kMaxOutputWords> words{};
    words[0] = n_value;
    words[1] = static_cast<std::int64_t>(bit_length);
    words[2] = static_cast<std::int64_t>(packed);
    words[3] = q_value;
    for (std::size_t index = 0; index < q; ++index) {
        const auto offset = query_base + 3 * index;
        const auto opcode = input[offset];
        const auto first = static_cast<std::size_t>(input[offset + 1]);
        const auto second = input[offset + 2];
        std::int64_t answer = -1;
        if (opcode == 0 || opcode == 1) {
            const auto target = excess[first] + second;
            if (opcode == 0) {
                answer = static_cast<std::int64_t>(bit_length + 1);
                for (std::size_t position = first + 1; position <= bit_length; ++position)
                    if (excess[position] == target) { answer = static_cast<std::int64_t>(position); break; }
            } else {
                answer = 0;
                for (std::size_t position = first; position > 0; --position)
                    if (excess[position - 1] == target) { answer = static_cast<std::int64_t>(position - 1); break; }
            }
        } else if (opcode == 2) {
            const auto right = static_cast<std::size_t>(second);
            auto best = first;
            for (std::size_t position = first + 1; position <= right; ++position)
                if (excess[position + 1] < excess[best + 1]) best = position;
            answer = static_cast<std::int64_t>(best);
        } else if (opcode == 3) {
            const auto target = excess[first + 1] - 1;
            for (std::size_t position = first + 2; position <= bit_length; ++position)
                if (excess[position] == target) { answer = static_cast<std::int64_t>(position - 1); break; }
        } else if (opcode == 4) {
            const auto target = excess[first + 1];
            for (std::size_t position = first + 1; position > 0; --position)
                if (excess[position - 1] == target) { answer = static_cast<std::int64_t>(position - 1); break; }
        } else if (first == 0) {
            answer = -1;
        } else {
            const auto target = excess[first + 1] - 2;
            for (std::size_t position = first + 1; position > 0; --position)
                if (excess[position - 1] == target) { answer = static_cast<std::int64_t>(position - 1); break; }
        }
        words[4 + index] = answer;
    }

    const std::size_t output_words = 4 + q, required = 8 * output_words;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < output_words; ++index)
        write_i64_le(output, 8 * index, words[index]);
    return static_cast<std::int64_t>(required);
}
