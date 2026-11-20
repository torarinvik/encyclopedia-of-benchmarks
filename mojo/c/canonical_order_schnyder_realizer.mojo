from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 8
comptime MAX_INPUT = 49
comptime MAX_DARTS = 48

@fieldwise_init
struct Embedding:
    var n: Int
    var u: Int
    var v: Int
    var w: Int
    var degree: InlineArray[Int, MAX_N]
    var rotation: InlineArray[Int, MAX_N * MAX_N]
    var adjacent: InlineArray[Bool, MAX_N * MAX_N]

fn next_active(g: Embedding, active: InlineArray[Bool, MAX_N], source: Int, target: Int) -> Int:
    var source_position = -1
    var remaining = 0
    for index in range(g.degree[target]):
        let neighbor = g.rotation[target * MAX_N + index]
        if active[neighbor]:
            remaining += 1
            if neighbor == source:
                source_position = index
    if remaining < 2 or source_position < 0:
        return -1
    for step in range(1, g.degree[target] + 1):
        let neighbor = g.rotation[target * MAX_N + (source_position + step) % g.degree[target]]
        if active[neighbor]:
            return neighbor
    return -1

fn face_cycle(g: Embedding, active: InlineArray[Bool, MAX_N], first: Int, second: Int,
              mut cycle: InlineArray[Int, MAX_DARTS]) -> Int:
    var seen = InlineArray[Bool, MAX_N * MAX_N]()
    var source = first
    var target = second
    var length = 0
    for _ in range(MAX_DARTS):
        if source < 0 or source >= g.n or target < 0 or target >= g.n or not active[source] or not active[target] or
            not g.adjacent[source * MAX_N + target] or seen[source * MAX_N + target]:
            return -1
        seen[source * MAX_N + target] = True
        cycle[length] = source
        length += 1
        let following = next_active(g, active, source, target)
        if following < 0:
            return -1
        source = target
        target = following
        if source == first and target == second:
            return length
    return -1

fn parse_embedding(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int,
                   mut g: Embedding) -> Bool:
    if length < 4 or length > MAX_INPUT:
        return False
    let n_raw = input[0]
    if n_raw < 3 or n_raw > MAX_N:
        return False
    g.n = Int(n_raw)
    let u_raw = input[1]
    let v_raw = input[2]
    let w_raw = input[3]
    if u_raw < 0 or u_raw >= n_raw or v_raw < 0 or v_raw >= n_raw or w_raw < 0 or w_raw >= n_raw or
       u_raw == v_raw or u_raw == w_raw or v_raw == w_raw:
        return False
    g.u = Int(u_raw)
    g.v = Int(v_raw)
    g.w = Int(w_raw)
    var offset = 4
    var degree_sum = 0
    for vertex in range(g.n):
        if offset >= length:
            return False
        let degree_raw = input[offset]
        offset += 1
        if degree_raw < 2 or degree_raw >= n_raw or offset + Int(degree_raw) > length:
            return False
        let degree = Int(degree_raw)
        g.degree[vertex] = degree
        degree_sum += degree
        var row_seen = InlineArray[Bool, MAX_N]()
        for rank in range(degree):
            let raw = input[offset]
            offset += 1
            if raw < 0 or raw >= n_raw or raw == Int64(vertex):
                return False
            let neighbor = Int(raw)
            if row_seen[neighbor]:
                return False
            row_seen[neighbor] = True
            g.rotation[vertex * MAX_N + rank] = neighbor
            g.adjacent[vertex * MAX_N + neighbor] = True
    if offset != length or degree_sum != 6 * g.n - 12:
        return False
    var edge_count = 0
    for a in range(g.n):
        for b in range(g.n):
            if g.adjacent[a * MAX_N + b] != g.adjacent[b * MAX_N + a]:
                return False
            if a < b and g.adjacent[a * MAX_N + b]:
                edge_count += 1
    if edge_count != 3 * g.n - 6:
        return False
    var reached = InlineArray[Bool, MAX_N]()
    var stack = InlineArray[Int, MAX_N]()
    var stack_size = 1
    var reached_count = 0
    reached[0] = True
    while stack_size > 0:
        stack_size -= 1
        let vertex = stack[stack_size]
        reached_count += 1
        for neighbor in range(g.n):
            if g.adjacent[vertex * MAX_N + neighbor] and not reached[neighbor]:
                reached[neighbor] = True
                stack[stack_size] = neighbor
                stack_size += 1
    if reached_count != g.n:
        return False
    var all_active = InlineArray[Bool, MAX_N]()
    for i in range(g.n):
        all_active[i] = True
    var seen_dart = InlineArray[Bool, MAX_N * MAX_N]()
    var face_count = 0
    var visited_darts = 0
    for source in range(g.n):
        for target in range(g.n):
            if not g.adjacent[source * MAX_N + target] or seen_dart[source * MAX_N + target]:
                continue
            var cycle = InlineArray[Int, MAX_DARTS]()
            let face_length = face_cycle(g, all_active, source, target, cycle)
            if face_length != 3:
                return False
            face_count += 1
            for i in range(face_length):
                let a = cycle[i]
                let b = cycle[(i + 1) % face_length]
                if seen_dart[a * MAX_N + b]:
                    return False
                seen_dart[a * MAX_N + b] = True
                visited_darts += 1
    if face_count != 2 * g.n - 4 or visited_darts != 6 * g.n - 12:
        return False
    var outer = InlineArray[Int, MAX_DARTS]()
    return face_cycle(g, all_active, g.u, g.v, outer) == 3 and outer[0] == g.u and outer[1] == g.v and outer[2] == g.w

