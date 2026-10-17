#include <stddef.h>
#include <stdint.h>

#define MAX_PATTERN_LENGTH 16u
#define MAX_TEXT_LENGTH 32u
#define MAX_PARSEABLE_INPUT_VALUES 51u
#define MAX_NFA_STATES 8u
#define MAX_NFA_EDGES 32u

typedef struct {
    int from;
    int to;
    uint8_t label; /* NUL denotes an epsilon transition. */
} NfaEdge;

typedef struct {
    NfaEdge edges[MAX_NFA_EDGES];
    size_t edge_count;
    size_t state_count;
} Nfa;

typedef struct {
    int start;
    int accept;
} Fragment;

typedef struct {
    const uint8_t *pattern;
    size_t length;
    size_t position;
    Nfa *nfa;
    int valid;
} Parser;

static int new_state(Nfa *nfa)
{
    if (nfa->state_count >= MAX_NFA_STATES) return -1;
    return (int)nfa->state_count++;
}

static int add_edge(Nfa *nfa, int from, int to, uint8_t label)
{
    if (nfa->edge_count >= MAX_NFA_EDGES || from < 0 || to < 0) return 0;
    NfaEdge *edge = &nfa->edges[nfa->edge_count++];
    edge->from = from;
    edge->to = to;
    edge->label = label;
    return 1;
}

static Fragment invalid_fragment(void)
{
    Fragment fragment = {-1, -1};
    return fragment;
}

static int fragment_is_valid(Fragment fragment)
{
    return fragment.start >= 0 && fragment.accept >= 0;
}

static Fragment make_literal(Nfa *nfa, uint8_t literal)
{
    Fragment fragment = invalid_fragment();
    const int start = new_state(nfa);
    const int accept = new_state(nfa);
    if (start < 0 || accept < 0 || !add_edge(nfa, start, accept, literal)) return fragment;
    fragment.start = start;
    fragment.accept = accept;
    return fragment;
}

static Fragment make_concat(Nfa *nfa, Fragment left, Fragment right)
{
    Fragment fragment = invalid_fragment();
    if (!fragment_is_valid(left) || !fragment_is_valid(right) ||
        !add_edge(nfa, left.accept, right.start, 0u)) return fragment;
    fragment.start = left.start;
    fragment.accept = right.accept;
    return fragment;
}

static Fragment make_union(Nfa *nfa, Fragment left, Fragment right)
{
    Fragment fragment = invalid_fragment();
    if (!fragment_is_valid(left) || !fragment_is_valid(right)) return fragment;
    const int start = new_state(nfa);
    const int accept = new_state(nfa);
    if (start < 0 || accept < 0 ||
        !add_edge(nfa, start, left.start, 0u) ||
        !add_edge(nfa, start, right.start, 0u) ||
        !add_edge(nfa, left.accept, accept, 0u) ||
        !add_edge(nfa, right.accept, accept, 0u)) return fragment;
    fragment.start = start;
    fragment.accept = accept;
    return fragment;
}

static Fragment make_star(Nfa *nfa, Fragment child)
{
    Fragment fragment = invalid_fragment();
    if (!fragment_is_valid(child)) return fragment;
    const int start = new_state(nfa);
    const int accept = new_state(nfa);
    if (start < 0 || accept < 0 ||
        !add_edge(nfa, start, child.start, 0u) ||
        !add_edge(nfa, start, accept, 0u) ||
        !add_edge(nfa, child.accept, child.start, 0u) ||
        !add_edge(nfa, child.accept, accept, 0u)) return fragment;
    fragment.start = start;
    fragment.accept = accept;
    return fragment;
}

static int is_atom_start(uint8_t token)
{
    return token == (uint8_t)'a' || token == (uint8_t)'b' ||
           token == (uint8_t)'c' || token == (uint8_t)'(';
}

static Fragment parse_union(Parser *parser);

