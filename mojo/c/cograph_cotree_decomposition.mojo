# Bounded clean-room connected/co-connected cograph cotree profile.
fn ct_components(mask: Int, adjacency: List[Int], complement: Bool) -> List[Int]:
    var remaining = mask
    var parts = List[Int]()
    for root in range(12):
        let root_bit = 1 << root
        if (remaining & root_bit) == 0: continue
        var reached = root_bit
        var queue = List[Int]()
        queue.append(root)
        var head = 0
        while head < queue.len():
            let vertex = queue[head]
            head += 1
            var neighbors = adjacency[vertex] & mask
            if complement:
                neighbors = mask & (~adjacency[vertex]) & (~(1 << vertex))
            var fresh = neighbors & (~reached)
            for next in range(12):
                let bit = 1 << next
                if (fresh & bit) != 0:
                    fresh &= ~bit
                    reached |= bit
                    queue.append(next)
        parts.append(reached)
        remaining &= ~reached
    return parts

fn ct_emit(mask: Int, adjacency: List[Int]) -> List[Int]:
    if (mask & (mask - 1)) == 0:
        var leaf = List[Int]()
        leaf.append(0)
        var vertex = 0
        while (mask & (1 << vertex)) == 0: vertex += 1
        leaf.append(vertex)
        return leaf
    var parts = ct_components(mask, adjacency, False)
    var kind = 1
    if parts.len() == 1:
        parts = ct_components(mask, adjacency, True)
        kind = 2
        if parts.len() <= 1: return List[Int]()
    var tokens = List[Int]()
    tokens.append(kind)
    tokens.append(parts.len())
    for child in parts:
        let child_tokens = ct_emit(child, adjacency)
        if child_tokens.len() == 0: return List[Int]()
        for token in child_tokens: tokens.append(token)
    return tokens

@export("cograph_cotree_decomposition")
fn cograph_cotree_decomposition(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 135: return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 1 or n64 > 12 or m64 < 0 or m64 > 66 or m64 > n64 * (n64 - 1) // 2: return -1
    let n = Int(n64)
    let m = Int(m64)
    if length != c_size_t(2 + 2 * m): return -1
    var adjacency = List[Int](length=12, fill=0)
    for edge in range(m):
        let u64 = input[2 + 2 * edge]
        let v64 = input[3 + 2 * edge]
        if u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64 or u64 == v64: return -1
        let u = Int(u64)
        let v = Int(v64)
        if (adjacency[u] & (1 << v)) != 0: return -1
        adjacency[u] |= 1 << v
        adjacency[v] |= 1 << u
    var tokens = ct_emit((1 << n) - 1, adjacency)
    var staged = List[UInt8]()
    if tokens.len() == 0:
        staged.append(0)
    else:
        staged.append(1)
        for token in tokens: staged.append(UInt8(token))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(staged.len()): return -2
    for i in range(staged.len()): output[i] = staged[i]
    return Int64(staged.len())
