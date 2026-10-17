module word_frequency_bst;

const usz MAX_INPUT_BYTES = 256;
const usz MAX_TOKEN_BYTES = 45;
const usz MAX_UNIQUE_WORDS = 128;
const usz MAX_OUTPUT_BYTES = 896;

struct WordNode {
    char[46] word;
    usz word_length;
    ulong frequency;
    int left;
    int right;
}

fn bool ascii_alpha(char value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

fn int compare_word(char* word, usz word_length, WordNode* node) {
    usz common = word_length < node.word_length ? word_length : node.word_length;
    for (usz i = 0; i < common; ++i) {
        if (word[i] < node.word[i]) return -1;
        if (word[i] > node.word[i]) return 1;
    }
    if (word_length < node.word_length) return -1;
    if (word_length > node.word_length) return 1;
    return 0;
}

fn int create_node(WordNode* nodes, usz* used, char* word, usz word_length) {
    if (*used >= MAX_UNIQUE_WORDS) return -1;
    int index = (int)*used;
    for (usz i = 0; i < word_length; ++i) nodes[index].word[i] = word[i];
    nodes[index].word[word_length] = '\0';
    nodes[index].word_length = word_length;
    nodes[index].frequency = 1;
    nodes[index].left = -1;
    nodes[index].right = -1;
    *used = *used + 1;
    return index;
}

fn bool insert_word(WordNode* nodes, usz* used, int* root, char* word, usz word_length) {
    if (*root < 0) {
        *root = create_node(nodes, used, word, word_length);
        return *root >= 0;
    }
    int current = *root;
    while (true) {
        int order = compare_word(word, word_length, &nodes[current]);
        if (order == 0) {
            nodes[current].frequency += 1;
            return true;
        }
        if (order < 0) {
            if (nodes[current].left < 0) {
                nodes[current].left = create_node(nodes, used, word, word_length);
                return nodes[current].left >= 0;
            }
            current = nodes[current].left;
        } else {
            if (nodes[current].right < 0) {
                nodes[current].right = create_node(nodes, used, word, word_length);
                return nodes[current].right >= 0;
            }
            current = nodes[current].right;
        }
    }
}

fn bool flush_token(char* token, usz* token_length, WordNode* nodes, usz* used, int* root) {
    if (*token_length == 0) return true;
    if (token[*token_length - 1] == '-') *token_length = *token_length - 1;
    if (*token_length > 0 && !insert_word(nodes, used, root, token, *token_length)) return false;
    *token_length = 0;
    return true;
}

fn bool append_byte(char* output, usz* written, char value) {
    if (*written >= MAX_OUTPUT_BYTES) return false;
    output[*written] = value;
    *written = *written + 1;
    return true;
}

fn bool build_output(WordNode* nodes, int root, char* output, usz* output_length) {
    int[MAX_UNIQUE_WORDS] stack;
    usz top = 0;
    usz written = 0;
    int current = root;
    while (current >= 0 || top > 0) {
        while (current >= 0) {
            if (top >= MAX_UNIQUE_WORDS) return false;
            stack[top++] = current;
            current = nodes[current].left;
        }
        current = stack[--top];
        for (usz i = 0; i < nodes[current].word_length; ++i)
            if (!append_byte(output, &written, nodes[current].word[i])) return false;
        if (!append_byte(output, &written, '\t')) return false;
        char[20] reversed;
        usz digits = 0;
        ulong frequency = nodes[current].frequency;
        do {
            reversed[digits++] = (char)('0' + frequency % 10);
            frequency /= 10;
        } while (frequency != 0);
        while (digits > 0) if (!append_byte(output, &written, reversed[--digits])) return false;
        if (!append_byte(output, &written, '\n')) return false;
        current = nodes[current].right;
    }
    *output_length = written;
    return true;
}

fn long word_frequency_bst(long* input, usz length, char* output, usz capacity)
        @export("word_frequency_bst") {
    if (input == null || length < 1 || length > MAX_INPUT_BYTES + 2) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_INPUT_BYTES) return -1;
    usz text_length = (usz)input[0];
    if (length != text_length + 1) return -1;
    for (usz i = 0; i < text_length; ++i)
        if (input[i + 1] < 0 || input[i + 1] > 127) return -1;

    WordNode[MAX_UNIQUE_WORDS] nodes;
    usz used = 0;
    int root = -1;
    char[MAX_TOKEN_BYTES + 1] token;
    usz token_length = 0;
    for (usz i = 0; i < text_length; ++i) {
        char byte = (char)input[i + 1];
        if (ascii_alpha(byte)) {
            if (token_length >= MAX_TOKEN_BYTES) return -1;
            token[token_length++] = byte >= 'A' && byte <= 'Z' ? (char)(byte + 32) : byte;
        } else if ((byte == '\'' || byte == '-') && token_length > 0 && ascii_alpha(token[token_length - 1])) {
            if (token_length >= MAX_TOKEN_BYTES) return -1;
            token[token_length++] = byte;
        } else if (!flush_token(&token[0], &token_length, &nodes[0], &used, &root)) {
            return -1;
        }
    }
    if (!flush_token(&token[0], &token_length, &nodes[0], &used, &root)) return -1;

    char[MAX_OUTPUT_BYTES] result;
    usz result_length = 0;
    if (!build_output(&nodes[0], root, &result[0], &result_length)) return -1;
    if (output == null || capacity < result_length) return -2;
    for (usz i = 0; i < result_length; ++i) output[i] = result[i];
    return (long)result_length;
}