fn boundary_path(g: Embedding, active: InlineArray[Bool, MAX_N],
                 mut path: InlineArray[Int, MAX_N]) -> Int:
    var cycle = InlineArray[Int, MAX_DARTS]()
    let length = face_cycle(g, active, g.u, g.v, cycle)
    if length < 3:
        return -1
    var count = 1
    path[0] = g.u
    for index in range(length - 1, 1, -1):
        path[count] = cycle[index]
        count += 1
    path[count] = g.v
    return count + 1

fn peel_choice(g: Embedding, path: InlineArray[Int, MAX_N], length: Int) -> Int:
    var chord = InlineArray[Bool, MAX_N * MAX_N]()
    var chord_count = 0
    for left in range(length):
        for right in range(left + 2, length):
            if left == 0 and right == length - 1:
                continue
            if g.adjacent[path[left] * MAX_N + path[right]]:
                chord[left * MAX_N + right] = True
                chord_count += 1
    var eligible = InlineArray[Bool, MAX_N]()
    if chord_count == 0:
        for index in range(1, length - 1):
            eligible[path[index]] = True
    else:
        for left in range(length):
            for right in range(left + 2, length):
                if not chord[left * MAX_N + right]:
                    continue
                var minimal = True
                for a in range(left, right):
                    for b in range(a + 2, right + 1):
                        if chord[a * MAX_N + b] and (a != left or b != right):
                            minimal = False
                if minimal:
                    for index in range(left + 1, right):
                        eligible[path[index]] = True
    for vertex in range(g.n):
        if eligible[vertex]:
            return vertex
    return -1

fn peel_contains(g: Embedding, path: InlineArray[Int, MAX_N], length: Int, candidate: Int) -> Bool:
    var chord = InlineArray[Bool, MAX_N * MAX_N]()
    var chord_count = 0
    for left in range(length):
        for right in range(left + 2, length):
            if left == 0 and right == length - 1:
                continue
            if g.adjacent[path[left] * MAX_N + path[right]]:
                chord[left * MAX_N + right] = True
                chord_count += 1
    var eligible = InlineArray[Bool, MAX_N]()
    if chord_count == 0:
        for index in range(1, length - 1):
            eligible[path[index]] = True
    else:
        for left in range(length):
            for right in range(left + 2, length):
                if not chord[left * MAX_N + right]:
                    continue
                var minimal = True
                for a in range(left, right):
                    for b in range(a + 2, right + 1):
                        if chord[a * MAX_N + b] and (a != left or b != right):
                            minimal = False
                if minimal:
                    for index in range(left + 1, right):
                        eligible[path[index]] = True
    return candidate >= 0 and candidate < g.n and eligible[candidate]

