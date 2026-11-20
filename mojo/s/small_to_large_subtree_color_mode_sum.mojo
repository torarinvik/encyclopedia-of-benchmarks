from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime CELLS = MAX_N * MAX_N

fn stlm_add_color(map: Int, color: Int, amount: Int64,
                  labels: InlineArray[Int64, MAX_N],
                  inout frequencies: InlineArray[Int64, CELLS],
                  inout keys: InlineArray[Int, CELLS],
                  inout lengths: InlineArray[Int, MAX_N],
                  inout maximum: InlineArray[Int64, MAX_N],
                  inout mode_sum: InlineArray[Int64, MAX_N]):
    let cell = map * MAX_N + color
    let old = frequencies[cell]
    if old == 0:
        keys[map * MAX_N + lengths[map]] = color
        lengths[map] += 1
    if old > 0 and old == maximum[map]: mode_sum[map] -= labels[color]
    let updated = old + amount
    if updated > maximum[map]:
        maximum[map] = updated
        mode_sum[map] = labels[color]
    elif updated == maximum[map]:
        mode_sum[map] += labels[color]
    frequencies[cell] = updated

fn stlm_put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("small_to_large_subtree_color_mode_sum")
fn small_to_large_subtree_color_mode_sum(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 129: return -1
    let nv = input[0]
    if nv < 1 or nv > MAX_N or length != c_size_t(2 * nv): return -1
    let n = Int(nv)
    var parent = InlineArray[Int, MAX_N](fill=0)
    for vertex in range(1, n):
        let p = input[vertex]
        if p < 0 or p >= Int64(vertex): return -1
        parent[vertex] = Int(p)
    var sorted = InlineArray[Int64, MAX_N](fill=0)
    for vertex in range(n):
        let color = input[n + vertex]
        if color < -1000 or color > 1000: return -1
        sorted[vertex] = color
    for i in range(1, n):
        let value = sorted[i]
        var j = i
        while j > 0 and sorted[j - 1] > value:
            sorted[j] = sorted[j - 1]
            j -= 1
        sorted[j] = value
    var labels = InlineArray[Int64, MAX_N](fill=0)
    var distinct = 0
    for i in range(n):
        if distinct == 0 or labels[distinct - 1] != sorted[i]:
            labels[distinct] = sorted[i]
            distinct += 1
    var color_index = InlineArray[Int, MAX_N](fill=0)
    for vertex in range(n):
        var index = 0
        while labels[index] != input[n + vertex]: index += 1
        color_index[vertex] = index
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2

    var frequencies = InlineArray[Int64, CELLS](fill=0)
    var keys = InlineArray[Int, CELLS](fill=0)
    var lengths = InlineArray[Int, MAX_N](fill=0)
    var map_id = InlineArray[Int, MAX_N](fill=0)
    var maximum = InlineArray[Int64, MAX_N](fill=0)
    var mode_sum = InlineArray[Int64, MAX_N](fill=0)
    var answers = InlineArray[Int64, MAX_N](fill=0)
    var cursor = n
    while cursor > 0:
        cursor -= 1
        let vertex = cursor
        var largest = n
        for child in range(vertex + 1, n):
            if parent[child] == vertex and (largest == n or lengths[map_id[child]] > lengths[map_id[largest]]):
                largest = child
        let map = largest if largest == n else map_id[largest]
        for child in range(vertex + 1, n):
            if parent[child] != vertex or child == largest: continue
            let small = map_id[child]
            for i in range(lengths[small]):
                let color = keys[small * MAX_N + i]
                let amount = frequencies[small * MAX_N + color]
                stlm_add_color(map, color, amount, labels, frequencies, keys, lengths, maximum, mode_sum)
        stlm_add_color(map, color_index[vertex], 1, labels, frequencies, keys, lengths, maximum, mode_sum)
        map_id[vertex] = map
        answers[vertex] = mode_sum[map]
    for vertex in range(n): stlm_put_word(output, vertex * 8, answers[vertex])
    return Int64(8 * n)
