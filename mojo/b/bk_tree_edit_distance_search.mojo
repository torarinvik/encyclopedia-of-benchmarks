from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_WORDS = 16
alias MAX_QUERIES = 8
alias MAX_WORD_LENGTH = 10

fn valid_word(word: Int64) -> Bool:
    if word < 0:
        return False
    let packed = UInt64(word)
    if packed >> 44 != 0:
        return False
    let word_length = Int((packed >> 40) & 15)
    if word_length > MAX_WORD_LENGTH:
        return False
    for position in range(MAX_WORD_LENGTH):
        let symbol = Int((packed >> (4 * position)) & 15)
        if position < word_length:
            if symbol == 0:
                return False
        elif symbol != 0:
            return False
    return True

fn edit_distance(left: Int64, right: Int64) -> Int:
    let a = UInt64(left)
    let b = UInt64(right)
    let n = Int((a >> 40) & 15)
    let m = Int((b >> 40) & 15)
    var previous = InlineArray[Int, MAX_WORD_LENGTH + 1]()
    var current = InlineArray[Int, MAX_WORD_LENGTH + 1]()
    for j in range(m + 1):
        previous[j] = j
    for i in range(1, n + 1):
        current[0] = i
        let a_symbol = (a >> (4 * (i - 1))) & 15
        for j in range(1, m + 1):
            let b_symbol = (b >> (4 * (j - 1))) & 15
            let deletion = previous[j] + 1
            let insertion = current[j - 1] + 1
            let replacement = previous[j - 1] + (1 if a_symbol != b_symbol else 0)
            current[j] = min(deletion, min(insertion, replacement))
        for j in range(m + 1):
            previous[j] = current[j]
    return previous[m]

@export("bk_tree_edit_distance_search")
fn bk_tree_edit_distance_search(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 28:
        return -1
    let n_value = input[0]
    let q_value = input[1]
    let radius_value = input[2]
    if n_value < 0 or n_value > MAX_WORDS or q_value < 0 or q_value > MAX_QUERIES
            or radius_value < 0 or radius_value > 3
            or length != c_size_t(3 + n_value + q_value):
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    let radius = Int(radius_value)
    for i in range(n + q):
        if not valid_word(input[i + 3]):
            return -1
    for i in range(n):
        for j in range(i):
            if input[i + 3] == input[j + 3]:
                return -1

    var children = InlineArray[Int32, MAX_WORDS * (MAX_WORD_LENGTH + 1)]()
    for i in range(MAX_WORDS * (MAX_WORD_LENGTH + 1)):
        children[i] = -1
    for node in range(1, n):
        var pivot = 0
        while True:
            let edge = edit_distance(input[node + 3], input[pivot + 3])
            let slot = pivot * (MAX_WORD_LENGTH + 1) + edge
            if children[slot] == -1:
                children[slot] = Int32(node)
                break
            pivot = Int(children[slot])

    var result: Int64 = 0
    for query_index in range(q):
        var matches: Int64 = 0
        var index_sum: Int64 = 0
        if n != 0:
            var stack = InlineArray[Int32, MAX_WORDS]()
            var top = 1
            stack[0] = 0
            while top != 0:
                top -= 1
                let node = Int(stack[top])
                let distance = edit_distance(input[3 + n + query_index], input[node + 3])
                if distance <= radius:
                    matches += 1
                    index_sum += Int64(node)
                let low = max(0, distance - radius)
                let high = min(MAX_WORD_LENGTH, distance + radius)
                for edge in range(low, high + 1):
                    let child = children[node * (MAX_WORD_LENGTH + 1) + edge]
                    if child >= 0:
                        stack[top] = child
                        top += 1
        result += Int64(query_index + 1) * (17 * matches + index_sum)
    return result
