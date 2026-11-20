module glushkov_bit_parallel_regex_search;

const MAX_TEXT = 24;
const MAX_PATTERN = 32;
const MAX_POSITIONS = 8;
const MAX_NODES = 64;
const POSITION_NODE = 1;
const CONCAT_NODE = 2;
const ALT_NODE = 3;
const STAR_NODE = 4;

struct RegexNode { uint kind; uint left; uint right; uint position; }
struct RegexParser {
    long* pattern;
    usz length;
    usz cursor;
    usz node_count;
    usz position_count;
    RegexNode[MAX_NODES] nodes;
    uchar[MAX_POSITIONS + 1] symbols;
    bool failed;
}

fn uint add_node(RegexParser* p, uint kind, uint left, uint right, uint position) {
    if (p->node_count >= MAX_NODES) { p->failed = true; return 0; }
    uint result = (uint)p->node_count;
    p->node_count++;
    p->nodes[result] = RegexNode{kind, left, right, position};
    return result;
}

fn uint parse_expression(RegexParser* p);

fn uint parse_atom(RegexParser* p) {
    if (p->cursor >= p->length) { p->failed = true; return 0; }
    long token = p->pattern[p->cursor++];
    if (token == '(') {
        uint result = parse_expression(p);
        if (p->failed || p->cursor >= p->length || p->pattern[p->cursor] != ')') { p->failed = true; return 0; }
        p->cursor++;
        return result;
    }
    if (token != 'a' && token != 'b' && token != 'c' && token != '.') { p->failed = true; return 0; }
    if (p->position_count >= MAX_POSITIONS) { p->failed = true; return 0; }
    p->position_count++;
    uint position = (uint)p->position_count;
    p->symbols[position] = (uchar)token;
    return add_node(p, POSITION_NODE, 0, 0, position);
}

fn uint parse_repetition(RegexParser* p) {
    uint result = parse_atom(p);
    if (!p->failed && p->cursor < p->length && p->pattern[p->cursor] == '*') {
        p->cursor++;
        result = add_node(p, STAR_NODE, result, 0, 0);
    }
    return result;
}

fn uint parse_concatenation(RegexParser* p) {
    if (p->cursor >= p->length || p->pattern[p->cursor] == '|' || p->pattern[p->cursor] == ')') {
        p->failed = true; return 0;
    }
    uint result = parse_repetition(p);
    while (!p->failed && p->cursor < p->length && p->pattern[p->cursor] != '|' && p->pattern[p->cursor] != ')') {
        uint right = parse_repetition(p);
        result = add_node(p, CONCAT_NODE, result, right, 0);
    }
    return result;
}

fn uint parse_expression(RegexParser* p) {
    uint result = parse_concatenation(p);
    while (!p->failed && p->cursor < p->length && p->pattern[p->cursor] == '|') {
        p->cursor++;
        uint right = parse_concatenation(p);
        result = add_node(p, ALT_NODE, result, right, 0);
    }
    return result;
}

fn long glushkov_bit_parallel_regex_search(long* input, usz length, char* output,
    usz capacity) @export("glushkov_bit_parallel_regex_search") {
    if (input == null || length < 2 || length > 58) return -1;
    if (input[0] < 0 || input[0] > MAX_TEXT || input[1] < 1 || input[1] > MAX_PATTERN) return -1;
    usz text_length = (usz)input[0];
    usz pattern_length = (usz)input[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (usz i = 0; i < text_length + pattern_length; i++)
        if (input[2 + i] < 1 || input[2 + i] > 127) return -1;

    RegexParser parser = { .pattern = &input[2 + text_length], .length = pattern_length };
    uint root = parse_expression(&parser);
    if (parser.failed || parser.cursor != pattern_length || parser.node_count == 0) return -1;

    bool[MAX_NODES] nullable = zeroed;
    ushort[MAX_NODES] first = zeroed;
    ushort[MAX_NODES] last = zeroed;
    ushort[MAX_POSITIONS + 1] follow = zeroed;
    for (usz i = 0; i < parser.node_count; i++) {
        RegexNode node = parser.nodes[i];
        if (node.kind == POSITION_NODE) {
            ushort bit = (ushort)(1u << node.position);
            first[i] = bit; last[i] = bit;
        } else if (node.kind == STAR_NODE) {
            nullable[i] = true; first[i] = first[node.left]; last[i] = last[node.left];
            for (usz pos = 1; pos <= parser.position_count; pos++)
                if ((last[node.left] & (ushort)(1u << pos)) != 0) follow[pos] |= first[node.left];
        } else if (node.kind == ALT_NODE) {
            nullable[i] = nullable[node.left] || nullable[node.right];
            first[i] = first[node.left] | first[node.right];
            last[i] = last[node.left] | last[node.right];
        } else {
            nullable[i] = nullable[node.left] && nullable[node.right];
            first[i] = first[node.left] | (nullable[node.left] ? first[node.right] : 0);
            last[i] = last[node.right] | (nullable[node.right] ? last[node.left] : 0);
            for (usz pos = 1; pos <= parser.position_count; pos++)
                if ((last[node.left] & (ushort)(1u << pos)) != 0) follow[pos] |= first[node.right];
        }
    }
    follow[0] = first[root] | 1;
    ushort[512] transitions = zeroed;
    usz subset_count = (usz)1 << (parser.position_count + 1);
    for (usz subset = 1; subset < subset_count; subset++) {
        usz state = 0;
        while (((subset >> state) & 1) == 0) state++;
        transitions[subset] = transitions[subset & (subset - 1)] | follow[state];
    }
    ushort[128] byte_masks = zeroed;
    for (usz byte = 0; byte < 128; byte++) byte_masks[byte] = 1;
    for (usz pos = 1; pos <= parser.position_count; pos++)
        for (usz byte = 1; byte < 128; byte++)
            if (parser.symbols[pos] == '.' || parser.symbols[pos] == byte) byte_masks[byte] |= (ushort)(1u << pos);

    char[MAX_TEXT] staged = zeroed;
    ushort active = 1;
    for (usz i = 0; i < text_length; i++) {
        active = transitions[active] & byte_masks[(usz)input[2 + i]];
        staged[i] = (active & last[root]) != 0 ? 1 : 0;
    }
    if (text_length != 0 && (output == null || capacity < text_length)) return -2;
    for (usz i = 0; i < text_length; i++) output[i] = staged[i];
    return (long)text_length;
}
