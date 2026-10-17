module trie_multiple_search;

const usz MAX_OPERATIONS = 64;
const usz MAX_WORD_LENGTH = 32;
const usz MAX_DISTINCT_WORDS = 32;
const usz MAX_NODE_INDEX = 1 + MAX_WORD_LENGTH * MAX_DISTINCT_WORDS;
const usz NODE_ARRAY_LENGTH = MAX_NODE_INDEX + 1;
const usz MAX_VALID_INPUT_LENGTH = 1 + MAX_OPERATIONS * (2 + MAX_WORD_LENGTH);
const usz MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1;
const uint16 ROOT_INDEX = 1;
const ulong FNV_OFFSET = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;

struct TrieNode { uint16[26] children; uint32 frequency; bool terminal; }
struct Suggestion { uint32 frequency; uint8 length; uint8[32] word; }

fn int letter_index(long code, uint8* lowercase) {
    if (code >= 65 && code <= 90) {
        *lowercase = (uint8)(code + 32);
        return (int)(code - 65);
    }
    if (code >= 97 && code <= 122) {
        *lowercase = (uint8)code;
        return (int)(code - 97);
    }
    return -1;
}

fn void hash_byte(ulong* hash, uint8 byte) { *hash = (*hash ^ (ulong)byte) * FNV_PRIME; }
fn void hash_u16(ulong* hash, uint16 value) {
    for (uint byte = 0; byte < 2; ++byte) hash_byte(hash, (uint8)(value >> (byte * 8)));
}
fn void hash_u32(ulong* hash, uint32 value) {
    for (uint byte = 0; byte < 4; ++byte) hash_byte(hash, (uint8)(value >> (byte * 8)));
}
fn void hash_string(ulong* hash, uint8* word, usz length) {
    hash_byte(hash, (uint8)length);
    for (usz index = 0; index < length; ++index) hash_byte(hash, word[index]);
}

fn usz count_descendants(TrieNode* nodes, uint16 node) {
    usz count = 0;
    for (usz letter = 0; letter < 26; ++letter) {
        uint16 child = nodes[node].children[letter];
        if (child != 0) {
            if (nodes[child].terminal) ++count;
            count += count_descendants(nodes, child);
        }
    }
    return count;
}

fn void hash_descendants(TrieNode* nodes, uint16 node, uint8* path, usz path_length, ulong* hash) {
    for (usz letter = 0; letter < 26; ++letter) {
        uint16 child = nodes[node].children[letter];
        if (child != 0) {
            path[path_length] = (uint8)('a' + letter);
            if (nodes[child].terminal) hash_string(hash, path, path_length + 1);
            hash_descendants(nodes, child, path, path_length + 1, hash);
        }
    }
}

fn int compare_suggestions(Suggestion* left, Suggestion* right) {
    if (left.frequency > right.frequency) return 1;
    if (left.frequency < right.frequency) return -1;
    usz common = left.length < right.length ? left.length : right.length;
    for (usz index = 0; index < common; ++index) {
        if (left.word[index] > right.word[index]) return 1;
        if (left.word[index] < right.word[index]) return -1;
    }
    if (left.length > right.length) return 1;
    if (left.length < right.length) return -1;
    return 0;
}

fn void offer_suggestion(Suggestion* top, usz* count, uint32 frequency, uint8* word, usz length) {
    Suggestion candidate;
    candidate.frequency = frequency;
    candidate.length = (uint8)length;
    for (usz index = 0; index < length; ++index) candidate.word[index] = word[index];
    usz position = 0;
    while (position < *count && compare_suggestions(&candidate, &top[position]) <= 0) ++position;
    if (position >= 3) return;
    if (*count < 3) ++*count;
    for (usz index = *count - 1; index > position; --index) top[index] = top[index - 1];
    top[position] = candidate;
}

fn void collect_top_descendants(TrieNode* nodes, uint16 node, uint8* path, usz path_length,
                                Suggestion* top, usz* count) {
    for (usz letter = 0; letter < 26; ++letter) {
        uint16 child = nodes[node].children[letter];
        if (child != 0) {
            path[path_length] = (uint8)('a' + letter);
            usz word_length = path_length + 1;
            if (nodes[child].terminal)
                offer_suggestion(top, count, nodes[child].frequency, path, word_length);
            collect_top_descendants(nodes, child, path, word_length, top, count);
        }
    }
}

