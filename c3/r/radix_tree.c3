module radix_tree;

const long MAX_OPERATIONS = 256;
const long MAX_WORD_LENGTH = 32;
const usz NODE_CAPACITY = 513;
const usz MAX_VALID_INPUT_LENGTH = 8705;
const usz MAX_PARSEABLE_INPUT_LENGTH = 8706;
const usz MAX_PREFIX_LENGTH = 8192;

struct RadixNode {
    u8[32] prefix;
    u16 prefix_length;
    bool is_leaf;
    u16[26] children;
}

fn u8 radix_tree_prefix_byte(RadixNode* nodes, u8* root_prefix, usz node, usz index) {
    if (node == 0) return root_prefix[index];
    return nodes[node].prefix[index];
}

fn void radix_tree_prefix_set(RadixNode* nodes, u8* root_prefix,
                              usz node, usz index, u8 value) {
    if (node == 0) root_prefix[index] = value;
    else nodes[node].prefix[index] = value;
}

fn usz radix_tree_child_count(RadixNode* nodes, usz node, usz* only_child) {
    usz count = 0;
    for (usz letter = 0; letter < 26; ++letter) {
        if (nodes[node].children[letter] != 0) {
            *only_child = (usz)nodes[node].children[letter] - 1;
            count += 1;
        }
    }
    return count;
}

fn bool radix_tree_merge(RadixNode* nodes, u8* root_prefix, usz destination, usz source) {
    usz destination_length = nodes[destination].prefix_length;
    usz source_length = nodes[source].prefix_length;
    usz combined_length = destination_length + source_length;
    usz limit = destination == 0 ? MAX_PREFIX_LENGTH : 32;
    if (combined_length > limit) return false;
    for (usz index = 0; index < source_length; ++index) {
        u8 byte = radix_tree_prefix_byte(nodes, root_prefix, source, index);
        radix_tree_prefix_set(nodes, root_prefix, destination, destination_length + index, byte);
    }
    nodes[destination].prefix_length = (u16)combined_length;
    nodes[destination].is_leaf = nodes[source].is_leaf;
    for (usz letter = 0; letter < 26; ++letter)
        nodes[destination].children[letter] = nodes[source].children[letter];
    return true;
}

fn bool radix_tree_insert(RadixNode* nodes, u8* root_prefix, usz* next_node,
                          usz node_index, u8* word, usz start, usz length) {
    usz remaining_length = length - start;
    if (remaining_length == 0) {
        nodes[node_index].is_leaf = true;
        return true;
    }
    if ((usz)nodes[node_index].prefix_length == remaining_length && !nodes[node_index].is_leaf) {
        usz index = 0;
        while (index < remaining_length &&
               radix_tree_prefix_byte(nodes, root_prefix, node_index, index) == word[start + index])
            index += 1;
        if (index == remaining_length) {
            nodes[node_index].is_leaf = true;
            return true;
        }
    }

    usz letter = (usz)(word[start] - 97);
    u16 child_plus_one = nodes[node_index].children[letter];
    if (child_plus_one == 0) {
        if (*next_node >= NODE_CAPACITY) return false;
        usz child = *next_node;
        *next_node += 1;
        for (usz index = 0; index < remaining_length; ++index)
            radix_tree_prefix_set(nodes, root_prefix, child, index, word[start + index]);
        nodes[child].prefix_length = (u16)remaining_length;
        nodes[child].is_leaf = true;
        nodes[node_index].children[letter] = (u16)(child + 1);
        return true;
    }

    usz child = (usz)child_plus_one - 1;
    usz matched = 0;
    while (matched < (usz)nodes[child].prefix_length && matched < remaining_length &&
           radix_tree_prefix_byte(nodes, root_prefix, child, matched) == word[start + matched])
        matched += 1;
    usz remaining_prefix_length = (usz)nodes[child].prefix_length - matched;
    if (remaining_prefix_length == 0)
        return radix_tree_insert(nodes, root_prefix, next_node, child, word, start + matched, length);
    if (*next_node >= NODE_CAPACITY) return false;

    for (usz index = 0; index < remaining_prefix_length; ++index) {
        u8 byte = radix_tree_prefix_byte(nodes, root_prefix, child, matched + index);
        radix_tree_prefix_set(nodes, root_prefix, child, index, byte);
    }
    nodes[child].prefix_length = (u16)remaining_prefix_length;
    usz middle = *next_node;
    *next_node += 1;
    for (usz index = 0; index < matched; ++index)
        radix_tree_prefix_set(nodes, root_prefix, middle, index, word[start + index]);
    nodes[middle].prefix_length = (u16)matched;
    usz suffix_letter = (usz)(radix_tree_prefix_byte(nodes, root_prefix, child, 0) - 97);
    nodes[middle].children[suffix_letter] = (u16)(child + 1);
    nodes[node_index].children[letter] = (u16)(middle + 1);

    if (start + matched == length) {
        nodes[middle].is_leaf = true;
        return true;
    }
    return radix_tree_insert(nodes, root_prefix, next_node, middle, word, start + matched, length);
}

