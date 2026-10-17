module mcnaughton_yamada_thompson;

const usz MAX_PATTERN_LENGTH = 16;
const usz MAX_TEXT_LENGTH = 32;
const usz MAX_PARSEABLE_INPUT_VALUES = 51;
const int MAX_NFA_STATES = 8;
const int MAX_NFA_EDGES = 32;

struct NfaEdge { int from; int to; int label; }
struct Nfa { NfaEdge[MAX_NFA_EDGES] edges; int edge_count; int state_count; }
struct Fragment { int start; int accept; }
struct Parser { int* pattern; usz length; usz position; Nfa* nfa; bool valid; }

fn int new_state(Nfa* nfa) {
    if (nfa->state_count >= MAX_NFA_STATES) return -1;
    int result = nfa->state_count;
    nfa->state_count++;
    return result;
}

fn bool add_edge(Nfa* nfa, int from, int to, int label) {
    if (nfa->edge_count >= MAX_NFA_EDGES || from < 0 || to < 0) return false;
    NfaEdge edge;
    edge.from = from;
    edge.to = to;
    edge.label = label;
    nfa->edges[nfa->edge_count] = edge;
    nfa->edge_count++;
    return true;
}

fn Fragment invalid_fragment() {
    Fragment fragment;
    fragment.start = -1;
    fragment.accept = -1;
    return fragment;
}

fn bool fragment_is_valid(Fragment fragment) {
    return fragment.start >= 0 && fragment.accept >= 0;
}

fn Fragment make_literal(Nfa* nfa, int literal) {
    int start = new_state(nfa);
    int accept = new_state(nfa);
    if (start < 0 || accept < 0 || !add_edge(nfa, start, accept, literal)) return invalid_fragment();
    Fragment fragment;
    fragment.start = start;
    fragment.accept = accept;
    return fragment;
}

fn Fragment make_concat(Nfa* nfa, Fragment left, Fragment right) {
    if (!fragment_is_valid(left) || !fragment_is_valid(right) ||
        !add_edge(nfa, left.accept, right.start, 0)) return invalid_fragment();
    Fragment fragment;
    fragment.start = left.start;
    fragment.accept = right.accept;
    return fragment;
}

fn Fragment make_union(Nfa* nfa, Fragment left, Fragment right) {
    if (!fragment_is_valid(left) || !fragment_is_valid(right)) return invalid_fragment();
    int start = new_state(nfa);
    int accept = new_state(nfa);
    if (start < 0 || accept < 0 ||
        !add_edge(nfa, start, left.start, 0) ||
        !add_edge(nfa, start, right.start, 0) ||
        !add_edge(nfa, left.accept, accept, 0) ||
        !add_edge(nfa, right.accept, accept, 0)) return invalid_fragment();
    Fragment fragment;
    fragment.start = start;
    fragment.accept = accept;
    return fragment;
}

fn Fragment make_star(Nfa* nfa, Fragment child) {
    if (!fragment_is_valid(child)) return invalid_fragment();
    int start = new_state(nfa);
    int accept = new_state(nfa);
    if (start < 0 || accept < 0 ||
        !add_edge(nfa, start, child.start, 0) ||
        !add_edge(nfa, start, accept, 0) ||
        !add_edge(nfa, child.accept, child.start, 0) ||
        !add_edge(nfa, child.accept, accept, 0)) return invalid_fragment();
    Fragment fragment;
    fragment.start = start;
    fragment.accept = accept;
    return fragment;
}

fn bool is_atom_start(int token) {
    return token == 'a' || token == 'b' || token == 'c' || token == '(';
}

fn Fragment parse_union(Parser* parser);

fn Fragment parse_atom(Parser* parser) {
    if (!parser->valid || parser->position >= parser->length) {
        parser->valid = false;
        return invalid_fragment();
    }
    int token = parser->pattern[parser->position];
    parser->position++;
    if (token == 'a' || token == 'b' || token == 'c') {
        Fragment fragment = make_literal(parser->nfa, token);
        if (!fragment_is_valid(fragment)) parser->valid = false;
        return fragment;
    }
    if (token == '(') {
        Fragment fragment = parse_union(parser);
        if (!parser->valid || parser->position >= parser->length ||
            parser->pattern[parser->position] != ')') {
            parser->valid = false;
            return invalid_fragment();
        }
        parser->position++;
        return fragment;
    }
    parser->valid = false;
    return invalid_fragment();
}

fn Fragment parse_repeat(Parser* parser) {
    Fragment fragment = parse_atom(parser);
    if (!parser->valid) return invalid_fragment();
    if (parser->position < parser->length && parser->pattern[parser->position] == '*') {
        parser->position++;
        fragment = make_star(parser->nfa, fragment);
        if (!fragment_is_valid(fragment)) parser->valid = false;
    }
    return fragment;
}

fn Fragment parse_concat(Parser* parser) {
    if (!parser->valid || parser->position >= parser->length ||
        !is_atom_start(parser->pattern[parser->position])) {
        parser->valid = false;
        return invalid_fragment();
    }
    Fragment fragment = parse_repeat(parser);
    while (parser->valid && parser->position < parser->length &&
           is_atom_start(parser->pattern[parser->position])) {
        Fragment right = parse_repeat(parser);
        fragment = make_concat(parser->nfa, fragment, right);
        if (!fragment_is_valid(fragment)) parser->valid = false;
    }
    return fragment;
}

