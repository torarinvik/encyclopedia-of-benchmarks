module mccat_trie;

const usz MAX_WORDS = 64;
const usz MAX_WORD_LENGTH = 32;
const usz MAX_INPUT_VALUES = 1 + MAX_WORDS * (1 + MAX_WORD_LENGTH);
const usz MAX_NODES = MAX_WORDS * MAX_WORD_LENGTH;
const usz MAX_OUTPUT_BYTES = MAX_WORDS * (MAX_WORD_LENGTH + 1);

struct Node { uchar value; bool terminal; usz postfix; usz other_char; }
struct Trie { Node[MAX_NODES + 1] nodes; usz used; }

fn usz new_node(Trie* trie, uchar value) {
    trie.used++;
    trie.nodes[trie.used].value = value;
    return trie.used;
}

fn usz new_suffix(Trie* trie, long* input, usz start, usz word_length) {
    usz root = new_node(trie, (uchar)input[start]);
    usz current = root;
    for (usz i = 1; i < word_length; i++) {
        usz child = new_node(trie, (uchar)input[start + i]);
        trie.nodes[current].postfix = child;
        current = child;
    }
    trie.nodes[current].terminal = true;
    return root;
}

fn void insert_word(Trie* trie, usz current, long* input, usz start,
                    usz word_length, usz offset) {
    if (trie.nodes[current].value == (uchar)input[start + offset]) {
        if (offset + 1 == word_length) trie.nodes[current].terminal = true;
        else if (trie.nodes[current].postfix == 0)
            trie.nodes[current].postfix = new_suffix(trie, input, start + offset + 1, word_length - offset - 1);
        else insert_word(trie, trie.nodes[current].postfix, input, start, word_length, offset + 1);
    } else if (trie.nodes[current].other_char == 0) {
        trie.nodes[current].other_char = new_suffix(trie, input, start + offset, word_length - offset);
    } else insert_word(trie, trie.nodes[current].other_char, input, start, word_length, offset);
}

fn void measure_output(Trie* trie, usz current, usz depth, usz* output_length) {
    if (current == 0) return;
    if (trie.nodes[current].terminal) *output_length += depth + 2;
    measure_output(trie, trie.nodes[current].postfix, depth + 1, output_length);
    measure_output(trie, trie.nodes[current].other_char, depth, output_length);
}

fn void emit_output(Trie* trie, usz current, usz depth, uchar* prefix,
                    uchar* output, usz* position) {
    if (current == 0) return;
    prefix[depth] = trie.nodes[current].value;
    if (trie.nodes[current].terminal) {
        for (usz i = 0; i <= depth; i++) {
            output[*position] = prefix[i];
            *position += 1;
        }
        output[*position] = 10;
        *position += 1;
    }
    emit_output(trie, trie.nodes[current].postfix, depth + 1, prefix, output, position);
    emit_output(trie, trie.nodes[current].other_char, depth, prefix, output, position);
}

fn long mccat_trie(long* input, usz length, uchar* output, usz capacity) @export("mccat_trie") {
    if (input == null || length < 1 || length > MAX_INPUT_VALUES) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_WORDS) return -1;
    usz word_count = (usz)input[0];
    usz[MAX_WORDS] starts = {};
    usz[MAX_WORDS] lengths = {};
    usz position = 1;
    for (usz i = 0; i < word_count; i++) {
        if (position >= length) return -1;
        long word_length_value = input[position++];
        if (word_length_value < 1 || word_length_value > (long)MAX_WORD_LENGTH) return -1;
        usz word_length = (usz)word_length_value;
        if (word_length > length - position) return -1;
        starts[i] = position;
        lengths[i] = word_length;
        for (usz j = 0; j < word_length; j++)
            if (input[position + j] < 33 || input[position + j] > 126) return -1;
        position += word_length;
    }
    if (position != length) return -1;

    Trie trie = {};
    usz root = 0;
    for (usz i = 0; i < word_count; i++) {
        if (root == 0) root = new_suffix(&trie, input, starts[i], lengths[i]);
        else insert_word(&trie, root, input, starts[i], lengths[i], 0);
    }
    usz output_length = 0;
    measure_output(&trie, root, 0, &output_length);
    if (output_length > MAX_OUTPUT_BYTES) return -1;
    if (output_length > 0 && (output == null || capacity < output_length)) return -2;
    if (output_length == 0) return 0;
    uchar[MAX_WORD_LENGTH] prefix = {};
    position = 0;
    emit_output(&trie, root, 0, &prefix[0], output, &position);
    return (long)position;
}
