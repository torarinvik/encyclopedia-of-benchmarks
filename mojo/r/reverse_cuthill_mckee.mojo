from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_VERTICES = 8
comptime MAX_EDGES = 28
comptime MAX_INPUT_LENGTH = 59

@export("reverse_cuthill_mckee")
fn reverse_cuthill_mckee(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_VERTICES or m_value < 0 or m_value > MAX_EDGES:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if m > n * (n - 1) // 2 or length != c_size_t(2 + 2 * m):
        return -1

    var adjacency = InlineArray[Bool, MAX_VERTICES * MAX_VERTICES](fill=False)
    for edge in range(m):
        let left_value = input[2 + 2 * edge]
        let right_value = input[3 + 2 * edge]
        if left_value < 0 or left_value >= n_value or right_value < 0 or right_value >= n_value or left_value == right_value:
            return -1
        let left = Int(left_value)
        let right = Int(right_value)
        let forward = left * MAX_VERTICES + right
        let backward = right * MAX_VERTICES + left
        if adjacency[forward] or adjacency[backward]:
            return -1
        adjacency[forward] = True
        adjacency[backward] = True

    var degree = InlineArray[Int, MAX_VERTICES](fill=0)
    for vertex in range(n):
        for neighbor in range(n):
            if adjacency[vertex * MAX_VERTICES + neighbor]:
                degree[vertex] += 1

    var visited = InlineArray[Bool, MAX_VERTICES](fill=False)
    var queue = InlineArray[Int, MAX_VERTICES](fill=0)
    var order = InlineArray[Int, MAX_VERTICES](fill=0)
    var order_length = 0
    var visited_count = 0
    while visited_count < n:
        var root = n
        for vertex in range(n):
            if visited[vertex]:
                continue
            if root == n or degree[vertex] < degree[root] or (degree[vertex] == degree[root] and vertex < root):
                root = vertex

        var head = 0
        var tail = 1
        queue[0] = root
        visited[root] = True
        visited_count += 1
        order[order_length] = root
        order_length += 1

        while head < tail:
            let vertex = queue[head]
            head += 1
            var fresh = InlineArray[Int, MAX_VERTICES](fill=0)
            var fresh_count = 0
            for neighbor in range(n):
                if not adjacency[vertex * MAX_VERTICES + neighbor] or visited[neighbor]:
                    continue
                var insert_at = fresh_count
                while insert_at > 0:
                    let previous = fresh[insert_at - 1]
                    if degree[previous] < degree[neighbor] or (degree[previous] == degree[neighbor] and previous < neighbor):
                        break
                    fresh[insert_at] = previous
                    insert_at -= 1
                fresh[insert_at] = neighbor
                fresh_count += 1
            for index in range(fresh_count):
                let neighbor = fresh[index]
                visited[neighbor] = True
                visited_count += 1
                queue[tail] = neighbor
                tail += 1
                order[order_length] = neighbor
                order_length += 1

    var left = 0
    var right = order_length
    while left < right:
        right -= 1
        if left >= right:
            break
        let temporary = order[left]
        order[left] = order[right]
        order[right] = temporary
        left += 1

    var position = InlineArray[Int, MAX_VERTICES](fill=0)
    var rank_word: Int64 = 0
    for rank in range(n):
        let vertex = order[rank]
        position[vertex] = rank
        rank_word = rank_word | (Int64(vertex) << (3 * rank))

    var bandwidth = 0
    for left_vertex in range(n):
        for right_vertex in range(left_vertex + 1, n):
            if adjacency[left_vertex * MAX_VERTICES + right_vertex]:
                let difference = if position[left_vertex] >= position[right_vertex]
                    { position[left_vertex] - position[right_vertex] }
                    else { position[right_vertex] - position[left_vertex] }
                if difference > bandwidth:
                    bandwidth = difference
    return (Int64(bandwidth) << 24) | rank_word