fn void hash_final_words(TrieNode* nodes, uint16 node, uint8* path, usz path_length, ulong* hash) {
    for (usz letter = 0; letter < 26; ++letter) {
        uint16 child = nodes[node].children[letter];
        if (child != 0) {
            path[path_length] = (uint8)('a' + letter);
            usz word_length = path_length + 1;
            if (nodes[child].terminal) {
                hash_string(hash, path, word_length);
                hash_u32(hash, nodes[child].frequency);
            }
            hash_final_words(nodes, child, path, word_length, hash);
        }
    }
}

fn long trie_multiple_search(long* input, usz length) @export("trie_multiple_search") {
    if (input == null || length < (usz)1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)input[0];

    TrieNode[NODE_ARRAY_LENGTH] nodes;
    for (usz i = 0; i < NODE_ARRAY_LENGTH; ++i) {
        nodes[i].frequency = 0;
        nodes[i].terminal = false;
        for (usz letter = 0; letter < 26; ++letter) nodes[i].children[letter] = 0;
    }
    uint16 next_node = ROOT_INDEX + 1;
    usz word_count = 0, offset = 1;
    ulong hash = FNV_OFFSET;
    hash_u16(&hash, (uint16)operation_count);

    for (usz operation = 0; operation < operation_count; ++operation) {
        if (offset + 2 > length) return -1;
        long opcode_value = input[offset], word_length_value = input[offset + 1];
        offset += 2;
        if (opcode_value < 0 || opcode_value > 3 || word_length_value < 0 ||
            word_length_value > (long)MAX_WORD_LENGTH) return -1;
        uint8 opcode = (uint8)opcode_value;
        usz word_length = (usz)word_length_value;
        if (opcode == 0 && word_length == 0) return -1;
        if (offset + word_length > length) return -1;
        uint8[MAX_WORD_LENGTH] raw_word, folded_word;
        for (usz index = 0; index < word_length; ++index) {
            long code = input[offset + index];
            if (letter_index(code, &folded_word[index]) < 0) return -1;
            raw_word[index] = (uint8)code;
        }
        offset += word_length;
        hash_byte(&hash, opcode);

        uint16 node = ROOT_INDEX;
        usz matched_length = 0;
        while (matched_length < word_length) {
            usz letter = (usz)(folded_word[matched_length] - 'a');
            uint16 child = nodes[node].children[letter];
            if (child == 0) break;
            node = child;
            ++matched_length;
        }
        bool full_path = matched_length == word_length;
        bool exact_match = full_path && nodes[node].terminal;

        if (opcode == 0) {
            if (!exact_match) {
                if (word_count >= MAX_DISTINCT_WORDS) return -1;
                while (matched_length < word_length) {
                    usz letter = (usz)(folded_word[matched_length] - 'a');
                    if ((usz)next_node > MAX_NODE_INDEX) return -1;
                    uint16 child = next_node++;
                    nodes[node].children[letter] = child;
                    node = child;
                    ++matched_length;
                }
                nodes[node].terminal = true;
                ++word_count;
            }
        } else if (opcode == 1) {
            uint8 present = exact_match ? 1 : 0;
            if (exact_match) ++nodes[node].frequency;
            hash_byte(&hash, present);
        } else {
            if (exact_match) ++nodes[node].frequency;
            usz descendant_count = 0;
            Suggestion[3] top;
            usz top_count = 0;
            uint8[MAX_WORD_LENGTH] path;
            for (usz index = 0; index < matched_length; ++index) path[index] = folded_word[index];
            if (opcode == 2) descendant_count = count_descendants(&nodes[0], node);
            else {
                collect_top_descendants(&nodes[0], node, &path[0], matched_length, &top[0], &top_count);
                descendant_count = top_count;
            }
            hash_u16(&hash, (uint16)(descendant_count + (exact_match ? 1 : 0)));
            if (exact_match) hash_string(&hash, &raw_word[0], word_length);
            if (opcode == 2) hash_descendants(&nodes[0], node, &path[0], matched_length, &hash);
            else for (usz index = 0; index < top_count; ++index)
                hash_string(&hash, &top[index].word[0], top[index].length);
        }
    }

    if (offset != length) return -1;
    hash_u16(&hash, (uint16)word_count);
    uint8[MAX_WORD_LENGTH] path;
    hash_final_words(&nodes[0], ROOT_INDEX, &path[0], 0, &hash);
    return (long)(hash & 0x7fffffffffffffff);
}
