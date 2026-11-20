from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_NODES = 32
alias MAX_QUERIES = 32
alias MAX_INPUT_WORDS = 130
alias MAX_OUTPUT_WORDS = 4 + MAX_QUERIES

fn lo_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("louds_ordered_tree_navigation")
fn louds_ordered_tree_navigation(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_WORDS:
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_NODES or q_value < 0 or q_value > MAX_QUERIES:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + (n - 1) + 3 * q):
        return -1

    var parent = InlineArray[Int, MAX_NODES]()
    for vertex in range(1, n):
        let value = input[1 + vertex]
        if value < 0 or value >= vertex:
            return -1
        parent[vertex] = Int(value)

    let query_base = n + 1
    for index in range(q):
        let offset = query_base + 3 * index
        let opcode = input[offset]
        let node = input[offset + 1]
        let argument = input[offset + 2]
        if node < 0 or node >= n_value:
            return -1
        if opcode == 0 or opcode == 1:
            if argument != 0:
                return -1
        elif opcode == 2:
            if argument < 0 or argument > n_value:
                return -1
        else:
            return -1

    var order = InlineArray[Int, MAX_NODES]()
    var order_count = 1
    var cursor = 0
    while cursor < order_count:
        let vertex = order[cursor]
        for child in range(1, n):
            if parent[child] == vertex:
                order[order_count] = child
                order_count += 1
        cursor += 1
    if order_count != n:
        return -1

    var degree = InlineArray[Int, MAX_NODES]()
    for node in range(n):
        for child in range(1, n):
            if parent[child] == order[node]:
                degree[node] += 1

    var packed: UInt64 = 0
    var bit_length = 0
    for node in range(n):
        for child in range(degree[node]):
            packed |= UInt64(1) << UInt(bit_length)
            bit_length += 1
        bit_length += 1

    var decoded = InlineArray[Int, MAX_NODES]()
    var rank_prefix = InlineArray[Int, MAX_NODES + 1]()
    var bit_position = 0
    var previous_zero = -1
    for node in range(n):
        while bit_position < bit_length and ((packed >> UInt(bit_position)) & 1) != 0:
            bit_position += 1
        decoded[node] = bit_position - previous_zero - 1
        previous_zero = bit_position
        bit_position += 1
        rank_prefix[node + 1] = rank_prefix[node] + decoded[node]

    var words = InlineArray[Int64, MAX_OUTPUT_WORDS]()
    words[0] = n_value
    words[1] = Int64(bit_length)
    words[2] = Int64(packed)
    words[3] = q_value
    for index in range(q):
        let offset = query_base + 3 * index
        let opcode = input[offset]
        let node = Int(input[offset + 1])
        let argument = input[offset + 2]
        var answer: Int64 = -1
        if opcode == 0:
            answer = Int64(decoded[node])
        elif opcode == 1:
            if node != 0:
                for candidate in range(n):
                    if rank_prefix[candidate + 1] >= node:
                        answer = Int64(candidate)
                        break
        elif Int(argument) < decoded[node]:
            answer = Int64(1 + rank_prefix[node] + Int(argument))
        words[4 + index] = answer

    let output_words = 4 + q
    let required = output_words * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    for index in range(output_words):
        lo_store_i64_le(output, 8 * index, words[index])
    return Int64(required)
