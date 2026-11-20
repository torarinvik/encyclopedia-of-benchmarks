from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 31
alias MAX_Q = 32
alias MAX_INPUT = 129
alias MAX_BITS = 2 * MAX_N
alias MAX_OUTPUT_WORDS = 4 + MAX_Q

fn dfuds_bit_at(bits: UInt64, position: Int) -> Bool:
    ((bits >> UInt(position - 1)) & UInt64(1)) != 0

fn dfuds_find_close(bits: UInt64, bit_length: Int, start: Int) -> Int:
    var balance = 0
    for position in range(start, bit_length + 1):
        if dfuds_bit_at(bits, position):
            balance += 1
        else:
            balance -= 1
        if balance == 0:
            return position
    return bit_length + 1

fn dfuds_find_open(bits: UInt64, position: Int) -> Int:
    if dfuds_bit_at(bits, position):
        return position
    var balance = 0
    for candidate in range(position, 0, -1):
        if dfuds_bit_at(bits, candidate):
            balance -= 1
        else:
            balance += 1
        if balance == 0:
            return candidate
    return 0

fn dfuds_previous_zero(bits: UInt64, position: Int) -> Int:
    for candidate in range(position - 1, 0, -1):
        if not dfuds_bit_at(bits, candidate):
            return candidate
    return 0

fn dfuds_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin],
                      offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("dfuds_ordered_tree_navigation")
fn dfuds_ordered_tree_navigation(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT:
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + n - 1 + 3 * q):
        return -1

    var parent = InlineArray[Int, MAX_N]()
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
        if opcode == 0 or opcode == 2:
            if argument != 0:
                return -1
        elif opcode == 1:
            if argument < 0 or argument > n_value:
                return -1
        else:
            return -1

    var order = InlineArray[Int, MAX_N]()
    var stack_node = InlineArray[Int, MAX_N]()
    var next_child = InlineArray[Int, MAX_N]()
    var order_count = 1
    var depth = 1
    while depth > 0:
        let frame = depth - 1
        let node = stack_node[frame]
        var child = next_child[frame]
        while child < n and parent[child] != node:
            child += 1
        if child < n:
            next_child[frame] = child + 1
            order[order_count] = child
            order_count += 1
            stack_node[depth] = child
            next_child[depth] = 1
            depth += 1
        else:
            depth -= 1
    if order_count != n:
        return -1

    var descriptor = InlineArray[Int, MAX_N]()
    var position_to_node = InlineArray[Int, MAX_BITS + 2]()
    for position in range(MAX_BITS + 2):
        position_to_node[position] = -1
    var packed: UInt64 = 1
    var bit_length = 1
    for node in range(n):
        var degree = 0
        for child in range(1, n):
            if parent[child] == order[node]:
                degree += 1
        descriptor[node] = bit_length + 1
        position_to_node[descriptor[node]] = node
        for _ in range(degree):
            packed |= UInt64(1) << UInt(bit_length)
            bit_length += 1
        bit_length += 1
    if bit_length != 2 * n:
        return -1

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
        let start = descriptor[node]
        var degree = 0
        while start + degree <= bit_length and dfuds_bit_at(packed, start + degree):
            degree += 1
        var answer: Int64 = -1
        if opcode == 0:
            answer = Int64(degree)
        elif opcode == 1:
            if Int(argument) < degree:
                let target = start + degree - (Int(argument) + 1)
                let child_start = dfuds_find_close(packed, bit_length, target) + 1
                if child_start > MAX_BITS + 1 or position_to_node[child_start] < 0:
                    return -1
                answer = Int64(position_to_node[child_start])
        elif node != 0:
            let matched_open = dfuds_find_open(packed, start - 1)
            let parent_position = dfuds_previous_zero(packed, matched_open) + 1
            if parent_position == 1:
                answer = 0
            elif parent_position <= MAX_BITS + 1 and position_to_node[parent_position] >= 0:
                answer = Int64(position_to_node[parent_position])
            else:
                return -1
        words[4 + index] = answer

    let output_words = 4 + q
    let required = output_words * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    for index in range(output_words):
        dfuds_store_i64_le(output, 8 * index, words[index])
    return Int64(required)
