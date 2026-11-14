from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("permutation_shortcut_index")
fn permutation_shortcut_index(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 52: return -1
    let count = input[0]
    let stride_value = input[1]
    if count < 1 or count > 16 or stride_value < 1 or stride_value > 16: return -1
    let n = Int(count)
    let stride = Int(stride_value)
    let query_at = 2 + n
    if Int(length) <= query_at: return -1
    let query_count = input[query_at]
    if query_count < 0 or query_count > 16 or length != c_size_t(query_at + 1 + 2 * Int(query_count)): return -1
    var successor = InlineArray[Int, 16](fill=0)
    var seen = InlineArray[Bool, 16](fill=False)
    for i in range(n):
        let value = input[2 + i]
        if value < 1 or value > count: return -1
        let vertex = Int(value - 1)
        if seen[vertex]: return -1
        seen[vertex] = True
        successor[i] = vertex
    for i in range(Int(query_count)):
        let op = input[query_at + 1 + 2 * i]
        let vertex = input[query_at + 2 + 2 * i]
        if (op != 0 and op != 1) or vertex < 1 or vertex > count: return -1
    var visited = InlineArray[Bool, 16](fill=False)
    var back = InlineArray[Int, 16](fill=0)
    var bitmap = 0
    for start in range(n):
        if not visited[start]:
            var cycle = InlineArray[Int, 16](fill=0)
            var cycle_length = 0
            var current = start
            while not visited[current]:
                visited[current] = True
                cycle[cycle_length] = current
                cycle_length += 1
                current = successor[current]
            if cycle_length >= stride:
                var offset = 0
                while offset < cycle_length:
                    let vertex = cycle[offset]
                    bitmap |= 1 << vertex
                    back[vertex] = cycle[(offset + cycle_length - stride) % cycle_length]
                    offset += stride
    var shortcuts = InlineArray[Int, 16](fill=0)
    var marked_count = 0
    for vertex in range(n):
        if (bitmap & (1 << vertex)) != 0:
            shortcuts[marked_count] = back[vertex]
            marked_count += 1
    var answers = InlineArray[Int64, 16](fill=0)
    for i in range(Int(query_count)):
        let op = input[query_at + 1 + 2 * i]
        let target = Int(input[query_at + 2 + 2 * i] - 1)
        var answer = successor[target]
        if op == 1:
            var marker = target
            var steps = 0
            while steps < n and (bitmap & (1 << marker)) == 0:
                marker = successor[marker]
                steps += 1
            var previous = target
            var current = successor[target]
            if (bitmap & (1 << marker)) != 0:
                var rank = 0
                for vertex in range(marker):
                    if (bitmap & (1 << vertex)) != 0: rank += 1
                previous = shortcuts[rank]
                current = successor[previous]
            while current != target:
                previous = current
                current = successor[current]
            answer = previous
        answers[i] = Int64(answer + 1)
    let bytes = 8 * Int(query_count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(Int(query_count)):
        var bits = UInt64(answers[i])
        for byte in range(8):
            output[8 * i + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
