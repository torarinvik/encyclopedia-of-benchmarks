#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 24, max_pattern = 32, max_positions = 8;
constexpr std::size_t max_states = max_positions + 1, max_nodes = 64;
enum : std::uint8_t { position_node = 1, concat_node = 2, alt_node = 3, star_node = 4 };
struct Node { std::uint8_t kind{}, left{}, right{}, position{}; };
struct Parser {
    const std::int64_t* pattern{};
    std::size_t length{}, cursor{}, node_count{}, position_count{};
    std::array<Node, max_nodes> nodes{};
    std::array<std::uint8_t, max_states> symbols{};
    bool failed{};

    std::uint8_t add(std::uint8_t kind, std::uint8_t left = 0,
                     std::uint8_t right = 0, std::uint8_t position = 0) {
        if (node_count >= max_nodes) { failed = true; return 0; }
        const auto result = static_cast<std::uint8_t>(node_count++);
        nodes[result] = Node{kind, left, right, position};
        return result;
    }
    std::uint8_t expression() {
        auto result = concatenation();
        while (!failed && cursor < length && pattern[cursor] == '|') {
            ++cursor;
            const auto right = concatenation();
            result = add(alt_node, result, right);
        }
        return result;
    }
    std::uint8_t concatenation() {
        if (cursor >= length || pattern[cursor] == '|' || pattern[cursor] == ')') {
            failed = true; return 0;
        }
        auto result = repetition();
        while (!failed && cursor < length && pattern[cursor] != '|' && pattern[cursor] != ')')
            result = add(concat_node, result, repetition());
        return result;
    }
    std::uint8_t repetition() {
        auto result = atom();
        if (!failed && cursor < length && pattern[cursor] == '*') {
            ++cursor;
            result = add(star_node, result);
        }
        return result;
    }
    std::uint8_t atom() {
        if (cursor >= length) { failed = true; return 0; }
        const auto token = pattern[cursor++];
        if (token == '(') {
            const auto result = expression();
            if (failed || cursor >= length || pattern[cursor] != ')') { failed = true; return 0; }
            ++cursor;
            return result;
        }
        if (token != 'a' && token != 'b' && token != 'c' && token != '.') { failed = true; return 0; }
        if (position_count >= max_positions) { failed = true; return 0; }
        const auto position = static_cast<std::uint8_t>(++position_count);
        symbols[position] = static_cast<std::uint8_t>(token);
        return add(position_node, 0, 0, position);
    }
};
}

extern "C" std::int64_t glushkov_bit_parallel_regex_search(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > 58) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_text) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_pattern)) return -1;
    const auto text_length = static_cast<std::size_t>(input[0]);
    const auto pattern_length = static_cast<std::size_t>(input[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (std::size_t i = 0; i < text_length + pattern_length; ++i)
        if (input[2 + i] < 1 || input[2 + i] > 127) return -1;

    Parser parser{};
    parser.pattern = input + 2 + text_length;
    parser.length = pattern_length;
    const auto root = parser.expression();
    if (parser.failed || parser.cursor != pattern_length || parser.node_count == 0) return -1;

    std::array<bool, max_nodes> nullable{};
    std::array<std::uint16_t, max_nodes> first{}, last{};
    std::array<std::uint16_t, max_states> follow{};
    for (std::size_t i = 0; i < parser.node_count; ++i) {
        const auto node = parser.nodes[i];
        if (node.kind == position_node) {
            const auto bit = static_cast<std::uint16_t>(1u << node.position);
            first[i] = last[i] = bit;
        } else if (node.kind == star_node) {
            nullable[i] = true;
            first[i] = first[node.left]; last[i] = last[node.left];
            for (std::size_t p = 1; p <= parser.position_count; ++p)
                if (last[node.left] & (1u << p)) follow[p] |= first[node.left];
        } else {
            const auto a = node.left, b = node.right;
            if (node.kind == alt_node) {
                nullable[i] = nullable[a] || nullable[b];
                first[i] = first[a] | first[b];
                last[i] = last[a] | last[b];
            } else {
                nullable[i] = nullable[a] && nullable[b];
                first[i] = first[a] | (nullable[a] ? first[b] : 0);
                last[i] = last[b] | (nullable[b] ? last[a] : 0);
                for (std::size_t p = 1; p <= parser.position_count; ++p)
                    if (last[a] & (1u << p)) follow[p] |= first[b];
            }
        }
    }
    follow[0] = first[root] | 1u;
    std::array<std::uint16_t, 1u << max_states> transitions{};
    const std::size_t subsets = std::size_t{1} << (parser.position_count + 1);
    for (std::size_t subset = 1; subset < subsets; ++subset) {
        std::size_t state = 0;
        while (((subset >> state) & 1u) == 0) ++state;
        transitions[subset] = transitions[subset & (subset - 1)] | follow[state];
    }
    std::array<std::uint16_t, 128> byte_masks{};
    byte_masks.fill(1);
    for (std::size_t p = 1; p <= parser.position_count; ++p)
        for (std::size_t byte = 1; byte < byte_masks.size(); ++byte)
            if (parser.symbols[p] == '.' || parser.symbols[p] == byte) byte_masks[byte] |= 1u << p;

    std::array<std::uint8_t, max_text> staged{};
    std::uint16_t state = 1;
    for (std::size_t i = 0; i < text_length; ++i) {
        state = transitions[state] & byte_masks[static_cast<std::size_t>(input[2 + i])];
        staged[i] = (state & last[root]) != 0 ? 1 : 0;
    }
    if (text_length != 0 && (output == nullptr || capacity < text_length)) return -2;
    for (std::size_t i = 0; i < text_length; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(text_length);
}
