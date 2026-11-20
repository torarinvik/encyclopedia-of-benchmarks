from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 31
alias MAX_Q = 32
alias MAX_INPUT = 129
alias MAX_BITS = 2 * MAX_N
alias MAX_OUTPUT_WORDS = 4 + MAX_Q

fn bp_write_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("bp_ordered_tree_navigation")
fn bp_ordered_tree_navigation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT:
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    let bit_length = 2 * n
    if length != c_size_t(2 + (n - 1) + 3 * q):
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
        let first = input[offset + 1]
        let second = input[offset + 2]
        if opcode == 0 or opcode == 1:
            if first < 0 or first > bit_length or second < -bit_length or second > bit_length:
                return -1
        elif opcode == 2:
            if first < 0 or second < first or second >= bit_length:
                return -1
        elif opcode == 3 or opcode == 4 or opcode == 5:
            if first < 0 or first >= bit_length or second != 0:
                return -1
        else:
            return -1

    var bits = InlineArray[Int, MAX_BITS]()
    var stack_node = InlineArray[Int, MAX_N + 1]()
    var next_child = InlineArray[Int, MAX_N + 1]()
    var bit_count = 0
    var depth = 1
    bits[bit_count] = 1
    bit_count += 1
    next_child[0] = 1
    while depth > 0:
        let frame = depth - 1
        let node = stack_node[frame]
        var child = next_child[frame]
        while child < n and parent[child] != node:
            child += 1
        if child < n:
            next_child[frame] = child + 1
            bits[bit_count] = 1
            bit_count += 1
            stack_node[depth] = child
            next_child[depth] = 1
            depth += 1
        else:
            bits[bit_count] = 0
            bit_count += 1
            depth -= 1
    if bit_count != bit_length:
        return -1

    var excess = InlineArray[Int64, MAX_BITS + 1]()
    var packed: UInt64 = 0
    for position in range(bit_length):
        if bits[position] != 0:
            packed |= UInt64(1) << UInt(position)
            excess[position + 1] = excess[position] + 1
        else:
            excess[position + 1] = excess[position] - 1
    for index in range(q):
        let offset = query_base + 3 * index
        let opcode = input[offset]
        let first = Int(input[offset + 1])
        if opcode == 3 and bits[first] == 0:
            return -1
        if opcode == 4 and bits[first] != 0:
            return -1
        if opcode == 5 and bits[first] == 0:
            return -1

    var words = InlineArray[Int64, MAX_OUTPUT_WORDS]()
    words[0] = n_value
    words[1] = Int64(bit_length)
    words[2] = Int64(packed)
    words[3] = q_value
    for index in range(q):
        let offset = query_base + 3 * index
        let opcode = input[offset]
        let first = Int(input[offset + 1])
        let second = input[offset + 2]
        var answer: Int64 = -1
        if opcode == 0 or opcode == 1:
            let target = excess[first] + second
            if opcode == 0:
                answer = Int64(bit_length + 1)
                for position in range(first + 1, bit_length + 1):
                    if excess[position] == target:
                        answer = Int64(position)
                        break
            else:
                var position = first
                answer = 0
                while position > 0:
                    position -= 1
                    if excess[position] == target:
                        answer = Int64(position)
                        break
        elif opcode == 2:
            let right = Int(second)
            var best = first
            for position in range(first + 1, right + 1):
                if excess[position + 1] < excess[best + 1]:
                    best = position
            answer = Int64(best)
        elif opcode == 3:
            let target = excess[first + 1] - 1
            for position in range(first + 2, bit_length + 1):
                if excess[position] == target:
                    answer = Int64(position - 1)
                    break
        elif opcode == 4:
            let target = excess[first + 1]
            var position = first + 1
            while position > 0:
                position -= 1
                if excess[position] == target:
                    answer = Int64(position)
                    break
        elif first == 0:
            answer = -1
        else:
            let target = excess[first + 1] - 2
            var position = first + 1
            while position > 0:
                position -= 1
                if excess[position] == target:
                    answer = Int64(position)
                    break
        words[4 + index] = answer

    let output_words = 4 + q
    let required = 8 * output_words
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    for index in range(output_words):
        bp_write_i64_le(output, 8 * index, words[index])
    return Int64(required)