fn write_i64_le(mut output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("canonical_order_schnyder_realizer")
fn canonical_order_schnyder_realizer(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 57:
        return -1
    let n_raw = input[0]
    if n_raw < 3 or n_raw > MAX_N:
        return -1
    let n = Int(n_raw)
    if Int(length) < n + 4:
        return -1
    let graph_length = Int(length) - n
    var g = Embedding(
        n=0,
        u=0,
        v=0,
        w=0,
        degree=InlineArray[Int, MAX_N](fill=0),
        rotation=InlineArray[Int, MAX_N * MAX_N](fill=0),
        adjacent=InlineArray[Bool, MAX_N * MAX_N](fill=False),
    )
    if not parse_embedding(input, graph_length, g) or g.n != n:
        return -1
    var order = InlineArray[Int, MAX_N]()
    var order_seen = InlineArray[Bool, MAX_N]()
    for i in range(n):
        let raw = input[graph_length + i]
        if raw < 0 or raw >= n_raw or order_seen[Int(raw)]:
            return -1
        order[i] = Int(raw)
        order_seen[order[i]] = True
    if order[0] != g.u or order[1] != g.v or order[n - 1] != g.w:
        return -1
    var active = InlineArray[Bool, MAX_N](fill=False)
    for i in range(n):
        active[i] = True
    var path = InlineArray[Int, MAX_N](fill=0)
    if n > 3:
        active[g.w] = False
        var path_length = boundary_path(g, active, path)
        if path_length < 3:
            return -1
        var reverse_index = n - 2
        while reverse_index >= 3:
            let candidate = order[reverse_index]
            if candidate == g.u or candidate == g.v or not active[candidate] or
                not peel_contains(g, path, path_length, candidate):
                return -1
            active[candidate] = False
            path_length = boundary_path(g, active, path)
            if path_length < 3:
                return -1
            if reverse_index == 3:
                break
            reverse_index -= 1
        if path_length != 3 or path[0] != g.u or path[1] != order[2] or path[2] != g.v:
            return -1
    elif order[2] != g.w:
        return -1
    var position = InlineArray[Int, MAX_N](fill=0)
    for i in range(n):
        position[order[i]] = i
    var words = InlineArray[Int64, 1 + 4 * (MAX_N - 3)](fill=0)
    words[0] = Int64(n)
    var count = 1
    for rank in range(2, n - 1):
        let vertex = order[rank]
        var left = -1
        var right = -1
        if rank == 2:
            if not g.adjacent[vertex * MAX_N + g.u] or not g.adjacent[vertex * MAX_N + g.v]:
                return -1
            left = g.u
            right = g.v
        else:
            var prefix = InlineArray[Bool, MAX_N](fill=False)
            for i in range(rank):
                prefix[order[i]] = True
            var boundary = InlineArray[Int, MAX_N](fill=0)
            let boundary_length = boundary_path(g, prefix, boundary)
            if boundary_length < 3:
                return -1
            var ended = False
            var boundary_count = 0
            for i in range(boundary_length):
                if g.adjacent[vertex * MAX_N + boundary[i]]:
                    if ended:
                        return -1
                    if left < 0:
                        left = boundary[i]
                    right = boundary[i]
                    boundary_count += 1
                elif left >= 0:
                    ended = True
            var predecessor_count = 0
            for i in range(rank):
                if g.adjacent[vertex * MAX_N + order[i]]:
                    predecessor_count += 1
            if boundary_count < 2 or boundary_count != predecessor_count:
                return -1
        var successor = -1
        for other in range(n):
            if position[other] > rank and g.adjacent[vertex * MAX_N + other] and
                (successor < 0 or position[other] > position[successor]):
                successor = other
        if successor < 0:
            return -1
        words[count] = Int64(vertex)
        words[count + 1] = Int64(left)
        words[count + 2] = Int64(right)
        words[count + 3] = Int64(successor)
        count += 4
    let required = 8 * count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    for index in range(count):
        write_i64_le(output, 8 * index, words[index])
    return Int64(required)
