#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_pattern_length = 16;
constexpr std::size_t max_text_length = 32;
constexpr std::size_t max_parseable_input_values = 51;
constexpr std::size_t max_nfa_states = 8;
constexpr std::size_t max_nfa_edges = 32;

struct NfaEdge {
    int from;
    int to;
    std::uint8_t label;
};

struct Nfa {
    NfaEdge edges[max_nfa_edges];
    std::size_t edge_count;
    std::size_t state_count;
};

struct Fragment {
    int start;
    int accept;
};

struct Parser {
    const std::uint8_t* pattern;
    std::size_t length;
    std::size_t position;
    Nfa* nfa;
    bool valid;
};

int new_state(Nfa* nfa) noexcept
{
    if (nfa->state_count >= max_nfa_states) return -1;
    return static_cast<int>(nfa->state_count++);
}

bool add_edge(Nfa* nfa, int from, int to, std::uint8_t label) noexcept
{
    if (nfa->edge_count >= max_nfa_edges || from < 0 || to < 0) return false;
    nfa->edges[nfa->edge_count++] = {from, to, label};
    return true;
}

constexpr Fragment invalid_fragment() noexcept { return {-1, -1}; }
constexpr bool fragment_is_valid(Fragment fragment) noexcept
{
    return fragment.start >= 0 && fragment.accept >= 0;
}

Fragment make_literal(Nfa* nfa, std::uint8_t literal) noexcept
{
    const int start = new_state(nfa);
    const int accept = new_state(nfa);
    if (start < 0 || accept < 0 || !add_edge(nfa, start, accept, literal)) return invalid_fragment();
    return {start, accept};
}

Fragment make_concat(Nfa* nfa, Fragment left, Fragment right) noexcept
{
    if (!fragment_is_valid(left) || !fragment_is_valid(right) ||
        !add_edge(nfa, left.accept, right.start, 0)) return invalid_fragment();
    return {left.start, right.accept};
}

Fragment make_union(Nfa* nfa, Fragment left, Fragment right) noexcept
{
    if (!fragment_is_valid(left) || !fragment_is_valid(right)) return invalid_fragment();
    const int start = new_state(nfa);
    const int accept = new_state(nfa);
    if (start < 0 || accept < 0 ||
        !add_edge(nfa, start, left.start, 0) ||
        !add_edge(nfa, start, right.start, 0) ||
        !add_edge(nfa, left.accept, accept, 0) ||
        !add_edge(nfa, right.accept, accept, 0)) return invalid_fragment();
    return {start, accept};
}

Fragment make_star(Nfa* nfa, Fragment child) noexcept
{
    if (!fragment_is_valid(child)) return invalid_fragment();
    const int start = new_state(nfa);
    const int accept = new_state(nfa);
    if (start < 0 || accept < 0 ||
        !add_edge(nfa, start, child.start, 0) ||
        !add_edge(nfa, start, accept, 0) ||
        !add_edge(nfa, child.accept, child.start, 0) ||
        !add_edge(nfa, child.accept, accept, 0)) return invalid_fragment();
    return {start, accept};
}

bool is_atom_start(std::uint8_t token) noexcept
{
    return token == 'a' || token == 'b' || token == 'c' || token == '(';
}

Fragment parse_union(Parser* parser) noexcept;

Fragment parse_atom(Parser* parser) noexcept
{
    if (!parser->valid || parser->position >= parser->length) {
        parser->valid = false;
        return invalid_fragment();
    }
    const std::uint8_t token = parser->pattern[parser->position++];
    if (token == 'a' || token == 'b' || token == 'c') {
        const Fragment fragment = make_literal(parser->nfa, token);
        if (!fragment_is_valid(fragment)) parser->valid = false;
        return fragment;
    }
    if (token == '(') {
        const Fragment fragment = parse_union(parser);
        if (!parser->valid || parser->position >= parser->length ||
            parser->pattern[parser->position] != ')') {
            parser->valid = false;
            return invalid_fragment();
        }
        ++parser->position;
        return fragment;
    }
    parser->valid = false;
    return invalid_fragment();
}

Fragment parse_repeat(Parser* parser) noexcept
{
    Fragment fragment = parse_atom(parser);
    if (!parser->valid) return invalid_fragment();
    if (parser->position < parser->length && parser->pattern[parser->position] == '*') {
        ++parser->position;
        fragment = make_star(parser->nfa, fragment);
        if (!fragment_is_valid(fragment)) parser->valid = false;
    }
    return fragment;
}

Fragment parse_concat(Parser* parser) noexcept
{
    if (!parser->valid || parser->position >= parser->length ||
        !is_atom_start(parser->pattern[parser->position])) {
        parser->valid = false;
        return invalid_fragment();
    }
    Fragment fragment = parse_repeat(parser);
    while (parser->valid && parser->position < parser->length &&
           is_atom_start(parser->pattern[parser->position])) {
        const Fragment right = parse_repeat(parser);
        fragment = make_concat(parser->nfa, fragment, right);
        if (!fragment_is_valid(fragment)) parser->valid = false;
    }
    return fragment;
}

Fragment parse_union(Parser* parser) noexcept
{
    Fragment fragment = parse_concat(parser);
    while (parser->valid && parser->position < parser->length &&
           parser->pattern[parser->position] == '|') {
        ++parser->position;
        const Fragment right = parse_concat(parser);
        fragment = make_union(parser->nfa, fragment, right);
        if (!fragment_is_valid(fragment)) parser->valid = false;
    }
    return fragment;
}

