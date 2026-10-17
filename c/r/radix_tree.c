#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 256u
#define MAX_WORD_LENGTH 32u
#define MAX_PREFIX_LENGTH (MAX_OPERATIONS * MAX_WORD_LENGTH)
#define NODE_CAPACITY (1u + 2u * MAX_OPERATIONS)
#define MAX_VALID_INPUT_LENGTH (1u + MAX_OPERATIONS * (2u + MAX_WORD_LENGTH))
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_VALID_INPUT_LENGTH + 1u)

typedef struct {
    uint8_t prefix[MAX_WORD_LENGTH];
    uint16_t prefix_length;
    uint8_t is_leaf;
    uint16_t children[26];
} RadixNode;

static uint8_t radix_prefix_byte(const RadixNode *nodes, const uint8_t *root_prefix,
                                 size_t node, size_t index)
{
    return node == 0u ? root_prefix[index] : nodes[node].prefix[index];
}

static void radix_prefix_set(RadixNode *nodes, uint8_t *root_prefix,
                             size_t node, size_t index, uint8_t value)
{
    if (node == 0u) root_prefix[index] = value;
    else nodes[node].prefix[index] = value;
}

static size_t radix_child_count(const RadixNode *node, size_t *only_child)
{
    size_t count = 0;
    for (size_t letter = 0; letter < 26u; ++letter) {
        if (node->children[letter] != 0u) {
            *only_child = (size_t)node->children[letter] - 1u;
            ++count;
        }
    }
    return count;
}

static int radix_merge(RadixNode *nodes, uint8_t *root_prefix, size_t destination, size_t source)
{
    const size_t destination_length = nodes[destination].prefix_length;
    const size_t source_length = nodes[source].prefix_length;
    const size_t combined_length = destination_length + source_length;
    if (combined_length > (destination == 0u ? MAX_PREFIX_LENGTH : MAX_WORD_LENGTH)) return 0;
    for (size_t index = 0; index < source_length; ++index)
        radix_prefix_set(nodes, root_prefix, destination, destination_length + index,
                         radix_prefix_byte(nodes, root_prefix, source, index));
    nodes[destination].prefix_length = (uint16_t)combined_length;
    nodes[destination].is_leaf = nodes[source].is_leaf;
    for (size_t letter = 0; letter < 26u; ++letter)
        nodes[destination].children[letter] = nodes[source].children[letter];
    return 1;
}

static int radix_insert(RadixNode *nodes, uint8_t *root_prefix, size_t *next_node, size_t node_index,
                        const uint8_t *word, size_t start, size_t length)
{
    const size_t remaining_length = length - start;
    if (remaining_length == 0u) {
        nodes[node_index].is_leaf = 1u;
        return 1;
    }
    if (nodes[node_index].prefix_length == remaining_length && !nodes[node_index].is_leaf) {
        size_t index = 0;
        while (index < remaining_length && radix_prefix_byte(nodes, root_prefix, node_index, index) == word[start + index]) ++index;
        if (index == remaining_length) {
            nodes[node_index].is_leaf = 1u;
            return 1;
        }
    }

    const size_t letter = (size_t)(word[start] - (uint8_t)'a');
    const uint16_t child_plus_one = nodes[node_index].children[letter];
    if (child_plus_one == 0u) {
        if (*next_node >= NODE_CAPACITY) return 0;
        const size_t child = (*next_node)++;
        for (size_t index = 0; index < remaining_length; ++index)
            radix_prefix_set(nodes, root_prefix, child, index, word[start + index]);
        nodes[child].prefix_length = (uint16_t)remaining_length;
        nodes[child].is_leaf = 1u;
        nodes[node_index].children[letter] = (uint16_t)(child + 1u);
        return 1;
    }

    const size_t child = (size_t)child_plus_one - 1u;
    size_t matched = 0;
    while (matched < nodes[child].prefix_length && matched < remaining_length &&
           radix_prefix_byte(nodes, root_prefix, child, matched) == word[start + matched]) ++matched;
    const size_t remaining_prefix_length = (size_t)nodes[child].prefix_length - matched;
    if (remaining_prefix_length == 0u)
        return radix_insert(nodes, root_prefix, next_node, child, word, start + matched, length);
    if (*next_node >= NODE_CAPACITY) return 0;

    for (size_t index = 0; index < remaining_prefix_length; ++index)
        radix_prefix_set(nodes, root_prefix, child, index,
                         radix_prefix_byte(nodes, root_prefix, child, matched + index));
    nodes[child].prefix_length = (uint16_t)remaining_prefix_length;

    const size_t middle = (*next_node)++;
    for (size_t index = 0; index < matched; ++index)
        radix_prefix_set(nodes, root_prefix, middle, index, word[start + index]);
    nodes[middle].prefix_length = (uint16_t)matched;
    const size_t suffix_letter = (size_t)(radix_prefix_byte(nodes, root_prefix, child, 0) - (uint8_t)'a');
    nodes[middle].children[suffix_letter] = (uint16_t)(child + 1u);
    nodes[node_index].children[letter] = (uint16_t)(middle + 1u);

    if (start + matched == length) {
        nodes[middle].is_leaf = 1u;
        return 1;
    }
    return radix_insert(nodes, root_prefix, next_node, middle, word, start + matched, length);
}

