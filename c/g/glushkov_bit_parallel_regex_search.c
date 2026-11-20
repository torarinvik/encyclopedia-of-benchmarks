#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 24
#define MAX_PATTERN 32
#define MAX_POSITIONS 8
#define MAX_STATES 9
#define MAX_NODES 64

enum { NODE_POSITION = 1, NODE_CONCAT = 2, NODE_ALT = 3, NODE_STAR = 4 };
typedef struct { uint8_t kind, left, right, position; } RegexNode;
typedef struct {
    const int64_t *pattern;
    size_t length, cursor, node_count, position_count;
    RegexNode nodes[MAX_NODES];
    uint8_t symbols[MAX_STATES];
    int failed;
} RegexParser;

static int add_node(RegexParser *p, uint8_t kind, uint8_t left, uint8_t right, uint8_t position) {
    if (p->node_count >= MAX_NODES) { p->failed = 1; return 0; }
    size_t result = p->node_count++;
    p->nodes[result] = (RegexNode){kind, left, right, position};
    return (int)result;
}

static int parse_expression(RegexParser *p);

static int parse_atom(RegexParser *p) {
    if (p->cursor >= p->length) { p->failed = 1; return 0; }
    int64_t token = p->pattern[p->cursor++];
    if (token == '(') {
        int inside = parse_expression(p);
        if (p->failed || p->cursor >= p->length || p->pattern[p->cursor] != ')') {
            p->failed = 1; return 0;
        }
        ++p->cursor;
        return inside;
    }
    if (token != 'a' && token != 'b' && token != 'c' && token != '.') {
        p->failed = 1; return 0;
    }
    if (p->position_count >= MAX_POSITIONS) { p->failed = 1; return 0; }
    uint8_t position = (uint8_t)++p->position_count;
    p->symbols[position] = (uint8_t)token;
    return add_node(p, NODE_POSITION, 0, 0, position);
}

static int parse_repetition(RegexParser *p) {
    int result = parse_atom(p);
    if (p->failed) return result;
    if (p->cursor < p->length && p->pattern[p->cursor] == '*') {
        ++p->cursor;
        result = add_node(p, NODE_STAR, (uint8_t)result, 0, 0);
    }
    return result;
}

static int parse_concatenation(RegexParser *p) {
    if (p->cursor >= p->length || p->pattern[p->cursor] == '|' || p->pattern[p->cursor] == ')') {
        p->failed = 1; return 0;
    }
    int result = parse_repetition(p);
    while (!p->failed && p->cursor < p->length && p->pattern[p->cursor] != '|' && p->pattern[p->cursor] != ')') {
        int next = parse_repetition(p);
        result = add_node(p, NODE_CONCAT, (uint8_t)result, (uint8_t)next, 0);
    }
    return result;
}

static int parse_expression(RegexParser *p) {
    int result = parse_concatenation(p);
    while (!p->failed && p->cursor < p->length && p->pattern[p->cursor] == '|') {
        ++p->cursor;
        int right = parse_concatenation(p);
        result = add_node(p, NODE_ALT, (uint8_t)result, (uint8_t)right, 0);
    }
    return result;
}

int64_t glushkov_bit_parallel_regex_search(const int64_t *input, size_t length,
                                            uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 2 + MAX_TEXT + MAX_PATTERN) return -1;
    int64_t text_value = input[0], pattern_value = input[1];
    if (text_value < 0 || text_value > MAX_TEXT || pattern_value < 1 || pattern_value > MAX_PATTERN) return -1;
    size_t text_length = (size_t)text_value, pattern_length = (size_t)pattern_value;
    if (length != 2 + text_length + pattern_length) return -1;
    for (size_t i = 0; i < text_length + pattern_length; ++i)
        if (input[2 + i] < 1 || input[2 + i] > 127) return -1;

    RegexParser parser = {0};
    parser.pattern = input + 2 + text_length;
    parser.length = pattern_length;
    int root = parse_expression(&parser);
    if (parser.failed || parser.cursor != pattern_length || parser.node_count == 0) return -1;

    uint8_t nullable[MAX_NODES] = {0};
    uint16_t first[MAX_NODES] = {0}, last[MAX_NODES] = {0}, follow[MAX_STATES] = {0};
    for (size_t i = 0; i < parser.node_count; ++i) {
        RegexNode node = parser.nodes[i];
        if (node.kind == NODE_POSITION) {
            uint16_t bit = (uint16_t)(1u << node.position);
            first[i] = last[i] = bit;
        } else if (node.kind == NODE_STAR) {
            nullable[i] = 1;
            first[i] = first[node.left]; last[i] = last[node.left];
            uint16_t positions = last[node.left];
            for (size_t p = 1; p <= parser.position_count; ++p)
                if (positions & (uint16_t)(1u << p)) follow[p] |= first[node.left];
        } else {
            uint8_t a = node.left, b = node.right;
            if (node.kind == NODE_ALT) {
                nullable[i] = nullable[a] || nullable[b];
                first[i] = first[a] | first[b];
                last[i] = last[a] | last[b];
            } else {
                nullable[i] = nullable[a] && nullable[b];
                first[i] = first[a] | (nullable[a] ? first[b] : 0);
                last[i] = last[b] | (nullable[b] ? last[a] : 0);
                for (size_t p = 1; p <= parser.position_count; ++p)
                    if (last[a] & (uint16_t)(1u << p)) follow[p] |= first[b];
            }
        }
    }
    follow[0] = first[root] | 1u;
    uint16_t transitions[1u << MAX_STATES] = {0};
    size_t subset_count = (size_t)1u << (parser.position_count + 1);
    for (size_t subset = 1; subset < subset_count; ++subset) {
        size_t state = 0;
        while (((subset >> state) & 1u) == 0) ++state;
        transitions[subset] = transitions[subset & (subset - 1)] | follow[state];
    }
    uint16_t byte_masks[128];
    for (size_t byte = 0; byte < 128; ++byte) byte_masks[byte] = 1u;
    for (size_t p = 1; p <= parser.position_count; ++p)
        for (size_t byte = 1; byte < 128; ++byte)
            if (parser.symbols[p] == '.' || parser.symbols[p] == byte)
                byte_masks[byte] |= (uint16_t)(1u << p);

    uint8_t staged[MAX_TEXT];
    uint16_t state = 1u;
    for (size_t i = 0; i < text_length; ++i) {
        uint8_t byte = (uint8_t)input[2 + i];
        state = transitions[state] & byte_masks[byte];
        staged[i] = (state & last[root]) != 0 ? 1u : 0u;
    }
    if (text_length != 0 && (output == NULL || capacity < text_length)) return -2;
    for (size_t i = 0; i < text_length; ++i) output[i] = staged[i];
    return (int64_t)text_length;
}
