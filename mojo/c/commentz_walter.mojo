from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime CW_P = 6
comptime CW_L = 8
comptime CW_T = 64
comptime CW_NODES = 33
comptime CW_INPUT = 105

fn cw_is_suffix(v: Int, u: Int, depth: InlineArray[Int, 33],
                path: InlineArray[Int, 264]) -> Bool:
    if depth[v] >= depth[u]: return False
    let offset = depth[u] - depth[v]
    for i in range(depth[v]):
        if path[v * CW_L + i] != path[u * CW_L + offset + i]: return False
    return True

@export("commentz_walter")
fn commentz_walter(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(CW_INPUT): return -1
    let raw_p = values[0]
    let raw_n = values[1]
    if raw_p < 1 or raw_p > CW_P or raw_n < 0 or raw_n > CW_T: return -1
    let p = Int(raw_p)
    let n = Int(raw_n)
    if length < c_size_t(2 + p): return -1
    var lens = InlineArray[Int, 6]()
    var total = 0
    var shortest = CW_L + 1
    for i in range(p):
        let raw = values[2 + i]
        if raw < 1 or raw > CW_L: return -1
        lens[i] = Int(raw)
        total += lens[i]
        shortest = min(shortest, lens[i])
    if total > 32 or length != c_size_t(2 + p + total + n): return -1
    var patterns = InlineArray[Int64, 48]()
    var text = InlineArray[Int64, 64]()
    var at = 2 + p
    for i in range(p):
        for j in range(lens[i]):
            let symbol = values[at]
            at += 1
            if symbol < 1 or symbol > 4: return -1
            patterns[i * CW_L + j] = symbol
        for prior in range(i):
            if lens[prior] != lens[i]: continue
            var same = True
            for j in range(lens[i]):
                if patterns[prior * CW_L + j] != patterns[i * CW_L + j]: same = False
            if same: return -1
    for i in range(n):
        let symbol = values[at]
        at += 1
        if symbol < 1 or symbol > 4: return -1
        text[i] = symbol

    var child = InlineArray[Int, 165]()
    var parent = InlineArray[Int, 33]()
    var label = InlineArray[Int, 33]()
    var depth = InlineArray[Int, 33]()
    var path = InlineArray[Int, 264]()
    var terminal = InlineArray[Bool, 33]()
    var nodes = 1
    for i in range(p):
        var v = 0
        for step in range(lens[i]):
            let symbol = Int(patterns[i * CW_L + lens[i] - 1 - step])
            var encoded = child[v * 5 + symbol]
            if encoded == 0:
                let u = nodes
                nodes += 1
                child[v * 5 + symbol] = u + 1
                parent[u] = v
                label[u] = symbol
                depth[u] = depth[v] + 1
                for k in range(depth[v]): path[u * CW_L + k] = path[v * CW_L + k]
                path[u * CW_L + depth[v]] = symbol
                encoded = u + 1
            v = encoded - 1
        terminal[v] = True

    var shift1 = InlineArray[Int, 33]()
    var shift2 = InlineArray[Int, 33]()
    var bad = InlineArray[Int, 5]()
    for v in range(nodes):
        shift1[v] = shortest
        shift2[v] = shortest
    shift1[0] = 1
    for a in range(5): bad[a] = shortest + 1
    for v in range(1, nodes):
        bad[label[v]] = min(bad[label[v]], depth[v])
        shift2[v] = shift2[parent[v]]
        for u in range(1, nodes):
            if cw_is_suffix(v, u, depth, path):
                let delta = depth[u] - depth[v]
                shift1[v] = min(shift1[v], delta)
                if terminal[u]: shift2[v] = min(shift2[v], delta)

    var matches: Int64 = 0
    var position = shortest - 1
    while position < n:
        var v = 0
        var i = position
        while i >= 0:
            let encoded = child[v * 5 + Int(text[i])]
            if encoded == 0: break
            v = encoded - 1
            i -= 1
            if terminal[v]: matches += 1
        let symbol = if i >= 0: Int(text[i]) else: 0
        let char_shift = if symbol == 0: shortest + 1 else: bad[symbol]
        var delta = char_shift - depth[v] - 1
        if delta < shift1[v]: delta = shift1[v]
        if delta > shift2[v]: delta = shift2[v]
        position += delta
    return matches
