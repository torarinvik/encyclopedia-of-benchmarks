#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_operations = 256;
constexpr std::size_t max_word_length = 32;
constexpr std::size_t max_prefix_length = max_operations * max_word_length;
constexpr std::size_t node_capacity = 1 + 2 * max_operations;
constexpr std::size_t max_valid_input_length = 1 + max_operations * (2 + max_word_length);
constexpr std::size_t max_parseable_input_length = max_valid_input_length + 1;

struct RadixNode {
    std::array<std::uint8_t, max_word_length> prefix{};
    std::uint16_t prefix_length = 0;
    bool is_leaf = false;
    std::array<std::uint16_t, 26> children{};
};

std::uint8_t prefix_byte(const RadixNode *nodes, const std::uint8_t *root_prefix,
                        std::size_t node, std::size_t index)
{
    return node == 0 ? root_prefix[index] : nodes[node].prefix[index];
}

void prefix_set(RadixNode *nodes, std::uint8_t *root_prefix,
                std::size_t node, std::size_t index, std::uint8_t value)
{
    if (node == 0) root_prefix[index] = value;
    else nodes[node].prefix[index] = value;
}

std::size_t child_count(const RadixNode *nodes, std::size_t node, std::size_t &only_child)
{
    std::size_t count = 0;
    for (std::size_t letter = 0; letter < 26; ++letter) {
        if (nodes[node].children[letter] != 0) {
            only_child = static_cast<std::size_t>(nodes[node].children[letter]) - 1;
            ++count;
        }
    }
    return count;
}

bool merge_node(RadixNode *nodes, std::uint8_t *root_prefix,
                std::size_t destination, std::size_t source)
{
    const std::size_t destination_length = nodes[destination].prefix_length;
    const std::size_t source_length = nodes[source].prefix_length;
    const std::size_t combined_length = destination_length + source_length;
    if (combined_length > (destination == 0 ? max_prefix_length : max_word_length)) return false;
    for (std::size_t index = 0; index < source_length; ++index)
        prefix_set(nodes, root_prefix, destination, destination_length + index,
                   prefix_byte(nodes, root_prefix, source, index));
    nodes[destination].prefix_length = static_cast<std::uint16_t>(combined_length);
    nodes[destination].is_leaf = nodes[source].is_leaf;
    nodes[destination].children = nodes[source].children;
    return true;
}

bool insert(RadixNode *nodes, std::uint8_t *root_prefix, std::size_t &next_node, std::size_t node_index,
            const std::array<std::uint8_t, max_word_length> &word, std::size_t start,
            std::size_t length)
{
    const std::size_t remaining_length = length - start;
    if (remaining_length == 0) {
        nodes[node_index].is_leaf = true;
        return true;
    }
    if (nodes[node_index].prefix_length == remaining_length && !nodes[node_index].is_leaf) {
        std::size_t index = 0;
        while (index < remaining_length && prefix_byte(nodes, root_prefix, node_index, index) == word[start + index]) ++index;
        if (index == remaining_length) {
            nodes[node_index].is_leaf = true;
            return true;
        }
    }

    const std::size_t letter = static_cast<std::size_t>(word[start] - static_cast<std::uint8_t>('a'));
    const std::uint16_t child_plus_one = nodes[node_index].children[letter];
    if (child_plus_one == 0) {
        if (next_node >= node_capacity) return false;
        const std::size_t child = next_node++;
        for (std::size_t index = 0; index < remaining_length; ++index)
            prefix_set(nodes, root_prefix, child, index, word[start + index]);
        nodes[child].prefix_length = static_cast<std::uint16_t>(remaining_length);
        nodes[child].is_leaf = true;
        nodes[node_index].children[letter] = static_cast<std::uint16_t>(child + 1);
        return true;
    }

    const std::size_t child = static_cast<std::size_t>(child_plus_one) - 1;
    std::size_t matched = 0;
    while (matched < nodes[child].prefix_length && matched < remaining_length &&
           prefix_byte(nodes, root_prefix, child, matched) == word[start + matched]) ++matched;
    const std::size_t remaining_prefix_length = nodes[child].prefix_length - matched;
    if (remaining_prefix_length == 0)
        return insert(nodes, root_prefix, next_node, child, word, start + matched, length);
    if (next_node >= node_capacity) return false;

    for (std::size_t index = 0; index < remaining_prefix_length; ++index)
        prefix_set(nodes, root_prefix, child, index, prefix_byte(nodes, root_prefix, child, matched + index));
    nodes[child].prefix_length = static_cast<std::uint16_t>(remaining_prefix_length);

    const std::size_t middle = next_node++;
    for (std::size_t index = 0; index < matched; ++index)
        prefix_set(nodes, root_prefix, middle, index, word[start + index]);
    nodes[middle].prefix_length = static_cast<std::uint16_t>(matched);
    const std::size_t suffix_letter = static_cast<std::size_t>(prefix_byte(nodes, root_prefix, child, 0) - static_cast<std::uint8_t>('a'));
    nodes[middle].children[suffix_letter] = static_cast<std::uint16_t>(child + 1);
    nodes[node_index].children[letter] = static_cast<std::uint16_t>(middle + 1);

    if (start + matched == length) {
        nodes[middle].is_leaf = true;
        return true;
    }
    return insert(nodes, root_prefix, next_node, middle, word, start + matched, length);
}

