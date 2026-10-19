from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_PATTERN_LENGTH = 16
comptime MAX_TEXT_LENGTH = 32
comptime MAX_NFA_STATES = 8
comptime MAX_NFA_EDGES = 32


@fieldwise_init
struct Fragment:
    var start: Int
    var accept: Int


@fieldwise_init
struct Nfa:
    var edge_from: InlineArray[Int64, MAX_NFA_EDGES]
    var edge_to: InlineArray[Int64, MAX_NFA_EDGES]
    var edge_label: InlineArray[Int64, MAX_NFA_EDGES]
    var edge_count: Int
    var state_count: Int


fn invalid_fragment() -> Fragment:
    return Fragment(start=-1, accept=-1)


fn new_state(mut nfa: Nfa) -> Int:
    if nfa.state_count >= MAX_NFA_STATES:
        return -1
    let state = nfa.state_count
    nfa.state_count += 1
    return state


fn add_edge(mut nfa: Nfa, from: Int, to: Int, label: Int64) -> Bool:
    if nfa.edge_count >= MAX_NFA_EDGES or from < 0 or to < 0:
        return False
    nfa.edge_from[nfa.edge_count] = Int64(from)
    nfa.edge_to[nfa.edge_count] = Int64(to)
    nfa.edge_label[nfa.edge_count] = label
    nfa.edge_count += 1
    return True


fn make_literal(mut nfa: Nfa, literal: Int64) -> Fragment:
    let start = new_state(nfa)
    let accept = new_state(nfa)
    if start < 0 or accept < 0 or not add_edge(nfa, start, accept, literal):
        return invalid_fragment()
    return Fragment(start=start, accept=accept)


fn make_concat(mut nfa: Nfa, left: Fragment, right: Fragment) -> Fragment:
    if left.start < 0 or right.start < 0 or not add_edge(nfa, left.accept, right.start, 0):
        return invalid_fragment()
    return Fragment(start=left.start, accept=right.accept)


fn make_union(mut nfa: Nfa, left: Fragment, right: Fragment) -> Fragment:
    if left.start < 0 or right.start < 0:
        return invalid_fragment()
    let start = new_state(nfa)
    let accept = new_state(nfa)
    if (
        start < 0 or accept < 0 or not add_edge(nfa, start, left.start, 0)
        or not add_edge(nfa, start, right.start, 0)
        or not add_edge(nfa, left.accept, accept, 0)
        or not add_edge(nfa, right.accept, accept, 0)
    ):
        return invalid_fragment()
    return Fragment(start=start, accept=accept)


fn make_star(mut nfa: Nfa, child: Fragment) -> Fragment:
    if child.start < 0:
        return invalid_fragment()
    let start = new_state(nfa)
    let accept = new_state(nfa)
    if (
        start < 0 or accept < 0 or not add_edge(nfa, start, child.start, 0)
        or not add_edge(nfa, start, accept, 0)
        or not add_edge(nfa, child.accept, child.start, 0)
        or not add_edge(nfa, child.accept, accept, 0)
    ):
        return invalid_fragment()
    return Fragment(start=start, accept=accept)


fn is_atom_start(token: Int64) -> Bool:
    return token == 97 or token == 98 or token == 99 or token == 40


fn parse_union(
    pattern: InlineArray[Int64, MAX_PATTERN_LENGTH], length: Int,
    mut position: Int, mut valid: Bool, mut nfa: Nfa,
) -> Fragment:
    var fragment = parse_concat(pattern, length, position, valid, nfa)
    while valid and position < length and pattern[position] == 124:
        position += 1
        let right = parse_concat(pattern, length, position, valid, nfa)
        fragment = make_union(nfa, fragment, right)
        if fragment.start < 0:
            valid = False
    return fragment


fn parse_concat(
    pattern: InlineArray[Int64, MAX_PATTERN_LENGTH], length: Int,
    mut position: Int, mut valid: Bool, mut nfa: Nfa,
) -> Fragment:
    if not valid or position >= length or not is_atom_start(pattern[position]):
        valid = False
        return invalid_fragment()
    var fragment = parse_repeat(pattern, length, position, valid, nfa)
    while valid and position < length and is_atom_start(pattern[position]):
        let right = parse_repeat(pattern, length, position, valid, nfa)
        fragment = make_concat(nfa, fragment, right)
        if fragment.start < 0:
            valid = False
    return fragment


fn parse_repeat(
    pattern: InlineArray[Int64, MAX_PATTERN_LENGTH], length: Int,
    mut position: Int, mut valid: Bool, mut nfa: Nfa,
) -> Fragment:
    var fragment = parse_atom(pattern, length, position, valid, nfa)
    if not valid:
        return invalid_fragment()
    if position < length and pattern[position] == 42:
        position += 1
        fragment = make_star(nfa, fragment)
        if fragment.start < 0:
            valid = False
    return fragment


fn parse_atom(
    pattern: InlineArray[Int64, MAX_PATTERN_LENGTH], length: Int,
    mut position: Int, mut valid: Bool, mut nfa: Nfa,
) -> Fragment:
    if not valid or position >= length:
        valid = False
        return invalid_fragment()
    let token = pattern[position]
    position += 1
    if token == 97 or token == 98 or token == 99:
        let fragment = make_literal(nfa, token)
        if fragment.start < 0:
            valid = False
        return fragment
    if token == 40:
        let fragment = parse_union(pattern, length, position, valid, nfa)
        if not valid or position >= length or pattern[position] != 41:
            valid = False
            return invalid_fragment()
        position += 1
        return fragment
    valid = False
    return invalid_fragment()


