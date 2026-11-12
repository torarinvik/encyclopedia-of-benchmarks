#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_q = 128;
constexpr std::size_t tree_base = 128;
constexpr std::size_t tree_height = 7;
constexpr std::size_t max_nodes = 1 + max_q * (tree_height + 1);
constexpr std::size_t max_parseable_input = 1 + 3 * max_q + 1;
constexpr std::int64_t max_value = 1'000'000'000;

struct Node { std::size_t left = 0, right = 0; std::int64_t value = 0; };

std::size_t set_value(std::array<Node, max_nodes>& nodes, std::size_t& used,
                      std::size_t root, std::size_t low, std::size_t high,
                      std::size_t position, std::int64_t value) {
    const auto copy = used++;
    nodes[copy] = nodes[root];
    if (high - low == 1) {
        nodes[copy].value = value;
        return copy;
    }
    const auto middle = low + (high - low) / 2;
    if (position < middle)
        nodes[copy].left = set_value(nodes, used, nodes[root].left,
                                     low, middle, position, value);
    else
        nodes[copy].right = set_value(nodes, used, nodes[root].right,
                                      middle, high, position, value);
    return copy;
}

std::int64_t get_value(const std::array<Node, max_nodes>& nodes, std::size_t root,
                       std::size_t low, std::size_t high, std::size_t position) {
    if (high - low == 1) return nodes[root].value;
    const auto middle = low + (high - low) / 2;
    return position < middle
        ? get_value(nodes, nodes[root].left, low, middle, position)
        : get_value(nodes, nodes[root].right, middle, high, position);
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t persistent_queue(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_parseable_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_q)) return -1;
    const auto q = static_cast<std::size_t>(input[0]);
    std::array<std::int64_t, max_q> kind{}, parent{}, value{};
    std::array<std::size_t, max_q + 1> version_head{}, version_tail{}, version_size{};
    std::size_t cursor = 1, pop_count = 0;
    for (std::size_t operation = 0; operation < q; ++operation) {
        if (cursor + 2 > length) return -1;
        kind[operation] = input[cursor++];
        parent[operation] = input[cursor++];
        if ((kind[operation] != 0 && kind[operation] != 1) || parent[operation] < -1 ||
            parent[operation] >= static_cast<std::int64_t>(operation)) return -1;
        const auto base = static_cast<std::size_t>(parent[operation] + 1);
        if (kind[operation] == 0) {
            if (cursor >= length) return -1;
            value[operation] = input[cursor++];
            if (value[operation] < 0 || value[operation] > max_value || version_tail[base] >= tree_base)
                return -1;
            version_head[operation + 1] = version_head[base];
            version_tail[operation + 1] = version_tail[base] + 1;
            version_size[operation + 1] = version_size[base] + 1;
        } else {
            if (version_size[base] == 0) return -1;
            version_head[operation + 1] = version_head[base] + 1;
            version_tail[operation + 1] = version_tail[base];
            version_size[operation + 1] = version_size[base] - 1;
            ++pop_count;
        }
    }
    if (cursor != length) return -1;
    const auto output_bytes = 8 * pop_count;
    if (output_bytes != 0 && (output == nullptr || capacity < output_bytes)) return -2;

    std::array<Node, max_nodes> nodes{};
    std::array<std::size_t, max_q + 1> roots{};
    std::array<std::size_t, max_q> answers{};
    std::size_t answer_count = 0, used = 1;
    for (std::size_t operation = 0; operation < q; ++operation) {
        const auto base = static_cast<std::size_t>(parent[operation] + 1);
        const auto version = operation + 1;
        if (kind[operation] == 0) {
            roots[version] = set_value(nodes, used, roots[base], 0, tree_base,
                                       version_tail[base], value[operation]);
        } else {
            answers[answer_count++] = static_cast<std::size_t>(get_value(
                nodes, roots[base], 0, tree_base, version_head[base]));
            roots[version] = roots[base];
        }
    }
    for (std::size_t i = 0; i < answer_count; ++i)
        store_i64_le(output, 8 * i, static_cast<std::int64_t>(answers[i]));
    return static_cast<std::int64_t>(output_bytes);
}
