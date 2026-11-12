comptime MAX_N = 6
comptime MAX_INPUT = 32
comptime MAX_OUTPUT_VALUES = 8
comptime MAX_OUTPUT_BYTES = 64

fn put_u64(value: UInt64, mut output: InlineArray[UInt8, MAX_OUTPUT_BYTES], index: Int):
    for byte in range(8):
        output[index * 8 + byte] = UInt8((value >> (byte * 8)) & 0xff)

@export("chordal_graph_recognition")
fn chordal_graph_recognition(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_N or m_value < 0 or m_value > 15: return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if m > n * (n - 1) // 2 or length != c_size_t(2 + 2 * m): return -1
    var adjacent = InlineArray[Bool, MAX_N * MAX_N](False)
    for edge in range(m):
        let a_value = input[2 + 2 * edge]
        let b_value = input[3 + 2 * edge]
        if a_value < 0 or b_value < 0 or a_value >= n_value or b_value >= n_value or a_value == b_value: return -1
        let a = Int(a_value)
        let b = Int(b_value)
        if adjacent[a * MAX_N + b]: return -1
        adjacent[a * MAX_N + b] = True
        adjacent[b * MAX_N + a] = True
    var selected = InlineArray[Bool, MAX_N](False)
    var labels = InlineArray[Int, MAX_N](0)
    var reverse_order = InlineArray[Int, MAX_N](0)
    var order = InlineArray[Int, MAX_N](0)
    var position = InlineArray[Int, MAX_N](0)
    for step in range(n):
        var chosen = -1
        for vertex in range(n):
            if not selected[vertex] and (chosen < 0 or labels[vertex] > labels[chosen]): chosen = vertex
        selected[chosen] = True
        reverse_order[step] = chosen
        for other in range(n):
            if not selected[other] and adjacent[chosen * MAX_N + other]: labels[other] += 1
    for i in range(n):
        order[i] = reverse_order[n - i - 1]
        position[order[i]] = i
    var peo = True
    for i in range(n):
        let vertex = order[i]
        var parent = -1
        for other in range(n):
            if adjacent[vertex * MAX_N + other] and position[other] > i and (parent < 0 or position[other] < position[parent]):
                parent = other
        if parent >= 0:
            for other in range(n):
                if adjacent[vertex * MAX_N + other] and position[other] > i and other != parent and not adjacent[parent * MAX_N + other]:
                    peo = False
    var packed = InlineArray[UInt64, MAX_OUTPUT_VALUES](0)
    var packed_count = 0
    if peo:
        packed[packed_count] = 1
        packed_count += 1
        for i in range(n):
            packed[packed_count] = UInt64(order[i])
            packed_count += 1
    else:
        var found = False
        var cycle = InlineArray[Int, MAX_N](0)
        var cycle_length = 0
        for mask in range(1 << n):
            var vertices = InlineArray[Int, MAX_N](0)
            var size = 0
            for vertex in range(n):
                if (mask & (1 << vertex)) != 0:
                    vertices[size] = vertex
                    size += 1
            if size < 4: continue
            var valid = True
            for i in range(size):
                var degree = 0
                for j in range(size):
                    if adjacent[vertices[i] * MAX_N + vertices[j]]: degree += 1
                if degree != 2: valid = False
            if not valid: continue
            var seen = InlineArray[Bool, MAX_N](False)
            var queue = InlineArray[Int, MAX_N](0)
            var head = 0
            var tail = 1
            seen[vertices[0]] = True
            queue[0] = vertices[0]
            while head < tail:
                let vertex = queue[head]
                head += 1
                for j in range(size):
                    let other = vertices[j]
                    if adjacent[vertex * MAX_N + other] and not seen[other]:
                        seen[other] = True
                        queue[tail] = other
                        tail += 1
            if tail != size: continue
            cycle_length = size
            let start = vertices[0]
            var previous = start
            var current = start
            for j in range(size):
                if adjacent[start * MAX_N + vertices[j]]:
                    current = vertices[j]
                    break
            cycle[0] = start
            for i in range(1, size):
                cycle[i] = current
                var next = start
                for j in range(size):
                    let other = vertices[j]
                    if adjacent[current * MAX_N + other] and other != previous:
                        next = other
                        break
                previous = current
                current = next
            found = True
            break
        if not found: return -1
        packed[packed_count] = 0
        packed_count += 1
        packed[packed_count] = UInt64(cycle_length)
        packed_count += 1
        for i in range(cycle_length):
            packed[packed_count] = UInt64(cycle[i])
            packed_count += 1
    let bytes = packed_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var staged = InlineArray[UInt8, MAX_OUTPUT_BYTES](0)
    for i in range(packed_count): put_u64(packed[i], staged, i)
    for byte in range(bytes): output[byte] = staged[byte]
    return Int64(bytes)
