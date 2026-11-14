from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn suffix_tree_less(text: List[Int64], mut a: Int, mut b: Int) -> Bool:
    while a < len(text) and b < len(text):
        if text[a] != text[b]: return text[a] < text[b]
        a += 1; b += 1
    return a == len(text) and b != len(text)

@export("suffix_tree_from_sa_lcp")
fn suffix_tree_from_sa_lcp(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 10: return -1
    let n0 = input[0]
    if n0 < 0 or n0 > 8 or length != c_size_t(n0 + 1): return -1
    let n = Int(n0)
    var text = List[Int64]()
    for i in range(n):
        let value = input[i + 1]
        if value < 1 or value > 255: return -1
        text.append(value)
    text.append(0)
    let suffixes = n + 1
    var sa = List[Int]()
    for i in range(suffixes): sa.append(i)
    for i in range(1, suffixes):
        let value = sa[i]
        var j = i
        while j > 0 and suffix_tree_less(text, value, sa[j - 1]):
            sa[j] = sa[j - 1]; j -= 1
        sa[j] = value
    var lcp = List[Int](length=suffixes, fill=0)
    for rank in range(1, suffixes):
        let a = sa[rank - 1]; let b = sa[rank]
        var common = 0
        while a + common < suffixes and b + common < suffixes and text[a + common] == text[b + common]: common += 1
        lcp[rank] = common
    var parent = List[Int](length=17, fill=-1)
    var depth = List[Int](length=17, fill=0)
    var rep = List[Int](length=17, fill=-1)
    var leaf = List[Int](length=17, fill=-1)
    var last = List[Int](length=17, fill=-1)
    var stack = List[Int]()
    stack.append(0)
    var nodes = 1
    for rank in range(suffixes):
        if rank > 0:
            let common = lcp[rank]
            while len(stack) > 1 and depth[stack[len(stack) - 1]] > common: _ = stack.pop()
            let top = stack[len(stack) - 1]
            if depth[top] < common:
                let old = last[top]
                if old < 0 or nodes >= 17: return -1
                let internal = nodes; nodes += 1
                parent[internal] = top; depth[internal] = common; rep[internal] = rep[old]
                last[internal] = old; parent[old] = internal; last[top] = internal
                stack.append(internal)
        let owner = stack[len(stack) - 1]
        let start = sa[rank]
        if nodes >= 17: return -1
        parent[nodes] = owner; depth[nodes] = suffixes - start
        rep[nodes] = start; leaf[nodes] = start; last[owner] = nodes
        nodes += 1
    var order = List[Int]()
    for i in range(nodes): order.append(i)
    for i in range(1, nodes):
        let node = order[i]
        var j = i
        while j > 0:
            let prev = order[j - 1]
            if depth[prev] < depth[node] or (depth[prev] == depth[node] and
                    (rep[prev] < rep[node] or (rep[prev] == rep[node] and leaf[prev] <= leaf[node])): break
            order[j] = prev; j -= 1
        order[j] = node
    let bytes = 8 * (1 + 5 * nodes)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var words = List[Int]()
    words.append(nodes)
    for index in range(nodes):
        let node = order[index]
        if node == 0:
            words.append(-1); words.append(-1); words.append(-1); words.append(0); words.append(-1)
        else:
            let p = parent[node]
            words.append(rep[p]); words.append(depth[p]); words.append(rep[node]); words.append(depth[node]); words.append(leaf[node])
    for word in range(len(words)):
        for byte in range(8): output[8 * word + byte] = UInt8((words[word] >> (8 * byte)) & 255)
    return Int64(bytes)
