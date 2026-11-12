from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn tdw2_put(value: Int64, inout output: InlineArray[UInt8, 1592], offset: Int):
    var bits: UInt64 = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits = bits >> 8

@export("tree_decomposition_width_2")
fn tree_decomposition_width_2(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 131: return -1
    let n_arg = input[0]
    let m_arg = input[1]
    if n_arg < 1 or n_arg > 32 or m_arg < 0 or m_arg > 64: return -1
    let n = Int(n_arg)
    let m = Int(m_arg)
    if m > n * (n - 1) // 2 or length != c_size_t(2 + 2 * m): return -1

    var adjacent = InlineArray[Bool, 1024]()
    for edge in range(m):
        let left_arg = input[2 + 2 * edge]
        let right_arg = input[3 + 2 * edge]
        if left_arg < 0 or left_arg >= right_arg or right_arg >= n_arg: return -1
        let left = Int(left_arg)
        let right = Int(right_arg)
        if adjacent[left * 32 + right]: return -1
        adjacent[left * 32 + right] = True
        adjacent[right * 32 + left] = True

    var active = InlineArray[Bool, 32]()
    var order = InlineArray[Int, 32]()
    var bags = InlineArray[Int64, 96]()
    var bag_sizes = InlineArray[Int, 32]()
    var later = InlineArray[Int, 64]()
    var later_counts = InlineArray[Int, 32]()
    var position = InlineArray[Int, 32]()
    for vertex in range(n): active[vertex] = True

    for step in range(n):
        var chosen = -1
        var neighbors = InlineArray[Int, 2]()
        var count = 0
        for vertex in range(n):
            if not active[vertex]: continue
            var degree = 0
            for other in range(n):
                if active[other] and adjacent[vertex * 32 + other]: degree += 1
            if degree <= 2:
                chosen = vertex
                for other in range(n):
                    if active[other] and adjacent[vertex * 32 + other]:
                        neighbors[count] = other
                        count += 1
                break
        if chosen < 0: return -1

        order[step] = chosen
        later_counts[step] = count
        bag_sizes[step] = count + 1
        bags[step * 3] = Int64(chosen)
        for index in range(count):
            later[step * 2 + index] = neighbors[index]
            bags[step * 3 + index + 1] = Int64(neighbors[index])
        for i in range(count + 1):
            for j in range(i + 1, count + 1):
                if bags[step * 3 + j] < bags[step * 3 + i]:
                    let temporary = bags[step * 3 + i]
                    bags[step * 3 + i] = bags[step * 3 + j]
                    bags[step * 3 + j] = temporary
        if count == 2:
            adjacent[neighbors[0] * 32 + neighbors[1]] = True
            adjacent[neighbors[1] * 32 + neighbors[0]] = True
        active[chosen] = False

    for step in range(n): position[order[step]] = step
    var parents = InlineArray[Int, 32]()
    for step in range(n):
        parents[step] = n
        if later_counts[step] > 0:
            var selected = later[step * 2]
            if later_counts[step] == 2 and position[later[step * 2 + 1]] < position[selected]:
                selected = later[step * 2 + 1]
            parents[step] = position[selected]

    let bytes = 8 * (6 * n + 7)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes) or bytes > 1592:
        return -2
    var staged = InlineArray[UInt8, 1592]()
    tdw2_put(Int64(n + 1), staged, 0)
    tdw2_put(2, staged, 8)
    tdw2_put(Int64(n), staged, 16)
    var cursor = 24
    for bag in range(n + 1):
        let size = 0 if bag == n else bag_sizes[bag]
        tdw2_put(Int64(size), staged, cursor)
        cursor += 8
        for slot in range(3):
            let value = bags[bag * 3 + slot] if slot < size else Int64(-1)
            tdw2_put(value, staged, cursor)
            cursor += 8
    for child in range(n):
        tdw2_put(Int64(child), staged, cursor)
        tdw2_put(Int64(parents[child]), staged, cursor + 8)
        cursor += 16
    for byte in range(bytes): output[byte] = staged[byte]
    return Int64(bytes)
