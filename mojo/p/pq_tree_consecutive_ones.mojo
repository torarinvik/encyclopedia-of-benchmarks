from std.collections import InlineArray

const MAX_N: usize = 20
const MAX_M: usize = 32
const MAX_INPUT: usize = 35
const MAX_NODES: usize = 128
const MAX_OUTPUT: usize = 648
const LEAF: u8 = 0
const P_NODE: u8 = 1
const Q_NODE: u8 = 2
const WHITE: u8 = 0
const BLACK: u8 = 1
const MIXED: u8 = 2

struct PqNode(Copyable):
    var kind: u8
    var count: usize
    var arg: u8
    var child: InlineArray[u8, MAX_N]

    fn __init__(out self, kind: u8 = LEAF, count: usize = 0, arg: u8 = 0):
        self.kind = kind
        self.count = count
        self.arg = arg
        self.child = InlineArray[u8, MAX_N](fill=0)

struct PqTree(Copyable):
    var nodes: InlineArray[PqNode, MAX_NODES]
    var color: InlineArray[u8, MAX_NODES]
    var free_id: InlineArray[u8, MAX_NODES]
    var next_id: usize
    var free_count: usize
    var root: usize

    fn __init__(out self):
        self.nodes = InlineArray[PqNode, MAX_NODES](fill=PqNode())
        self.color = InlineArray[u8, MAX_NODES](fill=0)
        self.free_id = InlineArray[u8, MAX_NODES](fill=0)
        self.next_id = 0
        self.free_count = 0
        self.root = 0

def pq_new(tree: mutable PqTree&, kind: u8) -> i64:
    id: mutable usize = 0
    if tree.free_count > 0:
        tree.free_count <- tree.free_count - 1
        id <- tree.free_id[tree.free_count].usize()
    else:
        if tree.next_id >= MAX_NODES: return -1
        id <- tree.next_id
        tree.next_id <- tree.next_id + 1
    tree.nodes[id] <- PqNode()
    tree.nodes[id].kind <- kind
    id.i64()

def pq_delete(tree: mutable PqTree&, id: usize) -> void:
    tree.nodes[id].count <- 0
    tree.free_id[tree.free_count] <- id.u8()
    tree.free_count <- tree.free_count + 1

def pq_push(tree: mutable PqTree&, id: usize, child: usize) -> void:
    at: usize = tree.nodes[id].count
    tree.nodes[id].child[at] <- child.u8()
    tree.nodes[id].count <- tree.nodes[id].count + 1

def pq_paint(tree: mutable PqTree&, id: usize, mask: u64) -> u8:
    node: PqNode = tree.nodes[id]
    if node.kind == LEAF:
        tree.color[id] <- if ((mask >> node.arg.usize()) & 1) != 0: BLACK else: WHITE
        return tree.color[id]
    saw_white: mutable bool = false
    saw_black: mutable bool = false
    for i in 0..<node.count:
        shade: u8 = pq_paint(tree, node.child[i].usize(), mask)
        saw_white <- saw_white or shade != BLACK
        saw_black <- saw_black or shade != WHITE
    tree.color[id] <- if saw_white and saw_black: MIXED else: if saw_black: BLACK else: WHITE
    tree.color[id]

def pq_pattern(tree: PqTree&, children: view[u8], count: usize) -> bool:
    pivot: mutable i64 = -1
    mixed_count: mutable usize = 0
    for i in 0..<count:
        if tree.color[children[i].usize()] == MIXED:
            pivot <- i.i64()
            mixed_count <- mixed_count + 1
            if mixed_count > 1: return false
    if mixed_count == 0:
        for i in 0..<count:
            if tree.color[children[i].usize()] == BLACK:
                pivot <- i.i64()
                break
    if pivot < 0: return false
    for i in 0..<pivot.usize():
        if tree.color[children[i].usize()] != WHITE: return false
    for i in pivot.usize() + 1..<count:
        if tree.color[children[i].usize()] != BLACK: return false
    true

