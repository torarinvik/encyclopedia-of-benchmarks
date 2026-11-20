from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_NONTERMINALS = 4
comptime MAX_TERMINALS = 2
comptime MAX_WORD_LENGTH = 8
comptime MAX_PRODUCTIONS = 12
comptime MAX_INPUT_LENGTH = 62

@export("cyk_context_free_recognition")
fn cyk_context_free_recognition(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let variables_value = input[0]
    let alphabet_value = input[1]
    let word_value = input[2]
    let rule_value = input[3]
    let start_value = input[4]
    if variables_value < 1 or variables_value > MAX_NONTERMINALS or
        alphabet_value < 1 or alphabet_value > MAX_TERMINALS or
        word_value < 1 or word_value > MAX_WORD_LENGTH or
        rule_value < 0 or rule_value > MAX_PRODUCTIONS or
        start_value < 0 or start_value >= variables_value:
        return -1
    let word_length = Int(word_value)
    let rule_count = Int(rule_value)
    if length != c_size_t(5 + word_length + 4 * rule_count):
        return -1
    for position in range(word_length):
        let token = input[5 + position]
        if token < 0 or token >= alphabet_value:
            return -1
    let rules = 5 + word_length
    for rule in range(rule_count):
        let offset = rules + 4 * rule
        let kind = input[offset]
        let lhs = input[offset + 1]
        let first = input[offset + 2]
        let second = input[offset + 3]
        if lhs < 0 or lhs >= variables_value:
            return -1
        if kind == 0:
            if first < 0 or first >= alphabet_value or second != 0:
                return -1
        elif kind == 1:
            if first < 0 or first >= variables_value or second < 0 or second >= variables_value:
                return -1
        else:
            return -1

    var chart = InlineArray[Bool, 288](fill=False)
    for position in range(word_length):
        let token = input[5 + position]
        for rule in range(rule_count):
            let offset = rules + 4 * rule
            if input[offset] == 0 and input[offset + 2] == token:
                let cell = Int(input[offset + 1]) * 72 + position * 9 + 1
                chart[cell] = True
    for width in range(2, word_length + 1):
        for left in range(word_length - width + 1):
            for rule in range(rule_count):
                let offset = rules + 4 * rule
                if input[offset] != 1:
                    continue
                let lhs = Int(input[offset + 1])
                let first = Int(input[offset + 2])
                let second = Int(input[offset + 3])
                for split in range(1, width):
                    let left_cell = first * 72 + left * 9 + split
                    let right_cell = second * 72 + (left + split) * 9 + width - split
                    if chart[left_cell] and chart[right_cell]:
                        chart[lhs * 72 + left * 9 + width] = True
                        break
    if chart[Int(start_value) * 72 + word_length]:
        return 1
    return 0