static int radix_find(const RadixNode *nodes, const uint8_t *root_prefix, size_t node_index,
                      const uint8_t *word, size_t start, size_t length)
{
    if (start >= length) return nodes[node_index].is_leaf != 0u;
    const size_t letter = (size_t)(word[start] - (uint8_t)'a');
    const uint16_t child_plus_one = nodes[node_index].children[letter];
    if (child_plus_one == 0u) return 0;
    const size_t child = (size_t)child_plus_one - 1u;
    size_t matched = 0;
    while (matched < nodes[child].prefix_length && start + matched < length &&
           radix_prefix_byte(nodes, root_prefix, child, matched) == word[start + matched]) ++matched;
    if (matched != nodes[child].prefix_length) return 0;
    const size_t next_start = start + matched;
    if (next_start == length) return nodes[child].is_leaf != 0u;
    return radix_find(nodes, root_prefix, child, word, next_start, length);
}

static int radix_delete(RadixNode *nodes, uint8_t *root_prefix, size_t node_index,
                        const uint8_t *word, size_t start, size_t length)
{
    if (start >= length) return 0;
    const size_t letter = (size_t)(word[start] - (uint8_t)'a');
    const uint16_t child_plus_one = nodes[node_index].children[letter];
    if (child_plus_one == 0u) return 0;
    const size_t child = (size_t)child_plus_one - 1u;
    size_t matched = 0;
    while (matched < nodes[child].prefix_length && start + matched < length &&
           radix_prefix_byte(nodes, root_prefix, child, matched) == word[start + matched]) ++matched;
    if (matched != nodes[child].prefix_length) return 0;
    const size_t next_start = start + matched;
    if (next_start < length) return radix_delete(nodes, root_prefix, child, word, next_start, length);
    if (nodes[child].is_leaf == 0u) return 0;

    size_t only_child = 0;
    const size_t child_count = radix_child_count(&nodes[child], &only_child);
    if (child_count == 0u) {
        nodes[node_index].children[letter] = 0u;
        size_t survivor = 0;
        if (!nodes[node_index].is_leaf && radix_child_count(&nodes[node_index], &survivor) == 1u)
            return radix_merge(nodes, root_prefix, node_index, survivor) ? 1 : -1;
    } else if (child_count > 1u) {
        nodes[child].is_leaf = 0u;
    } else {
        return radix_merge(nodes, root_prefix, child, only_child) ? 1 : -1;
    }
    return 1;
}

int64_t radix_tree_benchmark(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1u || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (int64_t)MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)input[0];
    RadixNode nodes[NODE_CAPACITY] = {0};
    uint8_t root_prefix[MAX_PREFIX_LENGTH] = {0};
    size_t next_node = 1u;
    size_t offset = 1u;
    int64_t checksum = 0;

    for (size_t operation = 0; operation < operation_count; ++operation) {
        if (offset + 2u > length) return -1;
        const int64_t opcode_value = input[offset];
        const int64_t word_length_value = input[offset + 1u];
        offset += 2u;
        if (opcode_value < 0 || opcode_value > 2 || word_length_value < 1 ||
            word_length_value > (int64_t)MAX_WORD_LENGTH) return -1;
        const size_t word_length = (size_t)word_length_value;
        if (word_length > length - offset) return -1;
        uint8_t word[MAX_WORD_LENGTH];
        for (size_t index = 0; index < word_length; ++index) {
            const int64_t byte = input[offset + index];
            if (byte < 'a' || byte > 'z') return -1;
            word[index] = (uint8_t)byte;
        }
        offset += word_length;

        if (opcode_value == 0) {
            if (!radix_insert(nodes, root_prefix, &next_node, 0u, word, 0u, word_length)) return -1;
        } else {
            const int observed = opcode_value == 1
                ? radix_find(nodes, root_prefix, 0u, word, 0u, word_length)
                : radix_delete(nodes, root_prefix, 0u, word, 0u, word_length);
            if (observed < 0) return -1;
            checksum += (int64_t)(operation + 1u) * (1 + observed);
        }
    }
    if (offset != length) return -1;
    return checksum;
}