def pq_split(tree: mutable PqTree&, id: usize, output: mutable view[u8]) -> i64:
    node: PqNode = tree.nodes[id]
    if tree.color[id] != MIXED:
        output[0] <- id.u8()
        return 1
    old: mutable u8[MAX_N] = zeroed
    white: mutable u8[MAX_N] = zeroed
    black: mutable u8[MAX_N] = zeroed
    mixed: mutable u8[MAX_N] = zeroed
    nw: mutable usize = 0
    nb: mutable usize = 0
    nm: mutable usize = 0
    used: mutable usize = 0
    for i in 0..<node.count:
        old[i] <- node.child[i]
        shade: u8 = tree.color[old[i].usize()]
        if shade == WHITE:
            white[nw] <- old[i]
            nw <- nw + 1
        elif shade == BLACK:
            black[nb] <- old[i]
            nb <- nb + 1
        else:
            mixed[nm] <- old[i]
            nm <- nm + 1
    if node.kind == Q_NODE:
        if not pq_pattern(tree, old[0:node.count], node.count):
            for left in 0..<node.count / 2:
                right: usize = node.count - 1 - left
                temp: u8 = old[left]
                old[left] <- old[right]
                old[right] <- temp
            if not pq_pattern(tree, old[0:node.count], node.count): return -1
        for i in 0..<node.count:
            child: usize = old[i].usize()
            if tree.color[child] == MIXED:
                part: mutable u8[MAX_N] = zeroed
                part_count: i64 = pq_split(tree, child, part[0:MAX_N])
                if part_count < 0: return -1
                for j in 0..<part_count.usize():
                    output[used] <- part[j]
                    used <- used + 1
            else:
                output[used] <- old[i]
                used <- used + 1
    else:
        if nm > 1: return -1
        if nw > 0:
            group: i64 = pq_new(tree, P_NODE)
            if group < 0: return -1
            for i in 0..<nw: pq_push(tree, group.usize(), white[i].usize())
            output[used] <- group.u8()
            used <- used + 1
        if nm > 0:
            part: mutable u8[MAX_N] = zeroed
            part_count: i64 = pq_split(tree, mixed[0].usize(), part[0:MAX_N])
            if part_count < 0: return -1
            for i in 0..<part_count.usize(): output[used] <- part[i]; used <- used + 1
        if nb > 0:
            group: i64 = pq_new(tree, P_NODE)
            if group < 0: return -1
            for i in 0..<nb: pq_push(tree, group.usize(), black[i].usize())
            output[used] <- group.u8()
            used <- used + 1
    pq_delete(tree, id)
    used.i64()

