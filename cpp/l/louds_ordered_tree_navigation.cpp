#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxNodes = 32;
constexpr std::size_t kMaxQueries = 32;
constexpr std::size_t kMaxInputWords = 130;
constexpr std::size_t kMaxOutputWords = 4 + kMaxQueries;

void store_i64_le(std::uint8_t* output, std::size_t offset,
                  std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t louds_ordered_tree_navigation(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInputWords) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(kMaxNodes) ||
        q_value < 0 || q_value > static_cast<std::int64_t>(kMaxQueries)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto q = static_cast<std::size_t>(q_value);
    if (length != 2 + (n - 1) + 3 * q) return -1;

    std::array<std::size_t, kMaxNodes> parent{};
    for (std::size_t vertex = 1; vertex < n; ++vertex) {
        const auto value = input[1 + vertex];
        if (value < 0 || static_cast<std::uint64_t>(value) >= vertex) return -1;
        parent[vertex] = static_cast<std::size_t>(value);
    }
    const std::size_t query_base = n + 1;
    for (std::size_t index = 0; index < q; ++index) {
        const auto offset = query_base + 3 * index;
        const auto opcode = input[offset], node = input[offset + 1], arg = input[offset + 2];
        if (node < 0 || node >= n_value) return -1;
        if (opcode == 0 || opcode == 1) {
            if (arg != 0) return -1;
        } else if (opcode == 2) {
            if (arg < 0 || static_cast<std::uint64_t>(arg) > n) return -1;
        } else return -1;
    }

    std::array<std::size_t, kMaxNodes> order{};
    std::size_t order_count = 1, cursor = 0;
    while (cursor < order_count) {
        const auto vertex = order[cursor++];
        for (std::size_t child = 1; child < n; ++child)
            if (parent[child] == vertex) order[order_count++] = child;
    }
    if (order_count != n) return -1;

    std::array<std::size_t, kMaxNodes> degree{};
    for (std::size_t node = 0; node < n; ++node)
        for (std::size_t child = 1; child < n; ++child)
            if (parent[child] == order[node]) ++degree[node];

    std::uint64_t packed = 0;
    std::size_t bit_length = 0;
    for (std::size_t node = 0; node < n; ++node) {
        for (std::size_t child = 0; child < degree[node]; ++child)
            packed |= UINT64_C(1) << bit_length++;
        ++bit_length;
    }

    std::array<std::size_t, kMaxNodes> decoded{};
    std::array<std::size_t, kMaxNodes + 1> rank_prefix{};
    std::size_t bit_position = 0, previous_zero = static_cast<std::size_t>(-1);
    for (std::size_t node = 0; node < n; ++node) {
        while (bit_position < bit_length && ((packed >> bit_position) & 1U) != 0)
            ++bit_position;
        decoded[node] = bit_position - previous_zero - 1;
        previous_zero = bit_position++;
        rank_prefix[node + 1] = rank_prefix[node] + decoded[node];
    }

    std::array<std::int64_t, kMaxOutputWords> words{};
    words[0] = n_value;
    words[1] = static_cast<std::int64_t>(bit_length);
    words[2] = static_cast<std::int64_t>(packed);
    words[3] = q_value;
    for (std::size_t index = 0; index < q; ++index) {
        const auto offset = query_base + 3 * index;
        const auto opcode = input[offset];
        const auto node = static_cast<std::size_t>(input[offset + 1]);
        const auto arg = input[offset + 2];
        std::int64_t answer = -1;
        if (opcode == 0) answer = static_cast<std::int64_t>(decoded[node]);
        else if (opcode == 1) {
            if (node != 0)
                for (std::size_t candidate = 0; candidate < n; ++candidate)
                    if (rank_prefix[candidate + 1] >= node) {
                        answer = static_cast<std::int64_t>(candidate);
                        break;
                    }
        } else if (static_cast<std::size_t>(arg) < decoded[node]) {
            answer = static_cast<std::int64_t>(1 + rank_prefix[node] +
                                                static_cast<std::size_t>(arg));
        }
        words[4 + index] = answer;
    }

    const std::size_t output_words = 4 + q;
    const std::size_t required = 8 * output_words;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < output_words; ++index)
        store_i64_le(output, 8 * index, words[index]);
    return static_cast<std::int64_t>(required);
}