fn bool radix_tree_find(RadixNode* nodes, u8* root_prefix, usz node_index,
                        u8* word, usz start, usz length) {
    if (start >= length) return nodes[node_index].is_leaf;
    usz letter = (usz)(word[start] - 97);
    u16 child_plus_one = nodes[node_index].children[letter];
    if (child_plus_one == 0) return false;
    usz child = (usz)child_plus_one - 1;
    usz matched = 0;
    while (matched < (usz)nodes[child].prefix_length && start + matched < length &&
           radix_tree_prefix_byte(nodes, root_prefix, child, matched) == word[start + matched])
        matched += 1;
    if (matched != (usz)nodes[child].prefix_length) return false;
    usz next_start = start + matched;
    if (next_start == length) return nodes[child].is_leaf;
    return radix_tree_find(nodes, root_prefix, child, word, next_start, length);
}

fn int radix_tree_delete(RadixNode* nodes, u8* root_prefix, usz node_index,
                         u8* word, usz start, usz length) {
    if (start >= length) return 0;
    usz letter = (usz)(word[start] - 97);
    u16 child_plus_one = nodes[node_index].children[letter];
    if (child_plus_one == 0) return 0;
    usz child = (usz)child_plus_one - 1;
    usz matched = 0;
    while (matched < (usz)nodes[child].prefix_length && start + matched < length &&
           radix_tree_prefix_byte(nodes, root_prefix, child, matched) == word[start + matched])
        matched += 1;
    if (matched != (usz)nodes[child].prefix_length) return 0;
    usz next_start = start + matched;
    if (next_start < length)
        return radix_tree_delete(nodes, root_prefix, child, word, next_start, length);
    if (!nodes[child].is_leaf) return 0;

    usz only_child = 0;
    usz children = radix_tree_child_count(nodes, child, &only_child);
    if (children == 0) {
        nodes[node_index].children[letter] = 0;
        usz survivor = 0;
        if (!nodes[node_index].is_leaf && radix_tree_child_count(nodes, node_index, &survivor) == 1)
            return radix_tree_merge(nodes, root_prefix, node_index, survivor) ? 1 : -1;
    } else if (children > 1) {
        nodes[child].is_leaf = false;
    } else {
        return radix_tree_merge(nodes, root_prefix, child, only_child) ? 1 : -1;
    }
    return 1;
}

fn long radix_tree_benchmark(long* input, usz length) @export("radix_tree_benchmark") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS) return -1;
    usz operation_count = (usz)input[0];
    RadixNode nodes[NODE_CAPACITY] = {0};
    u8 root_prefix[MAX_PREFIX_LENGTH] = {0};
    usz next_node = 1;
    usz offset = 1;
    long checksum = 0;

    for (usz operation = 0; operation < operation_count; ++operation) {
        if (offset + 2 > length) return -1;
        long opcode = input[offset];
        long word_length_value = input[offset + 1];
        offset += 2;
        if (opcode < 0 || opcode > 2 || word_length_value < 1 || word_length_value > MAX_WORD_LENGTH) return -1;
        usz word_length = (usz)word_length_value;
        if (word_length > length - offset) return -1;
        u8 word[32] = {0};
        for (usz index = 0; index < word_length; ++index) {
            long byte = input[offset + index];
            if (byte < 97 || byte > 122) return -1;
            word[index] = (u8)byte;
        }
        offset += word_length;
        if (opcode == 0) {
            if (!radix_tree_insert(nodes, root_prefix, &next_node, 0, word, 0, word_length)) return -1;
        } else {
            long observed = opcode == 1
                ? (radix_tree_find(nodes, root_prefix, 0, word, 0, word_length) ? 1 : 0)
                : radix_tree_delete(nodes, root_prefix, 0, word, 0, word_length);
            if (observed < 0) return -1;
            checksum += (long)(operation + 1) * (1 + observed);
        }
    }
    if (offset != length) return -1;
    return checksum;
}
