from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn write_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    for byte in range(8):
        output[offset + byte] = UInt8((value >> (8 * byte)) & 255)

@export("aho_build_rooted_triplet_tree")
fn aho_build_rooted_triplet_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 318:
        return -1
    if input[0] < 1 or input[0] > 7 or input[1] < 0:
        return -1
    let n = Int(input[0])
    let q_limit = n * (n - 1) * (n - 2) // 2
    if input[1] > Int64(q_limit):
        return -1
    let q = Int(input[1])
    if length != c_size_t(2 + 3 * q):
        return -1

    var triples = List[Int](length=315, fill=0)
    for i in range(q):
        let aa = input[2 + 3 * i]
        let bb = input[3 + 3 * i]
        let cc = input[4 + 3 * i]
        if aa < 0 or aa >= Int64(n) or bb < 0 or bb >= Int64(n) or cc < 0 or cc >= Int64(n) or aa == bb or aa == cc or bb == cc:
            return -1
        var a = Int(aa)
        var b = Int(bb)
        if a > b:
            let temp = a
            a = b
            b = temp
        for j in range(i):
            if triples[3 * j] == a and triples[3 * j + 1] == b and triples[3 * j + 2] == Int(cc):
                return -1
        triples[3 * i] = a
        triples[3 * i + 1] = b
        triples[3 * i + 2] = Int(cc)

    var tasks = List[Int](length=13, fill=0)
    tasks[0] = (1 << n) - 1
    var top = 1
    var kind = List[Int](length=13, fill=0)
    var node_value = List[Int](length=13, fill=0)
    var node_count = 0
    var compatible = True
    while top > 0:
        top -= 1
        let mask = tasks[top]
        if (mask & (mask - 1)) == 0:
            var label = 0
            while (mask & (1 << label)) == 0:
                label += 1
            kind[node_count] = 1
            node_value[node_count] = label
            node_count += 1
            continue
        var edge = List[Bool](length=49, fill=False)
        for i in range(q):
            let a = triples[3 * i]
            let b = triples[3 * i + 1]
            let c = triples[3 * i + 2]
            let needed = (1 << a) | (1 << b) | (1 << c)
            if (mask & needed) == needed:
                edge[a * 7 + b] = True
                edge[b * 7 + a] = True
        var seen = List[Bool](length=7, fill=False)
        var components = List[Int](length=7, fill=0)
        var component_count = 0
        for start in range(n):
            if (mask & (1 << start)) == 0 or seen[start]:
                continue
            var queue = List[Int](length=7, fill=0)
            var head = 0
            var tail = 1
            var component = 0
            queue[0] = start
            seen[start] = True
            while head < tail:
                let current = queue[head]
                head += 1
                component |= 1 << current
                for other in range(n):
                    if edge[current * 7 + other] and not seen[other]:
                        seen[other] = True
                        queue[tail] = other
                        tail += 1
            components[component_count] = component
            component_count += 1
        if component_count == 1:
            compatible = False
            break
        kind[node_count] = 0
        node_value[node_count] = component_count
        node_count += 1
        var k = component_count
        while k > 0:
            k -= 1
            tasks[top] = components[k]
            top += 1

    var words = List[Int64](length=14, fill=0)
    var word_count = 1
    if compatible:
        words[0] = Int64(node_count)
        for i in range(node_count):
            if kind[i] == 1:
                words[i + 1] = -Int64(node_value[i] + 1)
            else:
                words[i + 1] = Int64(node_value[i])
        word_count += node_count
    let byte_count = word_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count):
        return -2
    for i in range(word_count):
        write_word(output, i * 8, words[i])
    return Int64(byte_count)
