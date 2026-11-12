from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 64
alias MAX_M = MAX_N * (MAX_N - 1) // 2
alias MAX_INPUT_VALUES = 2 + 2 * MAX_M
alias MAX_OUTPUT_VALUES = 1 + 2 * MAX_N

fn ccocg_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("connected_components_of_complement_graph")
fn connected_components_of_complement_graph(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_VALUES:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_N or m_value < 0:
        return -1
    if m_value > n_value * (n_value - 1) // 2:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + 2 * m):
        return -1

    var graph = InlineArray[UInt64, MAX_N]()
    for edge in range(m):
        let left_value = input[2 + 2 * edge]
        let right_value = input[3 + 2 * edge]
        if left_value < 0 or left_value >= n_value or right_value < 0 or
            right_value >= n_value or left_value == right_value:
            return -1
        let left = Int(left_value)
        let right = Int(right_value)
        let bit = UInt64(1) << UInt(right)
        if (graph[left] & bit) != 0:
            return -1
        graph[left] |= bit
        graph[right] |= UInt64(1) << UInt(left)

    var remaining = InlineArray[Int, MAX_N]()
    var queue = InlineArray[Int, MAX_N]()
    var label = InlineArray[Int, MAX_N]()
    for vertex in range(n):
        remaining[vertex] = vertex
        label[vertex] = -1
    var remaining_count = n
    var component_count = 0
    while remaining_count > 0:
        remaining_count -= 1
        let root = remaining[remaining_count]
        label[root] = component_count
        var head = 0
        var tail = 1
        queue[0] = root
        while head < tail:
            let current = queue[head]
            head += 1
            var position = 0
            while position < remaining_count:
                let candidate = remaining[position]
                if ((graph[current] >> UInt(candidate)) & 1) != 0:
                    position += 1
                else:
                    remaining_count -= 1
                    remaining[position] = remaining[remaining_count]
                    label[candidate] = component_count
                    queue[tail] = candidate
                    tail += 1
        component_count += 1

    var staged = InlineArray[Int64, MAX_OUTPUT_VALUES]()
    var used = 0
    staged[used] = Int64(component_count)
    used += 1
    var emitted = InlineArray[Bool, MAX_N]()
    for first in range(n):
        let component = label[first]
        if emitted[component]:
            continue
        emitted[component] = True
        var component_size = 0
        for vertex in range(n):
            if label[vertex] == component:
                component_size += 1
        staged[used] = Int64(component_size)
        used += 1
        for vertex in range(n):
            if label[vertex] == component:
                staged[used] = Int64(vertex)
                used += 1

    let required = 8 * used
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    for index in range(used):
        ccocg_store_i64_le(output, 8 * index, staged[index])
    return Int64(required)