fn can_insert_concat(left: Int64, right: Int64) -> Bool:
    let left_literal = left != 40 and left != 41 and left != 42 and left != 124
    let right_literal = right != 40 and right != 41 and right != 42 and right != 124
    return (
        (left_literal and right_literal) or (left_literal and right == 40)
        or (left == 41 and right == 40) or (left == 41 and right_literal)
        or (left == 42 and right_literal) or (left == 42 and right == 40)
    )


fn source_compatible_slice(
    pattern: InlineArray[Int64, MAX_PATTERN_LENGTH * 2],
    start: Int, end: Int, recursion_depth: Int,
) -> Bool:
    let length = end - start
    if recursion_depth > 64:
        return False
    if length <= 1:
        return True
    if pattern[start] == 40 and pattern[end - 1] == 41:
        var depth = 0
        for index in range(start, end):
            if pattern[index] == 40:
                depth += 1
            elif pattern[index] == 41:
                depth -= 1
            if depth < 0 or (depth == 0 and index < end - 1):
                return False
        if depth != 0:
            return False
        return source_compatible_slice(pattern, start + 1, end - 1, recursion_depth + 1)

    for operator_index in range(2):
        var operator = Int64(124)
        if operator_index == 1:
            operator = 10
        var depth = 0
        for index in range(start, end):
            if depth == 0 and pattern[index] == operator:
                return source_compatible_slice(pattern, start, index, recursion_depth + 1) and source_compatible_slice(pattern, index + 1, end, recursion_depth + 1)
            if pattern[index] == 40:
                depth += 1
            elif pattern[index] == 41:
                depth -= 1

    var depth = 0
    for index in range(start, end - 1):
        if depth == 0 and pattern[index] == 10:
            return source_compatible_slice(pattern, start, index, recursion_depth + 1) and source_compatible_slice(pattern, index + 1, end, recursion_depth + 1)
        if pattern[index] == 40:
            depth += 1
        elif pattern[index] == 41:
            depth -= 1
    if pattern[end - 1] == 42:
        return source_compatible_slice(pattern, start, end - 1, recursion_depth + 1)
    return True


fn source_parser_compatible(
    pattern: InlineArray[Int64, MAX_PATTERN_LENGTH], length: Int,
) -> Bool:
    var processed = InlineArray[Int64, MAX_PATTERN_LENGTH * 2](fill=0)
    var processed_length = 0
    for index in range(length):
        let token = pattern[index]
        processed[processed_length] = token
        processed_length += 1
        if index + 1 < length and can_insert_concat(token, pattern[index + 1]):
            processed[processed_length] = 10
            processed_length += 1
    return source_compatible_slice(processed, 0, processed_length, 0)


fn epsilon_closure(nfa: Nfa, input_states: Int64) -> Int64:
    var states = input_states
    var changed = True
    while changed:
        changed = False
        for edge_index in range(nfa.edge_count):
            let from_bit = Int64(1) << nfa.edge_from[edge_index]
            let to_bit = Int64(1) << nfa.edge_to[edge_index]
            if nfa.edge_label[edge_index] == 0 and (states & from_bit) != 0 and (states & to_bit) == 0:
                states |= to_bit
                changed = True
    return states


@export("mcnaughton_yamada_thompson")
fn mcnaughton_yamada_thompson(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 51:
        return -1
    let pattern_length = input[0]
    let text_length = input[1]
    if pattern_length < 0 or pattern_length > MAX_PATTERN_LENGTH or text_length < 0 or text_length > MAX_TEXT_LENGTH:
        return -1
    if Int(length) != 2 + Int(pattern_length + text_length):
        return -1
    var pattern = InlineArray[Int64, MAX_PATTERN_LENGTH](fill=0)
    var text = InlineArray[Int64, MAX_TEXT_LENGTH](fill=0)
    for index in range(Int(pattern_length)):
        let token = input[2 + index]
        if token != 97 and token != 98 and token != 99 and token != 40 and token != 41 and token != 42 and token != 124:
            return -1
        pattern[index] = token
    for index in range(Int(text_length)):
        let value = input[2 + Int(pattern_length) + index]
        if value < 1 or value > 127:
            return -1
        text[index] = value
    if pattern_length == 0:
        if text_length == 0:
            return 1
        return 0
    if not source_parser_compatible(pattern, Int(pattern_length)):
        return -1

    var nfa = Nfa(
        edge_from=InlineArray[Int64, MAX_NFA_EDGES](fill=0),
        edge_to=InlineArray[Int64, MAX_NFA_EDGES](fill=0),
        edge_label=InlineArray[Int64, MAX_NFA_EDGES](fill=0),
        edge_count=0,
        state_count=0,
    )
    var position = 0
    var valid = True
    let root = parse_union(pattern, Int(pattern_length), position, valid, nfa)
    if not valid or position != Int(pattern_length) or root.start < 0:
        return -1

    var active = epsilon_closure(nfa, Int64(1) << root.start)
    for text_index in range(Int(text_length)):
        var next_states: Int64 = 0
        for edge_index in range(nfa.edge_count):
            if (
                nfa.edge_label[edge_index] != 0
                and nfa.edge_label[edge_index] == text[text_index]
                and (active & (Int64(1) << nfa.edge_from[edge_index])) != 0
            ):
                next_states |= Int64(1) << nfa.edge_to[edge_index]
        active = epsilon_closure(nfa, next_states)
    if (active & (Int64(1) << root.accept)) != 0:
        return 1
    return 0