static Fragment parse_atom(Parser *parser)
{
    if (!parser->valid || parser->position >= parser->length) {
        parser->valid = 0;
        return invalid_fragment();
    }

    const uint8_t token = parser->pattern[parser->position++];
    if (token == (uint8_t)'a' || token == (uint8_t)'b' || token == (uint8_t)'c') {
        Fragment fragment = make_literal(parser->nfa, token);
        if (!fragment_is_valid(fragment)) parser->valid = 0;
        return fragment;
    }
    if (token == (uint8_t)'(') {
        Fragment fragment = parse_union(parser);
        if (!parser->valid || parser->position >= parser->length ||
            parser->pattern[parser->position] != (uint8_t)')') {
            parser->valid = 0;
            return invalid_fragment();
        }
        ++parser->position;
        return fragment;
    }

    parser->valid = 0;
    return invalid_fragment();
}

static Fragment parse_repeat(Parser *parser)
{
    Fragment fragment = parse_atom(parser);
    if (!parser->valid) return invalid_fragment();
    if (parser->position < parser->length &&
        parser->pattern[parser->position] == (uint8_t)'*') {
        ++parser->position;
        fragment = make_star(parser->nfa, fragment);
        if (!fragment_is_valid(fragment)) parser->valid = 0;
    }
    return fragment;
}

static Fragment parse_concat(Parser *parser)
{
    if (!parser->valid || parser->position >= parser->length ||
        !is_atom_start(parser->pattern[parser->position])) {
        parser->valid = 0;
        return invalid_fragment();
    }

    Fragment fragment = parse_repeat(parser);
    while (parser->valid && parser->position < parser->length &&
           is_atom_start(parser->pattern[parser->position])) {
        Fragment right = parse_repeat(parser);
        fragment = make_concat(parser->nfa, fragment, right);
        if (!fragment_is_valid(fragment)) parser->valid = 0;
    }
    return fragment;
}

static Fragment parse_union(Parser *parser)
{
    Fragment fragment = parse_concat(parser);
    while (parser->valid && parser->position < parser->length &&
           parser->pattern[parser->position] == (uint8_t)'|') {
        ++parser->position;
        Fragment right = parse_concat(parser);
        fragment = make_union(parser->nfa, fragment, right);
        if (!fragment_is_valid(fragment)) parser->valid = 0;
    }
    return fragment;
}

static int source_parser_compatible_slice(const uint8_t *source, size_t length,
                                          size_t recursion_depth)
{
    if (recursion_depth > 64u) return 0;
    if (length == 0u || length == 1u) return 1;

    if (source[0] == (uint8_t)'(' && source[length - 1u] == (uint8_t)')') {
        int depth = 0;
        for (size_t index = 0u; index < length; ++index) {
            if (source[index] == (uint8_t)'(') ++depth;
            else if (source[index] == (uint8_t)')') --depth;
            if (depth < 0) return 0;
            if (depth == 0 && index < length - 1u) return 0;
        }
        if (depth != 0) return 0;
        return source_parser_compatible_slice(source + 1u, length - 2u,
                                              recursion_depth + 1u);
    }

    const uint8_t operators[2] = {(uint8_t)'|', (uint8_t)'\n'};
    for (size_t op = 0u; op < 2u; ++op) {
        int depth = 0;
        for (size_t index = 0u; index < length; ++index) {
            if (depth == 0 && source[index] == operators[op]) {
                return source_parser_compatible_slice(source, index, recursion_depth + 1u) &&
                       source_parser_compatible_slice(source + index + 1u,
                                                      length - index - 1u,
                                                      recursion_depth + 1u);
            }
            if (source[index] == (uint8_t)'(') ++depth;
            else if (source[index] == (uint8_t)')') --depth;
        }
    }

    return source[length - 1u] == (uint8_t)'*' &&
           source_parser_compatible_slice(source, length - 1u, recursion_depth + 1u);
}

