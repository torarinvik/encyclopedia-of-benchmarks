from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

comptime MAX_NODES = 64

fn append_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], index: Int, value: Int64) -> None:
    let bits = UInt64(value)
    for b in range(8): output[index * 8 + b] = UInt8((bits >> (8 * b)) & 255)

@export("binary_tree_traversal")
fn binary_tree_traversal(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 195: return -1
    let order = input[0]; let nv = input[1]; let root = input[2]
    if order < 0 or order > 6 or nv < 0 or nv > MAX_NODES or length != c_size_t(3 + 3 * nv): return -1
    let n = Int(nv)
    if (n == 0 and root != -1) or (n > 0 and (root < 0 or root >= nv)): return -1
    var values = List[Int64](capacity=n); var left = List[Int](capacity=n); var right = List[Int](capacity=n); var parents = List[Int](capacity=n)
    for _ in range(n): values.append(0); left.append(-1); right.append(-1); parents.append(0)
    for i in range(n):
        values[i] = input[3 + 3 * i]
        let l = input[4 + 3 * i]; let r = input[5 + 3 * i]
        if l < -1 or l >= nv or r < -1 or r >= nv or l == i or r == i: return -1
        left[i] = Int(l); right[i] = Int(r)
        if l >= 0: parents[Int(l)] += 1; if parents[Int(l)] > 1: return -1
        if r >= 0: parents[Int(r)] += 1; if parents[Int(r)] > 1: return -1
    if n > 0:
        for i in range(n):
            if parents[i] != (0 if i == Int(root) else 1): return -1
        var seen = List[Bool](capacity=n); for _ in range(n): seen.append(False)
        var stack = List[Int](capacity=n); stack.append(Int(root)); var visited = 0
        while len(stack) > 0:
            let u = stack.pop()
            if seen[u]: return -1
            seen[u] = True; visited += 1
            if left[u] >= 0: stack.append(left[u])
            if right[u] >= 0: stack.append(right[u])
        if visited != n: return -1
    var result = List[Int64](capacity=n)
    if n > 0:
        if order == 0 or order == 2:
            var todo = List[Int](capacity=n); var visited_stack = List[Bool](capacity=n)
            todo.append(Int(root)); visited_stack.append(False)
            while len(todo) > 0:
                let u = todo.pop(); let expanded = visited_stack.pop()
                if expanded: result.append(values[u])
                else:
                    if order == 0: result.append(values[u])
                    else:
                        todo.append(u); visited_stack.append(True)
                    if right[u] >= 0: todo.append(right[u]); visited_stack.append(False)
                    if left[u] >= 0: todo.append(left[u]); visited_stack.append(False)
        elif order == 1 or order == 5:
            var nodes = List[Int](capacity=n); var cur = Int(root)
            while cur >= 0 or len(nodes) > 0:
                while cur >= 0:
                    nodes.append(cur)
                    cur = left[cur] if order == 1 else right[cur]
                cur = nodes.pop(); result.append(values[cur])
                cur = right[cur] if order == 1 else left[cur]
        else:
            var queue = List[Int](capacity=n); queue.append(Int(root)); var head = 0; var level = 0
            while head < len(queue):
                let end = len(queue)
                var level_values = List[Int64](capacity=end - head)
                while head < end:
                    let u = queue[head]; head += 1; level_values.append(values[u])
                    if left[u] >= 0: queue.append(left[u])
                    if right[u] >= 0: queue.append(right[u])
                if order == 4 or (order == 6 and level % 2 == 1):
                    for j in range(len(level_values)): result.append(level_values[len(level_values) - 1 - j])
                else:
                    for j in range(len(level_values)): result.append(level_values[j])
                level += 1
    let required = 8 * len(result)
    if required == 0: return 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    for i in range(len(result)): append_i64_le(output, i, result[i])
    return Int64(required)
