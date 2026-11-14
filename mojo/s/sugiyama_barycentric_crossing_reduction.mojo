from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn sugiyama_positions(order: List[Int], sizes: List[Int], layer: Int, mut pos: List[Int]):
    for i in range(sizes[layer]): pos[order[32 * layer + i]] = i

fn sugiyama_reorder(mut order: List[Int], sizes: List[Int], owner: List[Int],
        sources: List[Int], targets: List[Int], target: Int, fixed: Int, down: Bool,
        mut pos: List[Int]):
    sugiyama_positions(order, sizes, fixed, pos)
    var rank = List[Int](length=32, fill=0)
    var num = List[Int](length=32, fill=0)
    var den = List[Int](length=32, fill=0)
    for i in range(sizes[target]): rank[order[32 * target + i]] = i
    for e in range(len(sources)):
        let u = sources[e]; let v = targets[e]
        if down and owner[u] == fixed and owner[v] == target:
            num[v] += pos[u]; den[v] += 1
        elif not down and owner[u] == target and owner[v] == fixed:
            num[u] += pos[v]; den[u] += 1
    for i in range(sizes[target]):
        let v = order[32 * target + i]
        if den[v] == 0: num[v] = rank[v]; den[v] = 1
    for i in range(1, sizes[target]):
        let v = order[32 * target + i]
        var j = i
        while j > 0:
            let prior = order[32 * target + j - 1]
            let left = num[v] * den[prior]; let right = num[prior] * den[v]
            if left > right or (left == right and rank[v] > rank[prior]): break
            order[32 * target + j] = prior
            j -= 1
        order[32 * target + j] = v
    sugiyama_positions(order, sizes, target, pos)

@export("sugiyama_barycentric_crossing_reduction")
fn sugiyama_barycentric_crossing_reduction(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 299: return -1
    let layer0 = input[0]; let limit0 = input[1]
    if layer0 < 2 or layer0 > 8 or limit0 < 0 or limit0 > 16: return -1
    let layers = Int(layer0)
    var order = List[Int](length=256, fill=0)
    var sizes = List[Int](length=8, fill=0)
    var owner = List[Int](length=32, fill=-1)
    var pos = List[Int](length=32, fill=0)
    var at = 2
    var total = 0
    for layer in range(layers):
        if at >= Int(length): return -1
        let size0 = input[at]; at += 1
        if size0 < 1 or size0 > 32 or at + Int(size0) > Int(length): return -1
        sizes[layer] = Int(size0); total += Int(size0)
        if total > 32: return -1
        for i in range(Int(size0)):
            let id0 = input[at]; at += 1
            if id0 < 0 or id0 >= 32: return -1
            let id = Int(id0)
            if owner[id] != -1: return -1
            order[32 * layer + i] = id; owner[id] = layer
    if at >= Int(length): return -1
    let edges0 = input[at]; at += 1
    if edges0 < 0 or edges0 > 128 or at + 2 * Int(edges0) != Int(length): return -1
    var sources = List[Int]()
    var targets = List[Int]()
    for e in range(Int(edges0)):
        let u0 = input[at + 2 * e]; let v0 = input[at + 2 * e + 1]
        if u0 < 0 or u0 >= 32 or v0 < 0 or v0 >= 32: return -1
        let u = Int(u0); let v = Int(v0)
        if owner[u] < 0 or owner[v] != owner[u] + 1: return -1
        for j in range(e):
            if sources[j] == u and targets[j] == v: return -1
        sources.append(u); targets.append(v)
    var sweeps = 0
    for _ in range(Int(limit0)):
        var before = List[Int](length=256, fill=0)
        for i in range(256): before[i] = order[i]
        for layer in range(layers - 1):
            sugiyama_reorder(order, sizes, owner, sources, targets, layer + 1, layer, True, pos)
        for reverse in range(layers - 1):
            let layer = layers - 2 - reverse
            sugiyama_reorder(order, sizes, owner, sources, targets, layer, layer + 1, False, pos)
        sweeps += 1
        var changed = False
        for layer in range(layers):
            for i in range(sizes[layer]):
                if before[32 * layer + i] != order[32 * layer + i]: changed = True
        if not changed: break
    for layer in range(layers): sugiyama_positions(order, sizes, layer, pos)
    var crossings = 0
    for i in range(len(sources)):
        for j in range(i + 1, len(sources)):
            if owner[sources[i]] == owner[sources[j]] and
                    (pos[sources[i]] - pos[sources[j]]) * (pos[targets[i]] - pos[targets[j]]) < 0:
                crossings += 1
    let bytes = 8 * (total + 2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var words = List[Int]()
    words.append(sweeps); words.append(crossings)
    for layer in range(layers):
        for i in range(sizes[layer]): words.append(order[32 * layer + i])
    for word in range(len(words)):
        for byte in range(8): output[8 * word + byte] = UInt8((words[word] >> (8 * byte)) & 255)
    return Int64(bytes)
