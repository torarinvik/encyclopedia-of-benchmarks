from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_QUERIES = 32
alias MAX_NODES = MAX_QUERIES + 2
alias ALPHABET = 26
alias TRANSITION_COUNT = MAX_NODES * ALPHABET

fn pid_store_i64_le(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64
) -> None:
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("palindromes_in_deque")
fn palindromes_in_deque(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65:
        return -1
    let query_value = input[0]
    if query_value < 1 or query_value > MAX_QUERIES:
        return -1
    let queries = Int(query_value)
    if length != c_size_t(1 + 2 * queries):
        return -1

    var size = 0
    for query in range(queries):
        let operation = input[1 + 2 * query]
        let letter = input[2 + 2 * query]
        if operation == 0 or operation == 1:
            if letter < 0 or letter >= Int64(ALPHABET):
                return -1
            size += 1
        elif operation == 2 or operation == 3:
            if letter != 0 or size == 0:
                return -1
            size -= 1
        else:
            return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(24 * queries):
        return -2

    var text = InlineArray[Int, MAX_QUERIES](fill=0)
    size = 0
    for query in range(queries):
        let operation = Int(input[1 + 2 * query])
        let letter = Int(input[2 + 2 * query])
        if operation == 0:
            for index in range(size, 0, -1):
                text[index] = text[index - 1]
            text[0] = letter
            size += 1
        elif operation == 1:
            text[size] = letter
            size += 1
        elif operation == 2:
            for index in range(1, size):
                text[index - 1] = text[index]
            size -= 1
        else:
            size -= 1

        var node_length = InlineArray[Int, MAX_NODES](fill=0)
        var suffix_link = InlineArray[Int, MAX_NODES](fill=0)
        var next = InlineArray[Int, TRANSITION_COUNT](fill=-1)
        node_length[0] = -1
        var node_count = 2
        var last = 1
        var longest_prefix = 0
        for position in range(size):
            let character = Int(text[position])
            var parent = last
            while True:
                let preceding = position - node_length[parent] - 1
                if preceding >= 0 and text[preceding] == text[position]:
                    break
                parent = suffix_link[parent]
            var child = next[parent * ALPHABET + character]
            if child < 0:
                child = node_count
                node_count += 1
                node_length[child] = node_length[parent] + 2
                if node_length[child] == 1:
                    suffix_link[child] = 1
                else:
                    var suffix_parent = suffix_link[parent]
                    while True:
                        let preceding = position - node_length[suffix_parent] - 1
                        if preceding >= 0 and text[preceding] == text[position]:
                            break
                        suffix_parent = suffix_link[suffix_parent]
                    suffix_link[child] = next[suffix_parent * ALPHABET + character]
                next[parent * ALPHABET + character] = child
            last = Int(child)
            if node_length[last] == position + 1:
                longest_prefix = position + 1

        let offset = 24 * query
        pid_store_i64_le(output, offset, Int64(node_count - 2))
        pid_store_i64_le(output, offset + 8, Int64(longest_prefix))
        pid_store_i64_le(output, offset + 16, Int64(node_length[last]))
    return Int64(24 * queries)