bool source_parser_compatible_slice(const std::uint8_t* source, std::size_t length,
                                   std::size_t recursion_depth) noexcept
{
    if (recursion_depth > 64) return false;
    if (length == 0 || length == 1) return true;
    if (source[0] == '(' && source[length - 1] == ')') {
        int depth = 0;
        for (std::size_t index = 0; index < length; ++index) {
            if (source[index] == '(') ++depth;
            else if (source[index] == ')') --depth;
            if (depth < 0) return false;
            if (depth == 0 && index < length - 1) return false;
        }
        if (depth != 0) return false;
        return source_parser_compatible_slice(source + 1, length - 2, recursion_depth + 1);
    }

    constexpr std::uint8_t operators[2] = {'|', '\n'};
    for (std::size_t op = 0; op < 2; ++op) {
        int depth = 0;
        for (std::size_t index = 0; index < length; ++index) {
            if (depth == 0 && source[index] == operators[op]) {
                return source_parser_compatible_slice(source, index, recursion_depth + 1) &&
                       source_parser_compatible_slice(source + index + 1,
                                                      length - index - 1,
                                                      recursion_depth + 1);
            }
            if (source[index] == '(') ++depth;
            else if (source[index] == ')') --depth;
        }
    }
    return source[length - 1] == '*' &&
           source_parser_compatible_slice(source, length - 1, recursion_depth + 1);
}

bool source_parser_compatible(const std::uint8_t* pattern, std::size_t length) noexcept
{
    std::uint8_t processed[max_pattern_length * 2]{};
    std::size_t processed_length = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const std::uint8_t token = pattern[index];
        processed[processed_length++] = token;
        if (index + 1 == length) continue;
        const std::uint8_t next = pattern[index + 1];
        const bool token_literal = token != '(' && token != ')' && token != '*' && token != '|';
        const bool next_literal = next != '(' && next != ')' && next != '*' && next != '|';
        const bool insert_concat =
            (token_literal && next_literal) ||
            (token_literal && next == '(') ||
            (token == ')' && next == '(') ||
            (token == ')' && next_literal) ||
            (token == '*' && next_literal) ||
            (token == '*' && next == '(');
        if (insert_concat) processed[processed_length++] = '\n';
    }
    return source_parser_compatible_slice(processed, processed_length, 0);
}

unsigned int epsilon_closure(const Nfa* nfa, unsigned int states) noexcept
{
    bool changed;
    do {
        changed = false;
        for (std::size_t edge_index = 0; edge_index < nfa->edge_count; ++edge_index) {
            const NfaEdge edge = nfa->edges[edge_index];
            const unsigned int from_bit = 1u << static_cast<unsigned int>(edge.from);
            const unsigned int to_bit = 1u << static_cast<unsigned int>(edge.to);
            if (edge.label == 0 && (states & from_bit) != 0 && (states & to_bit) == 0) {
                states |= to_bit;
                changed = true;
            }
        }
    } while (changed);
    return states;
}
} // namespace

extern "C" std::int64_t mcnaughton_yamada_thompson(const std::int64_t* values,
                                                    std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > max_parseable_input_values) return -1;
    if (values[0] < 0 || values[0] > static_cast<std::int64_t>(max_pattern_length) ||
        values[1] < 0 || values[1] > static_cast<std::int64_t>(max_text_length)) return -1;
    const std::size_t pattern_length = static_cast<std::size_t>(values[0]);
    const std::size_t text_length = static_cast<std::size_t>(values[1]);
    if (length != 2 + pattern_length + text_length) return -1;

    std::uint8_t pattern[max_pattern_length]{};
    std::uint8_t text[max_text_length]{};
    for (std::size_t index = 0; index < pattern_length; ++index) {
        const std::int64_t value = values[2 + index];
        if (value != 'a' && value != 'b' && value != 'c' && value != '(' &&
            value != ')' && value != '*' && value != '|') return -1;
        pattern[index] = static_cast<std::uint8_t>(value);
    }
    for (std::size_t index = 0; index < text_length; ++index) {
        const std::int64_t value = values[2 + pattern_length + index];
        if (value < 1 || value > 127) return -1;
        text[index] = static_cast<std::uint8_t>(value);
    }

    if (pattern_length == 0) return text_length == 0 ? 1 : 0;
    if (!source_parser_compatible(pattern, pattern_length)) return -1;

    Nfa nfa{};
    Parser parser{pattern, pattern_length, 0, &nfa, true};
    const Fragment root = parse_union(&parser);
    if (!parser.valid || parser.position != pattern_length || !fragment_is_valid(root)) return -1;

    unsigned int active = epsilon_closure(&nfa, 1u << static_cast<unsigned int>(root.start));
    for (std::size_t index = 0; index < text_length; ++index) {
        unsigned int next_states = 0;
        for (std::size_t edge_index = 0; edge_index < nfa.edge_count; ++edge_index) {
            const NfaEdge edge = nfa.edges[edge_index];
            if (edge.label != 0 && edge.label == text[index] &&
                (active & (1u << static_cast<unsigned int>(edge.from))) != 0) {
                next_states |= 1u << static_cast<unsigned int>(edge.to);
            }
        }
        active = epsilon_closure(&nfa, next_states);
    }
    return (active & (1u << static_cast<unsigned int>(root.accept))) != 0 ? 1 : 0;
}
