# Clean-room McCreight radix priority-search-tree profile.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("priority_search_tree_three_sided_reporting")
fn priority_search_tree_three_sided_reporting(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 48: return -1
    let n64 = input[0]
    let q64 = input[1]
    if n64 < 0 or n64 > 8 or q64 < 0 or q64 > 7 or length != c_size_t(2 + 3 * n64 + 3 * q64): return -1
    let n = Int(n64)
    let q = Int(q64)
    var nx = List[Int64](capacity=8)
    var ny = List[Int64](capacity=8)
    var nl = List[Int64](capacity=8)
    var nlo = List[Int64](capacity=8)
    var nhi = List[Int64](capacity=8)
    var left = List[Int](capacity=8)
    var right = List[Int](capacity=8)
    var seen_x = List[Bool](capacity=32)
    var seen_label = List[Bool](capacity=8)
    for _ in range(8):
        nx.append(0); ny.append(0); nl.append(0); nlo.append(0); nhi.append(0)
        left.append(-1); right.append(-1); seen_label.append(False)
    for _ in range(32): seen_x.append(False)
    var root = -1
    var count = 0
    var at = 2
    for _ in range(n):
        let x = input[at]
        let y = input[at + 1]
        let label = input[at + 2]
        at += 3
        if x < 0 or x >= 32 or y < -64 or y > 63 or label < 0 or label >= 8: return -1
        if seen_x[Int(x)] or seen_label[Int(label)]: return -1
        seen_x[Int(x)] = True; seen_label[Int(label)] = True
        var px = x
        var py = y
        var plabel = label
        if root < 0:
            root = count
            count += 1
            nx[root] = px; ny[root] = py; nl[root] = plabel
            nlo[root] = 0; nhi[root] = 32
        else:
            var current = root
            var low = 0
            var high = 32
            var searching = True
            while searching:
                if py < ny[current]:
                    let tx = nx[current]; nx[current] = px; px = tx
                    let ty = ny[current]; ny[current] = py; py = ty
                    let tl = nl[current]; nl[current] = plabel; plabel = tl
                let middle = (low + high) // 2
                if px < middle:
                    if left[current] < 0:
                        let child = count
                        count += 1
                        left[current] = child
                        nx[child] = px; ny[child] = py; nl[child] = plabel
                        nlo[child] = low; nhi[child] = middle
                        searching = False
                    else:
                        current = left[current]; high = middle
                else:
                    if right[current] < 0:
                        let child = count
                        count += 1
                        right[current] = child
                        nx[child] = px; ny[child] = py; nl[child] = plabel
                        nlo[child] = middle; nhi[child] = high
                        searching = False
                    else:
                        current = right[current]; low = middle
    var qx0 = List[Int64](capacity=7)
    var qx1 = List[Int64](capacity=7)
    var qy1 = List[Int64](capacity=7)
    for _ in range(7): qx0.append(0); qx1.append(0); qy1.append(0)
    for i in range(q):
        let x0 = input[at]
        let x1 = input[at + 1]
        let y1 = input[at + 2]
        at += 3
        if x0 < 0 or x0 > x1 or x1 >= 32 or y1 < -64 or y1 > 63: return -1
        qx0[i] = x0; qx1[i] = x1; qy1[i] = y1
    var result = Int64(0)
    for qi in range(q):
        var mask = Int64(0)
        if root >= 0:
            var stack = List[Int](capacity=8)
            for _ in range(8): stack.append(-1)
            var top = 1
            stack[0] = root
            while top > 0:
                top -= 1
                let node = stack[top]
                if qx1[qi] < nlo[node] or qx0[qi] >= nhi[node] or ny[node] > qy1[qi]: continue
                if qx0[qi] <= nx[node] and nx[node] <= qx1[qi]: mask |= Int64(1) << Int(nl[node])
                if left[node] >= 0: stack[top] = left[node]; top += 1
                if right[node] >= 0: stack[top] = right[node]; top += 1
        result |= mask << (8 * qi)
    return result
