from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn suffix_code(text: List[Int], n: Int, position: Int) -> Int:
    if position == n: return -1
    return text[position]

fn suffix_before(text: List[Int], n: Int, a: Int, b: Int) -> Bool:
    var k = 0
    while a+k <= n and b+k <= n:
        let x = suffix_code(text, n, a+k)
        let y = suffix_code(text, n, b+k)
        if x != y: return x < y
        k += 1
    return a < b

@export("suffix_tree_pattern_occurrences")
fn suffix_tree_pattern_occurrences(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 39: return -1
    let nr = input[0]
    if nr < 0 or nr > 24: return -1
    let n = Int(nr)
    if length < c_size_t(2+n): return -1
    let mr = input[1+n]
    if mr < 1 or mr > 12 or length != c_size_t(2+n+Int(mr)): return -1
    let m = Int(mr)
    var text = List[Int](capacity=n)
    var pattern = List[Int](capacity=m)
    for i in range(n):
        let x = input[1+i]
        if x < 0 or x > 127: return -1
        text.append(Int(x))
    for i in range(m):
        let x = input[2+n+i]
        if x < 0 or x > 127: return -1
        pattern.append(Int(x))
    # Flat node arrays represent edge labels and child lists; node zero is root.
    var starts = List[Int](capacity=51)
    var lengths = List[Int](capacity=51)
    var suffixes = List[Int](capacity=51)
    var counts = List[Int](capacity=51)
    var children = List[Int](capacity=51*51)
    for _ in range(51):
        starts.append(0); lengths.append(0); suffixes.append(0); counts.append(0)
    for _ in range(51*51): children.append(0)
    var used = 1
    for start in range(n+1):
        let suffix_length = n+1-start
        var offset = 0
        var node = 0
        while offset < suffix_length:
            let first = suffix_code(text, n, start+offset)
            var slot = 0
            while slot < counts[node] and suffix_code(text, n, starts[children[51*node+slot]]) != first:
                slot += 1
            if slot == counts[node]:
                if used >= 51: return -1
                let leaf = used
                used += 1
                starts[leaf] = start+offset
                lengths[leaf] = suffix_length-offset
                suffixes[leaf] = start
                children[51*node+slot] = leaf
                counts[node] += 1
                break
            let child = children[51*node+slot]
            var common = 0
            while common < lengths[child] and offset+common < suffix_length and suffix_code(text, n, start+offset+common) == suffix_code(text, n, starts[child]+common):
                common += 1
            if common == lengths[child]:
                offset += common
                node = child
                continue
            if used >= 51: return -1
            let split = used
            used += 1
            starts[split] = starts[child]
            lengths[split] = common
            children[51*split] = child
            counts[split] = 1
            starts[child] += common
            lengths[child] -= common
            children[51*node+slot] = split
            offset += common
            node = split
    var node = 0
    var offset = 0
    var matched = False
    while offset < m:
        let wanted = pattern[offset]
        var slot = 0
        while slot < counts[node] and suffix_code(text, n, starts[children[51*node+slot]]) != wanted:
            slot += 1
        if slot == counts[node]: break
        let child = children[51*node+slot]
        var common = 0
        while common < lengths[child] and offset+common < m and suffix_code(text, n, starts[child]+common) == pattern[offset+common]:
            common += 1
        if offset+common == m:
            node = child
            matched = True
            break
        if common != lengths[child]: break
        offset += common
        node = child
    var results = List[Int](capacity=24)
    if matched:
        var stack = List[Int](capacity=51)
        stack.append(node)
        while len(stack) > 0:
            let current = stack.pop()
            if counts[current] == 0 and lengths[current] > 0:
                results.append(suffixes[current])
            for j in range(counts[current]): stack.append(children[51*current+j])
    for i in range(1,len(results)):
        let value = results[i]
        var j = i
        while j > 0 and suffix_before(text, n, value, results[j-1]):
            results[j] = results[j-1]
            j -= 1
        results[j] = value
    let bytes = 8*(1+len(results))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(1+len(results)):
        var value = Int64(len(results))
        if i > 0: value = Int64(results[i-1])
        for j in range(8): output[8*i+j] = UInt8((value >> (8*j)) & 255)
    return Int64(bytes)
