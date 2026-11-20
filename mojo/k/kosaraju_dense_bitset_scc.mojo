from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_VERTICES = 256
const MAX_WORDS = 4
const MAX_CELLS = MAX_VERTICES * MAX_WORDS
const MAX_PARSEABLE_INPUT_LENGTH = 1026

fn lowest_bit_index(bits: UInt64) -> Int:
    var value = bits
    var index = 0
    while (value & UInt64(1)) == UInt64(0):
        value >>= 1
        index += 1
    return index

@export("kosaraju_dense_bitset_scc")
fn kosaraju_dense_bitset_scc(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(MAX_PARSEABLE_INPUT_LENGTH): return -1
    let n_value = input[unsafe_offset=0]
    if n_value < 1 or n_value > MAX_VERTICES: return -1
    let n = Int(n_value)
    let words = (n + 63) // 64
    if length != c_size_t(1 + n * words): return -1

    var adjacency = InlineArray[UInt64, MAX_CELLS](fill=UInt64(0))
    var transpose = InlineArray[UInt64, MAX_CELLS](fill=UInt64(0))
    for cell in range(n * words):
        adjacency[cell] = bitcast[UInt64](input[unsafe_offset=1 + cell])
    if n % 64 != 0:
        let valid = (UInt64(1) << UInt64(n % 64)) - UInt64(1)
        for vertex in range(n):
            if (adjacency[vertex * words + words - 1] & ~valid) != UInt64(0): return -1
    for source in range(n):
        for word in range(words):
            var bits = adjacency[source * words + word]
            while bits != UInt64(0):
                let bit = lowest_bit_index(bits)
                let target = word * 64 + bit
                transpose[target * words + source // 64] |= UInt64(1) << UInt64(source % 64)
                bits &= bits - UInt64(1)

    var unvisited = InlineArray[UInt64, MAX_WORDS](fill=UInt64(0))
    for word in range(words): unvisited[word] = UInt64.max
    if n % 64 != 0: unvisited[words - 1] = (UInt64(1) << UInt64(n % 64)) - UInt64(1)
    var stack = InlineArray[UInt16, MAX_VERTICES](fill=UInt16(0))
    var next_word = InlineArray[UInt16, MAX_VERTICES](fill=UInt16(0))
    var order = InlineArray[UInt16, MAX_VERTICES](fill=UInt16(0))
    var order_length = 0
    for root in range(n):
        let root_word = root // 64
        let root_bit = root % 64
        if ((unvisited[root_word] >> UInt64(root_bit)) & UInt64(1)) == UInt64(0): continue
        unvisited[root_word] &= ~(UInt64(1) << UInt64(root_bit))
        var stack_length = 1
        stack[0] = UInt16(root)
        next_word[0] = UInt16(0)
        while stack_length != 0:
            let depth = stack_length - 1
            let vertex = Int(stack[depth])
            var pushed = False
            while Int(next_word[depth]) < words:
                let word = Int(next_word[depth])
                let candidates = adjacency[vertex * words + word] & unvisited[word]
                if candidates != UInt64(0):
                    let bit = lowest_bit_index(candidates)
                    let neighbor = word * 64 + bit
                    unvisited[word] &= ~(UInt64(1) << UInt64(bit))
                    stack[stack_length] = UInt16(neighbor)
                    next_word[stack_length] = UInt16(0)
                    stack_length += 1
                    pushed = True
                    break
                next_word[depth] = next_word[depth] + UInt16(1)
            if not pushed and Int(next_word[depth]) == words:
                order[order_length] = UInt16(vertex)
                order_length += 1
                stack_length -= 1

    for word in range(words): unvisited[word] = UInt64.max
    if n % 64 != 0: unvisited[words - 1] = (UInt64(1) << UInt64(n % 64)) - UInt64(1)
    var raw_component = InlineArray[UInt16, MAX_VERTICES](fill=UInt16(0))
    var component_count = UInt16(0)
    while order_length != 0:
        order_length -= 1
        let root = Int(order[order_length])
        let root_word = root // 64
        let root_bit = root % 64
        if ((unvisited[root_word] >> UInt64(root_bit)) & UInt64(1)) == UInt64(0): continue
        unvisited[root_word] &= ~(UInt64(1) << UInt64(root_bit))
        var stack_length = 1
        stack[0] = UInt16(root)
        raw_component[root] = component_count
        while stack_length != 0:
            stack_length -= 1
            let vertex = Int(stack[stack_length])
            for word in range(words):
                var candidates = transpose[vertex * words + word] & unvisited[word]
                while candidates != UInt64(0):
                    let bit = lowest_bit_index(candidates)
                    let neighbor = word * 64 + bit
                    let selected = UInt64(1) << UInt64(bit)
                    unvisited[word] &= ~selected
                    candidates &= ~selected
                    raw_component[neighbor] = component_count
                    stack[stack_length] = UInt16(neighbor)
                    stack_length += 1
        component_count += UInt16(1)

    var remap = InlineArray[UInt16, MAX_VERTICES](fill=UInt16(65535))
    var canonical_count = UInt16(0)
    for vertex in range(n):
        let raw = Int(raw_component[vertex])
        if remap[raw] == UInt16(65535):
            remap[raw] = canonical_count
            canonical_count += UInt16(1)
    let output_length = 2 + 2 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_length): return -2
    output[unsafe_offset=0] = UInt8(canonical_count & UInt16(255))
    output[unsafe_offset=1] = UInt8(canonical_count >> UInt16(8))
    for vertex in range(n):
        let label = remap[Int(raw_component[vertex])]
        output[unsafe_offset=2 + 2 * vertex] = UInt8(label & UInt16(255))
        output[unsafe_offset=3 + 2 * vertex] = UInt8(label >> UInt16(8))
    return Int64(output_length)
