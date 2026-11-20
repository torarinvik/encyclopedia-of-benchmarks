from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 8
alias MAX_VERTICES = 2 * MAX_N + 2
alias MAX_CYCLES = MAX_N + 1
alias MAX_INPUT = MAX_N + 2
alias MAX_OUTPUT_WORDS = 1 + 3 * MAX_CYCLES
alias MAX_OUTPUT = 8 * MAX_OUTPUT_WORDS

fn sofc_store(inout bytes: InlineArray[UInt8, MAX_OUTPUT], word: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        bytes[word * 8 + byte] = UInt8(bits & 255)
        bits >>= 8

@export("signed_permutation_overlap_forest_components")
fn signed_permutation_overlap_forest_components(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT:
        return -1
    let n64 = input[0]
    if n64 < 1 or n64 > MAX_N or length != c_size_t(n64 + 1): return -1
    let n = Int(n64)
    let vertex_count = 2 * n + 2
    var pi = InlineArray[Int, MAX_VERTICES](fill=0)
    pi[vertex_count - 1] = vertex_count - 1
    var seen = UInt16(0)
    for position in range(n):
        let gene = input[position + 1]
        if gene == 0 or gene < -n64 or gene > n64: return -1
        var absolute = gene
        if absolute < 0: absolute = -absolute
        let absolute_value = Int(absolute)
        let bit = UInt16(1 << (absolute_value - 1))
        if (seen & bit) != 0: return -1
        seen |= bit
        var left = 2 * absolute_value - 1
        var right = 2 * absolute_value
        if gene < 0:
            let temporary = left
            left = right
            right = temporary
        pi[2 * position + 1] = left
        pi[2 * position + 2] = right
    var gray = InlineArray[Int, MAX_VERTICES](fill=0)
    for pair in range(n + 1):
        let left = pi[2 * pair]
        let right = pi[2 * pair + 1]
        gray[left] = right
        gray[right] = left
    var cycle_of = InlineArray[Int, MAX_VERTICES](fill=-1)
    var begin = InlineArray[Int, MAX_CYCLES](fill=0)
    var end = InlineArray[Int, MAX_CYCLES](fill=0)
    var cycle_count = 0
    for seed in range(vertex_count):
        if cycle_of[seed] >= 0: continue
        let cid = cycle_count
        cycle_count += 1
        var vertex = seed
        var low = seed
        var high = seed
        while cycle_of[vertex] < 0:
            cycle_of[vertex] = cid
            low = min(low, vertex)
            high = max(high, vertex)
            vertex = gray[vertex ^ 1]
        begin[cid] = low
        end[cid] = high

    var parent = InlineArray[Int, MAX_CYCLES](fill=0)
    for cid in range(cycle_count): parent[cid] = cid
    var stack_id = InlineArray[Int, MAX_CYCLES](fill=0)
    var stack_begin = InlineArray[Int, MAX_CYCLES](fill=0)
    var stack_end = InlineArray[Int, MAX_CYCLES](fill=0)
    var top = 0
    for vertex in range(vertex_count):
        let cid = cycle_of[vertex]
        let low = begin[cid]
        let high = end[cid]
        if vertex == low:
            stack_id[top] = cid
            stack_begin[top] = low
            stack_end[top] = high
            top += 1
        var extent_begin = low
        var extent_end = high
        while top > 0 and stack_begin[top - 1] > low:
            top -= 1
            let popped = stack_id[top]
            extent_begin = min(extent_begin, stack_begin[top])
            extent_end = max(extent_end, stack_end[top])
            parent[popped] = cid
        if top == 0: return -1
        stack_begin[top - 1] = min(stack_begin[top - 1], extent_begin)
        stack_end[top - 1] = max(stack_end[top - 1], extent_end)
        if vertex == stack_end[top - 1]: top -= 1

    var component = InlineArray[Int, MAX_CYCLES](fill=0)
    for cid in range(cycle_count):
        component[cid] = begin[cid] if parent[cid] == cid else component[parent[cid]]
    var words = InlineArray[Int64, MAX_OUTPUT_WORDS](fill=0)
    words[0] = Int64(cycle_count)
    for cid in range(cycle_count):
        words[1 + 3 * cid] = Int64(begin[cid])
        words[2 + 3 * cid] = Int64(end[cid])
        words[3 + 3 * cid] = Int64(component[cid])
    let output_bytes = (1 + 3 * cycle_count) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    var staged = InlineArray[UInt8, MAX_OUTPUT](fill=0)
    for word in range(1 + 3 * cycle_count): sofc_store(staged, word, words[word])
    for byte in range(output_bytes): output[byte] = staged[byte]
    return Int64(output_bytes)
