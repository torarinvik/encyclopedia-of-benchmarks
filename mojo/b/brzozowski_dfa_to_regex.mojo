from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_STATES = 3
alias MAX_TEXT = 512
alias Text = InlineArray[UInt8, MAX_TEXT]

fn text_len(text: Text) -> Int:
    var length = 0
    while length < MAX_TEXT and text[length] != 0: length += 1
    return length

fn copy_text(inout output: Text, source: Text) -> Bool:
    let length = text_len(source)
    if length >= MAX_TEXT: return False
    for index in range(length + 1): output[index] = source[index]
    return True

fn text_from_symbol(value: UInt8) -> Text:
    var result = Text()
    result[0] = value
    return result

fn text_compare(left: Text, right: Text) -> Int:
    let left_length = text_len(left)
    let right_length = text_len(right)
    let shared = if left_length < right_length then left_length else right_length
    for index in range(shared):
        if left[index] < right[index]: return -1
        if left[index] > right[index]: return 1
    if left_length < right_length: return -1
    if left_length > right_length: return 1
    return 0

fn regex_union(inout output: Text, left: Text, right: Text) -> Bool:
    let left_length = text_len(left)
    let right_length = text_len(right)
    if left_length == 1 and left[0] == UInt8(35): return copy_text(inout output, right)
    if (right_length == 1 and right[0] == UInt8(35)) or text_compare(left, right) == 0:
        return copy_text(inout output, left)
    let left_first = text_compare(left, right) < 0
    let first = if left_first then left else right
    let second = if left_first then right else left
    var temporary = Text()
    var position = 0
    temporary[position] = UInt8(40); position += 1
    for index in range(text_len(first)): temporary[position] = first[index]; position += 1
    temporary[position] = UInt8(124); position += 1
    for index in range(text_len(second)): temporary[position] = second[index]; position += 1
    temporary[position] = UInt8(41)
    return copy_text(inout output, temporary)

fn regex_concat(inout output: Text, left: Text, right: Text) -> Bool:
    let left_length = text_len(left)
    let right_length = text_len(right)
    if (left_length == 1 and left[0] == UInt8(35)) or (right_length == 1 and right[0] == UInt8(35)):
        return copy_text(inout output, text_from_symbol(UInt8(35)))
    if left_length == 1 and left[0] == UInt8(64): return copy_text(inout output, right)
    if right_length == 1 and right[0] == UInt8(64): return copy_text(inout output, left)
    var temporary = Text()
    var position = 0
    temporary[position] = UInt8(40); position += 1
    for index in range(left_length): temporary[position] = left[index]; position += 1
    temporary[position] = UInt8(46); position += 1
    for index in range(right_length): temporary[position] = right[index]; position += 1
    temporary[position] = UInt8(41)
    return copy_text(inout output, temporary)

fn regex_star(inout output: Text, value: Text) -> Bool:
    let length = text_len(value)
    if (length == 1 and value[0] == UInt8(35)) or (length == 1 and value[0] == UInt8(64)):
        return copy_text(inout output, text_from_symbol(UInt8(64)))
    var temporary = Text()
    temporary[0] = UInt8(40)
    for index in range(length): temporary[index + 1] = value[index]
    temporary[length + 1] = UInt8(41)
    temporary[length + 2] = UInt8(42)
    return copy_text(inout output, temporary)

@export("brzozowski_dfa_to_regex")
fn brzozowski_dfa_to_regex(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 10: return -1
    let n_value = input[0]
    let start_value = input[1]
    let accepting = input[2]
    if n_value < 1 or n_value > MAX_STATES or start_value < 0 or start_value >= n_value
        or accepting < 0 or accepting >= (Int64(1) << Int(n_value))
        or length != c_size_t(3 + 2 * n_value): return -1
    let n = Int(n_value)
    let start = Int(start_value)
    var coefficient = InlineArray[InlineArray[Text, MAX_STATES], MAX_STATES](
        fill=InlineArray[Text, MAX_STATES](fill=Text()))
    var constant = InlineArray[Text, MAX_STATES](fill=Text())
    for state in range(n):
        constant[state] = text_from_symbol(
            UInt8(64) if accepting & (Int64(1) << state) != 0 else UInt8(35))
        for target in range(n): coefficient[state][target] = text_from_symbol(UInt8(35))
        for symbol in range(2):
            let next_value = input[3 + 2 * state + symbol]
            if next_value < 0 or next_value >= n_value: return -1
            let next = Int(next_value)
            let label = text_from_symbol(UInt8(48 + symbol))
            let old = coefficient[state][next]
            if not regex_union(inout coefficient[state][next], old, label): return -1

    for pivot in range(n):
        if pivot == start: continue
        var loop = Text()
        if not regex_star(inout loop, coefficient[pivot][pivot]): return -1
        let pivot_row = coefficient[pivot]
        let pivot_constant = constant[pivot]
        var pivot_column = InlineArray[Text, MAX_STATES](fill=Text())
        for state in range(n): pivot_column[state] = coefficient[state][pivot]
        for source in range(n):
            if source == pivot: continue
            var prefix = Text()
            if not regex_concat(inout prefix, pivot_column[source], loop): return -1
            for target in range(n):
                if target == pivot: continue
                var through = Text()
                if not regex_concat(inout through, prefix, pivot_row[target]): return -1
                let old = coefficient[source][target]
                if not regex_union(inout coefficient[source][target], old, through): return -1
            var through_constant = Text()
            if not regex_concat(inout through_constant, prefix, pivot_constant): return -1
            let old_constant = constant[source]
            if not regex_union(inout constant[source], old_constant, through_constant): return -1

    var loop = Text()
    var answer = Text()
    if not regex_star(inout loop, coefficient[start][start])
        or not regex_concat(inout answer, loop, constant[start]): return -1
    let result_length = text_len(answer)
    if result_length > 270: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(result_length): return -2
    for index in range(result_length): output[index] = answer[index]
    return Int64(result_length)