fn Fragment parse_union(Parser* parser) {
    Fragment fragment = parse_concat(parser);
    while (parser->valid && parser->position < parser->length &&
           parser->pattern[parser->position] == '|') {
        parser->position++;
        Fragment right = parse_concat(parser);
        fragment = make_union(parser->nfa, fragment, right);
        if (!fragment_is_valid(fragment)) parser->valid = false;
    }
    return fragment;
}

fn bool source_parser_compatible_slice(int* source, usz length, usz recursion_depth) {
    if (recursion_depth > 64) return false;
    if (length == 0 || length == 1) return true;
    if (source[0] == '(' && source[length - 1] == ')') {
        int depth = 0;
        for (usz index = 0; index < length; index++) {
            if (source[index] == '(') depth++;
            else if (source[index] == ')') depth--;
            if (depth < 0) return false;
            if (depth == 0 && index < length - 1) return false;
        }
        if (depth != 0) return false;
        return source_parser_compatible_slice(source + 1, length - 2, recursion_depth + 1);
    }

    int[2] operators = {'|', '\n'};
    for (usz op = 0; op < 2; op++) {
        int depth = 0;
        for (usz index = 0; index < length; index++) {
            if (depth == 0 && source[index] == operators[op]) {
                return source_parser_compatible_slice(source, index, recursion_depth + 1) &&
                       source_parser_compatible_slice(source + index + 1,
                                                     length - index - 1,
                                                     recursion_depth + 1);
            }
            if (source[index] == '(') depth++;
            else if (source[index] == ')') depth--;
        }
    }
    return source[length - 1] == '*' &&
           source_parser_compatible_slice(source, length - 1, recursion_depth + 1);
}

fn bool source_parser_compatible(int* pattern, usz length) {
    int[MAX_PATTERN_LENGTH * 2] processed = zeroed;
    usz processed_length = 0;
    for (usz index = 0; index < length; index++) {
        int token = pattern[index];
        processed[processed_length] = token;
        processed_length++;
        if (index + 1 == length) continue;
        int next = pattern[index + 1];
        bool token_literal = token != '(' && token != ')' && token != '*' && token != '|';
        bool next_literal = next != '(' && next != ')' && next != '*' && next != '|';
        bool insert_concat =
            (token_literal && next_literal) ||
            (token_literal && next == '(') ||
            (token == ')' && next == '(') ||
            (token == ')' && next_literal) ||
            (token == '*' && next_literal) ||
            (token == '*' && next == '(');
        if (insert_concat) {
            processed[processed_length] = '\n';
            processed_length++;
        }
    }
    return source_parser_compatible_slice(&processed[0], processed_length, 0);
}

fn uint epsilon_closure(Nfa* nfa, uint states) {
    bool changed = false;
    do {
        changed = false;
        for (int edge_index = 0; edge_index < nfa->edge_count; edge_index++) {
            NfaEdge edge = nfa->edges[edge_index];
            uint from_bit = 1u << (uint)edge.from;
            uint to_bit = 1u << (uint)edge.to;
            if (edge.label == 0 && (states & from_bit) != 0 && (states & to_bit) == 0) {
                states |= to_bit;
                changed = true;
            }
        }
    } while (changed);
    return states;
}

fn long mcnaughton_yamada_thompson(long* input, usz input_length)
    @export("mcnaughton_yamada_thompson")
{
    if (input == null || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_PATTERN_LENGTH ||
        input[1] < 0 || input[1] > (long)MAX_TEXT_LENGTH) return -1;
    usz pattern_length = (usz)input[0];
    usz text_length = (usz)input[1];
    if (input_length != 2 + pattern_length + text_length) return -1;

    int[MAX_PATTERN_LENGTH] pattern = zeroed;
    int[MAX_TEXT_LENGTH] text = zeroed;
    for (usz index = 0; index < pattern_length; index++) {
        long value = input[2 + index];
        if (value != 'a' && value != 'b' && value != 'c' && value != '(' &&
            value != ')' && value != '*' && value != '|') return -1;
        pattern[index] = (int)value;
    }
    for (usz index = 0; index < text_length; index++) {
        long value = input[2 + pattern_length + index];
        if (value < 1 || value > 127) return -1;
        text[index] = (int)value;
    }

    if (pattern_length == 0) return text_length == 0 ? 1 : 0;
    if (!source_parser_compatible(&pattern[0], pattern_length)) return -1;

    Nfa nfa = zeroed;
    Parser parser;
    parser.pattern = &pattern[0];
    parser.length = pattern_length;
    parser.position = 0;
    parser.nfa = &nfa;
    parser.valid = true;
    Fragment root = parse_union(&parser);
    if (!parser.valid || parser.position != pattern_length || !fragment_is_valid(root)) return -1;

    uint active = epsilon_closure(&nfa, 1u << (uint)root.start);
    for (usz index = 0; index < text_length; index++) {
        uint next_states = 0;
        for (int edge_index = 0; edge_index < nfa.edge_count; edge_index++) {
            NfaEdge edge = nfa.edges[edge_index];
            if (edge.label != 0 && edge.label == text[index] &&
                (active & (1u << (uint)edge.from)) != 0) {
                next_states |= 1u << (uint)edge.to;
            }
        }
        active = epsilon_closure(&nfa, next_states);
    }
    return (active & (1u << (uint)root.accept)) != 0 ? 1 : 0;
}
