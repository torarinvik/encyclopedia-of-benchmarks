from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const MAX_STRINGS = 8
const MAX_TOTAL_BYTES = 24
const MAX_TRIE_NODES = 25
const MAX_STATES = 2 * MAX_TRIE_NODES - 1
const ALPHABET = 4
const MAX_INPUT_LENGTH = 34

@export("generalized_suffix_automaton_union")
fn generalized_suffix_automaton_union(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 1 or n > c_size_t(MAX_INPUT_LENGTH): return -1
    if v[0] < 2 or v[0] > MAX_STRINGS: return -1
    let string_count = Int(v[0])

    var state_length = InlineArray[Int64, MAX_STATES](fill=0)
    var state_link = InlineArray[Int64, MAX_STATES](fill= -1)
    var transitions = InlineArray[Int64, MAX_STATES * ALPHABET](fill=0)
    var trie_next = InlineArray[Int, MAX_TRIE_NODES * ALPHABET](fill=0)
    var trie_parent = InlineArray[Int, MAX_TRIE_NODES](fill=0)
    var trie_symbol = InlineArray[Int, MAX_TRIE_NODES](fill=0)

    var trie_node_count = 1
    var total_bytes = 0
    var cursor = 1
    for string_index in range(string_count):
        if cursor >= Int(n): return -1
        let string_length_value = v[cursor]
        cursor += 1
        if string_length_value < 0 or string_length_value > 8: return -1
        let string_length = Int(string_length_value)
        if total_bytes + string_length > MAX_TOTAL_BYTES or string_length > Int(n) - cursor: return -1
        total_bytes += string_length

        var node = 0
        for offset in range(string_length):
            let symbol_value = v[cursor + offset]
            if symbol_value < 0 or symbol_value >= ALPHABET: return -1
            let symbol = Int(symbol_value)
            let trie_index = node * ALPHABET + symbol
            var child = trie_next[trie_index]
            if child == 0:
                child = trie_node_count
                trie_node_count += 1
                trie_next[trie_index] = child
                transitions[trie_index] = child
                trie_parent[child] = node
                trie_symbol[child] = symbol
            node = child
        cursor += string_length
    if cursor != Int(n): return -1

    var state_count = trie_node_count
    var queue = InlineArray[Int, MAX_TRIE_NODES](fill=0)
    var queue_head = 0
    var queue_tail = 0
    for symbol in range(ALPHABET):
        let child = trie_next[symbol]
        if child != 0:
            queue[queue_tail] = child
            queue_tail += 1

    while queue_head < queue_tail:
        let current = queue[queue_head]
        queue_head += 1
        let parent = trie_parent[current]
        let symbol = trie_symbol[current]
        state_length[current] = state_length[parent] + 1

        var previous = Int(state_link[parent])
        while previous != -1 and transitions[previous * ALPHABET + symbol] == 0:
            transitions[previous * ALPHABET + symbol] = current
            previous = Int(state_link[previous])
        if previous == -1:
            state_link[current] = 0
        else:
            let next_state = Int(transitions[previous * ALPHABET + symbol])
            if state_length[previous] + 1 == state_length[next_state]:
                state_link[current] = next_state
            else:
                if state_count >= MAX_STATES: return -1
                let clone = state_count
                state_count += 1
                state_length[clone] = state_length[previous] + 1
                state_link[clone] = state_link[next_state]
                for character in range(ALPHABET):
                    let destination = Int(transitions[next_state * ALPHABET + character])
                    if destination != 0 and state_length[destination] > 0:
                        transitions[clone * ALPHABET + character] = destination
                while previous != -1 and transitions[previous * ALPHABET + symbol] == next_state:
                    transitions[previous * ALPHABET + symbol] = clone
                    previous = Int(state_link[previous])
                state_link[current] = clone
                state_link[next_state] = clone

        for character in range(ALPHABET):
            let child = trie_next[current * ALPHABET + character]
            if child != 0:
                queue[queue_tail] = child
                queue_tail += 1

    var distinct_count: Int64 = 0
    for state in range(1, state_count):
        let link = Int(state_link[state])
        distinct_count += state_length[state] - state_length[link]
    return distinct_count
