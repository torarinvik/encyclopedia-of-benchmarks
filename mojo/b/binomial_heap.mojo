from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn heap_link(mut values: List[Int64], mut child: List[Int], mut sibling: List[Int], mut degree: List[Int], a: Int, b: Int) -> Int:
    var parent = a; var other = b
    if values[a] >= values[b]: parent = b; other = a
    sibling[other] = child[parent]
    child[parent] = other
    degree[parent] += 1
    return parent

fn heap_add_tree(mut roots: List[Int], mut values: List[Int64], mut child: List[Int], mut sibling: List[Int], mut degree: List[Int], start: Int) -> None:
    var node = start; var rank = degree[node]
    while roots[rank] >= 0:
        node = heap_link(values, child, sibling, degree, node, roots[rank])
        roots[rank] = -1; rank += 1
    roots[rank] = node

@export("binomial_heap")
fn binomial_heap(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1: return -1
    let opn = input[0]
    if opn < 0 or opn > 128 or length != c_size_t(1 + 2 * opn): return -1
    var size = 0; var queries = 0
    for i in range(Int(opn)):
        let op = input[1 + 2 * i]; let arg = input[2 + 2 * i]
        if op == 0:
            if arg < -2_147_483_648 or arg > 2_147_483_647: return -1
            size += 1
        elif op >= 1 and op <= 3:
            if arg != 0 or ((op == 1 or op == 2) and size == 0): return -1
            queries += 1
            if op == 2: size -= 1
        else: return -1
    let needed = queries * 8
    if needed > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed)): return -2
    var roots = List[Int](capacity=9); var values = List[Int64](capacity=128); var child = List[Int](capacity=128); var sibling = List[Int](capacity=128); var degree = List[Int](capacity=128)
    for _ in range(9): roots.append(-1)
    var results = List[Int64](capacity=queries); var heap_size = 0
    for i in range(Int(opn)):
        let op = input[1 + 2 * i]; let arg = input[2 + 2 * i]
        if op == 0:
            let idx = len(values); values.append(arg); child.append(-1); sibling.append(-1); degree.append(0)
            heap_size += 1
            heap_add_tree(roots, values, child, sibling, degree, idx)
        elif op == 3:
            results.append(1 if heap_size == 0 else 0)
        else:
            var best = -1
            for r in range(len(roots)):
                if roots[r] >= 0 and (best < 0 or values[roots[r]] < values[best]): best = roots[r]
            if op == 1: results.append(values[best])
            else:
                results.append(values[best]); roots[degree[best]] = -1
                var node = child[best]
                while node >= 0:
                    let next = sibling[node]; sibling[node] = -1
                    heap_add_tree(roots, values, child, sibling, degree, node)
                    node = next
                heap_size -= 1
    for i in range(len(results)):
        let bits = UInt64(results[i])
        for b in range(8): output[8 * i + b] = UInt8((bits >> (8 * b)) & 255)
    return Int64(needed)