def pq_work(tree: mutable PqTree&, id: usize) -> bool:
    node: PqNode = tree.nodes[id]
    if tree.color[id] != MIXED: return true
    old: mutable u8[MAX_N] = zeroed
    white: mutable u8[MAX_N] = zeroed
    black: mutable u8[MAX_N] = zeroed
    mixed: mutable u8[MAX_N] = zeroed
    nw: mutable usize = 0
    nb: mutable usize = 0
    nm: mutable usize = 0
    for i in 0..<node.count:
        old[i] <- node.child[i]
        shade: u8 = tree.color[old[i].usize()]
        if shade == WHITE:
            white[nw] <- old[i]
            nw <- nw + 1
        elif shade == BLACK:
            black[nb] <- old[i]
            nb <- nb + 1
        else:
            mixed[nm] <- old[i]
            nm <- nm + 1
    if node.kind == P_NODE:
        if nb == 0 and nm == 1: return pq_work(tree, mixed[0].usize())
        if nm > 2: return false
        q: i64 = pq_new(tree, Q_NODE)
        if q < 0: return false
        for i in 0..<nw: tree.nodes[id].child[i] <- white[i]
        tree.nodes[id].child[nw] <- q.u8()
        tree.nodes[id].count <- nw + 1
        if nm > 0:
            part: mutable u8[MAX_N] = zeroed
            part_count: i64 = pq_split(tree, mixed[0].usize(), part[0:MAX_N])
            if part_count < 0: return false
            for i in 0..<part_count.usize(): pq_push(tree, q.usize(), part[i].usize())
        if nb > 0:
            group: i64 = pq_new(tree, P_NODE)
            if group < 0: return false
            for i in 0..<nb: pq_push(tree, group.usize(), black[i].usize())
            pq_push(tree, q.usize(), group.usize())
        if nm == 2:
            part: mutable u8[MAX_N] = zeroed
            part_count: i64 = pq_split(tree, mixed[1].usize(), part[0:MAX_N])
            if part_count < 0: return false
            i: mutable i64 = part_count - 1
            while i >= 0:
                pq_push(tree, q.usize(), part[i.usize()].usize())
                i <- i - 1
        return true
    left: mutable i64 = -1
    right: mutable i64 = -1
    for i in 0..<node.count:
        if tree.color[old[i].usize()] != WHITE:
            if left < 0: left <- i.i64()
            right <- i.i64()
    if left < 0: return false
    for i in left.usize() + 1..<right.usize():
        if tree.color[old[i].usize()] != BLACK: return false
    if left == right and tree.color[old[left.usize()].usize()] == MIXED:
        return pq_work(tree, old[left.usize()].usize())
    result: mutable u8[MAX_N] = zeroed
    used: mutable usize = 0
    for i in 0..<left.usize(): result[used] <- old[i]; used <- used + 1
    part: mutable u8[MAX_N] = zeroed
    part_count: mutable i64 = pq_split(tree, old[left.usize()].usize(), part[0:MAX_N])
    if part_count < 0: return false
    for i in 0..<part_count.usize(): result[used] <- part[i]; used <- used + 1
    for i in left.usize() + 1..<right.usize(): result[used] <- old[i]; used <- used + 1
    if right != left:
        part_count <- pq_split(tree, old[right.usize()].usize(), part[0:MAX_N])
        if part_count < 0: return false
        i: mutable i64 = part_count - 1
        while i >= 0:
            result[used] <- part[i.usize()]
            used <- used + 1
            i <- i - 1
    for i in right.usize() + 1..<node.count: result[used] <- old[i]; used <- used + 1
    tree.nodes[id].count <- used
    for i in 0..<used: tree.nodes[id].child[i] <- result[i]
    true

def pq_normalize(tree: mutable PqTree&, id: usize) -> usize:
    node: PqNode = tree.nodes[id]
    if node.kind == LEAF: return id
    for i in 0..<node.count: tree.nodes[id].child[i] <- pq_normalize(tree, node.child[i].usize()).u8()
    if tree.nodes[id].count == 1:
        child: usize = tree.nodes[id].child[0].usize()
        pq_delete(tree, id)
        return child
    if tree.nodes[id].kind == Q_NODE and tree.nodes[id].count == 2: tree.nodes[id].kind <- P_NODE
    id

def pq_compare(tree: PqTree&, a: usize, b: usize) -> i64:
    x: PqNode = tree.nodes[a]
    y: PqNode = tree.nodes[b]
    xa: usize = if x.kind == LEAF: x.arg.usize() else: x.count
    ya: usize = if y.kind == LEAF: y.arg.usize() else: y.count
    if x.kind != y.kind: return if x.kind < y.kind: -1 else: 1
    if xa != ya: return if xa < ya: -1 else: 1
    if x.kind != LEAF:
        for i in 0..<x.count:
            comparison: i64 = pq_compare(tree, x.child[i].usize(), y.child[i].usize())
            if comparison != 0: return comparison
    0

def pq_canonicalize(tree: mutable PqTree&, id: usize) -> void:
    node: PqNode = tree.nodes[id]
    if node.kind == LEAF: return
    for i in 0..<node.count: pq_canonicalize(tree, node.child[i].usize())
    if node.kind == P_NODE:
        for i in 1..<node.count:
            item: u8 = tree.nodes[id].child[i]
            j: mutable usize = i
            while j > 0 and pq_compare(tree, item.usize(), tree.nodes[id].child[j-1].usize()) < 0:
                tree.nodes[id].child[j] <- tree.nodes[id].child[j-1]
                j <- j - 1
            tree.nodes[id].child[j] <- item
    else:
        order: mutable i64 = 0
        for i in 0..<node.count:
            order <- pq_compare(tree, node.child[i].usize(), node.child[node.count-1-i].usize())
            if order != 0: break
        if order > 0:
            for left in 0..<node.count/2:
                right: usize = node.count-1-left
                temp: u8 = tree.nodes[id].child[left]
                tree.nodes[id].child[left] <- tree.nodes[id].child[right]
                tree.nodes[id].child[right] <- temp