bool find(const RadixNode *nodes, const std::uint8_t *root_prefix, std::size_t node_index,
          const std::array<std::uint8_t, max_word_length> &word,
          std::size_t start, std::size_t length)
{
    if (start >= length) return nodes[node_index].is_leaf;
    const std::size_t letter = static_cast<std::size_t>(word[start] - static_cast<std::uint8_t>('a'));
    const std::uint16_t child_plus_one = nodes[node_index].children[letter];
    if (child_plus_one == 0) return false;
    const std::size_t child = static_cast<std::size_t>(child_plus_one) - 1;
    std::size_t matched = 0;
    while (matched < nodes[child].prefix_length && start + matched < length &&
           prefix_byte(nodes, root_prefix, child, matched) == word[start + matched]) ++matched;
    if (matched != nodes[child].prefix_length) return false;
    const std::size_t next_start = start + matched;
    if (next_start == length) return nodes[child].is_leaf;
    return find(nodes, root_prefix, child, word, next_start, length);
}

int remove(RadixNode *nodes, std::uint8_t *root_prefix, std::size_t node_index,
           const std::array<std::uint8_t, max_word_length> &word,
           std::size_t start, std::size_t length)
{
    if (start >= length) return 0;
    const std::size_t letter = static_cast<std::size_t>(word[start] - static_cast<std::uint8_t>('a'));
    const std::uint16_t child_plus_one = nodes[node_index].children[letter];
    if (child_plus_one == 0) return 0;
    const std::size_t child = static_cast<std::size_t>(child_plus_one) - 1;
    std::size_t matched = 0;
    while (matched < nodes[child].prefix_length && start + matched < length &&
           prefix_byte(nodes, root_prefix, child, matched) == word[start + matched]) ++matched;
    if (matched != nodes[child].prefix_length) return 0;
    const std::size_t next_start = start + matched;
    if (next_start < length) return remove(nodes, root_prefix, child, word, next_start, length);
    if (!nodes[child].is_leaf) return 0;

    std::size_t only_child = 0;
    const std::size_t children = child_count(nodes, child, only_child);
    if (children == 0) {
        nodes[node_index].children[letter] = 0;
        std::size_t survivor = 0;
        if (!nodes[node_index].is_leaf && child_count(nodes, node_index, survivor) == 1)
            return merge_node(nodes, root_prefix, node_index, survivor) ? 1 : -1;
    } else if (children > 1) {
        nodes[child].is_leaf = false;
    } else {
        return merge_node(nodes, root_prefix, child, only_child) ? 1 : -1;
    }
    return 1;
}
}

extern "C" std::int64_t radix_tree_benchmark(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 1 || length > max_parseable_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_operations)) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(input[0]);
    std::array<RadixNode, node_capacity> nodes{};
    std::array<std::uint8_t, max_prefix_length> root_prefix{};
    std::size_t next_node = 1;
    std::size_t offset = 1;
    std::int64_t checksum = 0;

    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        if (offset + 2 > length) return -1;
        const std::int64_t opcode = input[offset];
        const std::int64_t word_length_value = input[offset + 1];
        offset += 2;
        if (opcode < 0 || opcode > 2 || word_length_value < 1 || word_length_value > static_cast<std::int64_t>(max_word_length)) return -1;
        const std::size_t word_length = static_cast<std::size_t>(word_length_value);
        if (word_length > length - offset) return -1;
        std::array<std::uint8_t, max_word_length> word{};
        for (std::size_t index = 0; index < word_length; ++index) {
            const std::int64_t byte = input[offset + index];
            if (byte < 'a' || byte > 'z') return -1;
            word[index] = static_cast<std::uint8_t>(byte);
        }
        offset += word_length;

        if (opcode == 0) {
            if (!insert(nodes.data(), root_prefix.data(), next_node, 0, word, 0, word_length)) return -1;
        } else {
            const int observed = opcode == 1
                ? static_cast<int>(find(nodes.data(), root_prefix.data(), 0, word, 0, word_length))
                : remove(nodes.data(), root_prefix.data(), 0, word, 0, word_length);
            if (observed < 0) return -1;
            checksum += static_cast<std::int64_t>(operation + 1) * (1 + observed);
        }
    }
    if (offset != length) return -1;
    return checksum;
}