static int source_parser_compatible(const uint8_t *pattern, size_t length)
{
    uint8_t processed[MAX_PATTERN_LENGTH * 2u];
    size_t processed_length = 0u;
    for (size_t index = 0u; index < length; ++index) {
        const uint8_t token = pattern[index];
        processed[processed_length++] = token;
        if (index + 1u == length) continue;
        const uint8_t next = pattern[index + 1u];
        const int token_literal = token != (uint8_t)'(' && token != (uint8_t)')' &&
                                  token != (uint8_t)'*' && token != (uint8_t)'|';
        const int next_literal = next != (uint8_t)'(' && next != (uint8_t)')' &&
                                 next != (uint8_t)'*' && next != (uint8_t)'|';
        const int insert_concat =
            (token_literal && next_literal) ||
            (token_literal && next == (uint8_t)'(') ||
            (token == (uint8_t)')' && next == (uint8_t)'(') ||
            (token == (uint8_t)')' && next_literal) ||
            (token == (uint8_t)'*' && next_literal) ||
            (token == (uint8_t)'*' && next == (uint8_t)'(');
        if (insert_concat) processed[processed_length++] = (uint8_t)'\n';
    }
    return source_parser_compatible_slice(processed, processed_length, 0u);
}

static unsigned int epsilon_closure(const Nfa *nfa, unsigned int states)
{
    int changed;
    do {
        changed = 0;
        for (size_t edge_index = 0u; edge_index < nfa->edge_count; ++edge_index) {
            const NfaEdge edge = nfa->edges[edge_index];
            const unsigned int from_bit = 1u << (unsigned int)edge.from;
            const unsigned int to_bit = 1u << (unsigned int)edge.to;
            if (edge.label == 0u && (states & from_bit) != 0u && (states & to_bit) == 0u) {
                states |= to_bit;
                changed = 1;
            }
        }
    } while (changed);
    return states;
}

int64_t mcnaughton_yamada_thompson(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2u || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (values[0] < 0 || values[0] > (int64_t)MAX_PATTERN_LENGTH ||
        values[1] < 0 || values[1] > (int64_t)MAX_TEXT_LENGTH) return -1;

    const size_t pattern_length = (size_t)values[0];
    const size_t text_length = (size_t)values[1];
    if (length != 2u + pattern_length + text_length) return -1;

    uint8_t pattern[MAX_PATTERN_LENGTH] = {0u};
    uint8_t text[MAX_TEXT_LENGTH] = {0u};
    for (size_t index = 0u; index < pattern_length; ++index) {
        const int64_t value = values[2u + index];
        if (value < 0 || value > 127) return -1;
        const uint8_t token = (uint8_t)value;
        if (token != (uint8_t)'a' && token != (uint8_t)'b' && token != (uint8_t)'c' &&
            token != (uint8_t)'(' && token != (uint8_t)')' &&
            token != (uint8_t)'*' && token != (uint8_t)'|') return -1;
        pattern[index] = token;
    }
    for (size_t index = 0u; index < text_length; ++index) {
        const int64_t value = values[2u + pattern_length + index];
        if (value < 1 || value > 127) return -1;
        text[index] = (uint8_t)value;
    }

    if (pattern_length == 0u) return text_length == 0u ? 1 : 0;
    if (!source_parser_compatible(pattern, pattern_length)) return -1;

    Nfa nfa = {{{0, 0, 0u}}, 0u, 0u};
    Parser parser = {pattern, pattern_length, 0u, &nfa, 1};
    Fragment root = parse_union(&parser);
    if (!parser.valid || parser.position != pattern_length || !fragment_is_valid(root)) return -1;

    unsigned int active = epsilon_closure(&nfa, 1u << (unsigned int)root.start);
    for (size_t index = 0u; index < text_length; ++index) {
        unsigned int next_states = 0u;
        for (size_t edge_index = 0u; edge_index < nfa.edge_count; ++edge_index) {
            const NfaEdge edge = nfa.edges[edge_index];
            if (edge.label != 0u && edge.label == text[index] &&
                (active & (1u << (unsigned int)edge.from)) != 0u) {
                next_states |= 1u << (unsigned int)edge.to;
            }
        }
        active = epsilon_closure(&nfa, next_states);
    }

    return (active & (1u << (unsigned int)root.accept)) != 0u ? 1 : 0;
}