def pq_frontier_count(tree: PqTree&, id: usize) -> i64:
    node: PqNode = tree.nodes[id]
    if node.kind == LEAF: return 1
    result: mutable i64 = 1
    for i in 0..<node.count: result <- result * pq_frontier_count(tree, node.child[i].usize())
    if node.kind == P_NODE:
        for factor in 2..<node.count+1: result <- result * factor.i64()
    else: result <- result * 2
    result

def pq_node_count(tree: PqTree&, id: usize) -> usize:
    node: PqNode = tree.nodes[id]
    result: mutable usize = 1
    if node.kind != LEAF:
        for i in 0..<node.count: result <- result + pq_node_count(tree, node.child[i].usize())
    result

def pq_serialize(tree: PqTree&, id: usize, words: mutable view[i64], used: mutable usize&) -> void:
    node: PqNode = tree.nodes[id]
    words[used] <- node.kind.i64()
    used <- used + 1
    words[used] <- if node.kind == LEAF: node.arg.i64() else: node.count.i64()
    used <- used + 1
    if node.kind != LEAF:
        for i in 0..<node.count: pq_serialize(tree, node.child[i].usize(), words, used)

def pq_store(value: i64, output: mutable view[u8], offset: usize) -> void:
    bits: u64 = value.u64()
    for i in 0..<8:
        output[offset+i] <- (bits & 255).u8()
        bits <- bits >> 8

def pq_tree_consecutive_ones_impl(input: i64&, length: usize, output: mutable u8&, capacity: usize) -> i64:
    if input.is_null() or length < 2 or length > MAX_INPUT: return -1
    n_raw: i64 = input[0]
    m_raw: i64 = input[1]
    if n_raw < 2 or n_raw > MAX_N.i64() or m_raw < 0 or m_raw > MAX_M.i64() or length != 2 + m_raw.usize(): return -1
    n: usize = n_raw.usize()
    m: usize = m_raw.usize()
    valid: u64 = (1 << n) - 1
    for row in 0..<m:
        raw: i64 = input[2+row]
        if raw < 0 or (raw.u64() & ~valid) != 0: return -1
    tree: mutable PqTree = PqTree()
    tree.next_id <- n + 1
    tree.root <- n
    for i in 0..<n:
        tree.nodes[i].kind <- LEAF
        tree.nodes[i].arg <- i.u8()
        tree.nodes[n].child[i] <- i.u8()
    tree.nodes[n].kind <- P_NODE
    tree.nodes[n].count <- n
    for row in 0..<m:
        _ = pq_paint(tree, tree.root, input[2+row].u64())
        if not pq_work(tree, tree.root):
            if output.is_null() or capacity < 24: return -2
            result: mutable view[u8] = output[0:24]
            for i in 0..<24: result[i] <- 0
            return 24
        tree.root <- pq_normalize(tree, tree.root)
    pq_canonicalize(tree, tree.root)
    words: mutable i64[81] = zeroed
    used: mutable usize = 0
    words[used] <- 1; used <- used + 1
    words[used] <- pq_frontier_count(tree, tree.root); used <- used + 1
    words[used] <- pq_node_count(tree, tree.root).i64(); used <- used + 1
    pq_serialize(tree, tree.root, words[0:81], used)
    staged: mutable u8[MAX_OUTPUT] = zeroed
    bytes: usize = used * 8
    for i in 0..<used: pq_store(words[i], staged[0:MAX_OUTPUT], i*8)
    if output.is_null() or capacity < bytes: return -2
    result: mutable view[u8] = output[0:bytes]
    for i in 0..<bytes: result[i] <- staged[i]
    bytes.i64()

export fn pq_tree_consecutive_ones(input: i64&, length: usize, output: mutable u8&, capacity: usize) -> i64 @export("pq_tree_consecutive_ones") = pq_tree_consecutive_ones_impl
from std.collections import InlineArray

