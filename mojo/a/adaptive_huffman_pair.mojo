from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const ALPHABET = 16
const MAX_NODES = 31
const MAX_SYMBOLS = 64
const MAX_INPUT = 66
const MAX_PACKED = 152
const NYT_KIND = 0
const LEAF_KIND = 1
const INTERNAL_KIND = 2

@fieldwise_init
struct AhNode(Copyable):
    var parent: Int
    var left: Int
    var right: Int
    var symbol: Int
    var kind: Int
    var weight: Int64

@fieldwise_init
struct AhBits(Copyable):
    var bytes: InlineArray[UInt8, MAX_PACKED]
    var count: Int

struct AhTree:
    var nodes: InlineArray[AhNode, MAX_NODES]
    var node_count: Int
    var root: Int
    var nyt: Int
    var leaf_of: InlineArray[Int, ALPHABET]
    var fgk_order: InlineArray[Int, MAX_NODES]
    var order_count: Int
    var bits: AhBits

    fn __init__(out self):
        self.nodes = InlineArray[AhNode, MAX_NODES](fill=AhNode(-1,-1,-1,-1,NYT_KIND,0))
        self.nodes[0] = AhNode(-1,-1,-1,-1,NYT_KIND,0)
        self.node_count = 1
        self.root = 0
        self.nyt = 0
        self.leaf_of = InlineArray[Int, ALPHABET](fill=-1)
        self.fgk_order = InlineArray[Int, MAX_NODES](fill=-1)
        self.fgk_order[0] = 0
        self.order_count = 1
        self.bits = AhBits(InlineArray[UInt8, MAX_PACKED](fill=0),0)

@fieldwise_init
struct AhOrderedNode(Copyable):
    var id: Int
    var depth: Int
    var path: Int

fn ah_put_bit(inout tree: AhTree, value: Int):
    if value != 0:
        tree.bits.bytes[tree.bits.count//8] = tree.bits.bytes[tree.bits.count//8] | UInt8(1 << (7-tree.bits.count%8))
    tree.bits.count += 1

fn ah_put_value(inout tree: AhTree, value: Int, width: Int):
    for shift in range(width):
        ah_put_bit(tree,(value >> (width-shift-1)) & 1)

fn ah_encode_path(inout tree: AhTree, node0: Int):
    var reverse = InlineArray[Int, MAX_NODES](fill=0)
    var depth = 0
    var node = node0
    while node != tree.root:
        let parent = tree.nodes[node].parent
        reverse[depth] = 1 if tree.nodes[parent].right == node else 0
        depth += 1
        node = parent
    while depth > 0:
        depth -= 1
        ah_put_bit(tree,reverse[depth])

fn ah_is_ancestor(tree: AhTree, ancestor: Int, node: Int) -> Bool:
    var parent = tree.nodes[node].parent
    while parent >= 0:
        if parent == ancestor: return True
        parent = tree.nodes[parent].parent
    return False

fn ah_replace_child(inout tree: AhTree, parent: Int, old_child: Int, new_child: Int):
    if tree.nodes[parent].left == old_child: tree.nodes[parent].left = new_child
    elif tree.nodes[parent].right == old_child: tree.nodes[parent].right = new_child

fn ah_swap_positions(inout tree: AhTree, a: Int, b: Int, update_order: Bool):
    if a == b or tree.nodes[a].parent == b or tree.nodes[b].parent == a or ah_is_ancestor(tree,a,b) or ah_is_ancestor(tree,b,a): return
    let parent_a = tree.nodes[a].parent
    let parent_b = tree.nodes[b].parent
    if parent_a == parent_b:
        if parent_a >= 0:
            let temp = tree.nodes[parent_a].left
            tree.nodes[parent_a].left = tree.nodes[parent_a].right
            tree.nodes[parent_a].right = temp
    else:
        if parent_a >= 0: ah_replace_child(tree,parent_a,a,b)
        if parent_b >= 0: ah_replace_child(tree,parent_b,b,a)
        tree.nodes[a].parent = parent_b
        tree.nodes[b].parent = parent_a
    if tree.root == a: tree.root = b
    elif tree.root == b: tree.root = a
    if update_order:
        var ra = -1
        var rb = -1
        for i in range(tree.order_count):
            if tree.fgk_order[i] == a: ra = i
            if tree.fgk_order[i] == b: rb = i
        if ra >= 0 and rb >= 0:
            let temp = tree.fgk_order[ra]
            tree.fgk_order[ra] = tree.fgk_order[rb]
            tree.fgk_order[rb] = temp

fn ah_add_node(inout tree: AhTree, parent: Int, kind: Int, symbol: Int) -> Int:
    let id = tree.node_count
    tree.node_count += 1
    tree.nodes[id] = AhNode(parent,-1,-1,symbol,kind,0)
    return id

fn ah_split_nyt(inout tree: AhTree, symbol: Int, remaining: Bool, for_fgk: Bool) -> Int:
    let old = tree.nyt
    if not remaining:
        tree.nodes[old].kind = LEAF_KIND
        tree.nodes[old].symbol = symbol
        tree.leaf_of[symbol] = old
        tree.nyt = -1
        return old
    let left = ah_add_node(tree,old,NYT_KIND,-1)
    let right = ah_add_node(tree,old,LEAF_KIND,symbol)
    tree.nodes[old].kind = INTERNAL_KIND
    tree.nodes[old].left = left
    tree.nodes[old].right = right
    tree.leaf_of[symbol] = right
    tree.nyt = left
    if for_fgk:
        var position = 0
        while tree.fgk_order[position] != old: position += 1
        var i = tree.order_count + 1
        while i > position + 2:
            tree.fgk_order[i] = tree.fgk_order[i-2]
            i -= 1
        tree.fgk_order[position] = left
        tree.fgk_order[position+1] = right
        tree.fgk_order[position+2] = old
        tree.order_count += 2
    return right

fn ah_fgk_leader(tree: AhTree, node: Int, leaves_only: Bool) -> Int:
    let weight = tree.nodes[node].weight
    let parent = tree.nodes[node].parent
    var i = tree.order_count
    while i > 0:
        i -= 1
        let candidate = tree.fgk_order[i]
        if candidate == parent or tree.nodes[candidate].weight != weight or
            (leaves_only and tree.nodes[candidate].kind == INTERNAL_KIND) or
            ah_is_ancestor(tree,candidate,node) or ah_is_ancestor(tree,node,candidate): continue
        return candidate
    return node

fn ah_update_fgk(inout tree: AhTree, node0: Int):
    var node = node0
    let parent = tree.nodes[node].parent
    if tree.nyt >= 0 and parent >= 0 and tree.nodes[tree.nyt].parent == parent:
        ah_swap_positions(tree,node,ah_fgk_leader(tree,node,True),True)
        tree.nodes[node].weight += 1
        node = tree.nodes[node].parent
    while node != tree.root:
        ah_swap_positions(tree,node,ah_fgk_leader(tree,node,False),True)
        tree.nodes[node].weight += 1
        node = tree.nodes[node].parent
    tree.nodes[tree.root].weight += 1

fn ah_implicit_order(inout tree: AhTree, inout order: InlineArray[AhOrderedNode, MAX_NODES]) -> Int:
    for id in range(tree.node_count):
        var reverse = InlineArray[Int, MAX_NODES](fill=0)
        var depth = 0
        var at = id
        var path = 0
        while at != tree.root:
            let parent = tree.nodes[at].parent
            reverse[depth] = 1 if tree.nodes[parent].right == at else 0
            depth += 1
            at = parent
        var i = depth
        while i > 0:
            i -= 1
            path = path * 2 + reverse[i]
        order[id] = AhOrderedNode(id,depth,path)
    for i in range(1,tree.node_count):
        let value = order[i]
        var j = i
        while j > 0 and (order[j-1].depth < value.depth or
            (order[j-1].depth == value.depth and order[j-1].path > value.path)):
            order[j] = order[j-1]
            j -= 1
        order[j] = value
    return tree.node_count

fn ah_vitter_leader(inout tree: AhTree, node: Int, inout order: InlineArray[AhOrderedNode, MAX_NODES]) -> Int:
    let count = ah_implicit_order(tree,order)
    var i = count
    while i > 0:
        i -= 1
        let candidate = order[i].id
        if tree.nodes[candidate].weight == tree.nodes[node].weight and tree.nodes[candidate].kind == tree.nodes[node].kind:
            return candidate
    return node

fn ah_slide_increment(inout tree: AhTree, node: Int, inout order: InlineArray[AhOrderedNode, MAX_NODES]) -> Int:
    let old_parent = tree.nodes[node].parent
    let target_kind = LEAF_KIND if tree.nodes[node].kind == INTERNAL_KIND else INTERNAL_KIND
    let target_weight = tree.nodes[node].weight + (1 if tree.nodes[node].kind == INTERNAL_KIND else 0)
    let count = ah_implicit_order(tree,order)
    var block = InlineArray[Int, MAX_NODES](fill=-1)
    var block_count = 0
    for i in range(count):
        let id = order[i].id
        if tree.nodes[id].kind == target_kind and tree.nodes[id].weight == target_weight:
            block[block_count] = id
            block_count += 1
    for i in range(block_count): ah_swap_positions(tree,node,block[i],False)
    tree.nodes[node].weight += 1
    return tree.nodes[node].parent if tree.nodes[node].kind == LEAF_KIND else old_parent

fn ah_update_vitter(inout tree: AhTree, node0: Int, just_split: Bool):
    var order = InlineArray[AhOrderedNode, MAX_NODES](fill=AhOrderedNode(-1,0,0))
    var node = node0
    var leaf_to_increment = -1
    if just_split:
        leaf_to_increment = node
        node = tree.nodes[node].parent
    else:
        ah_swap_positions(tree,node,ah_vitter_leader(tree,node,order),False)
        let parent = tree.nodes[node].parent
        if tree.nyt >= 0 and parent >= 0 and tree.nodes[tree.nyt].parent == parent:
            leaf_to_increment = node
            node = parent
    while node != tree.root: node = ah_slide_increment(tree,node,order)
    if leaf_to_increment >= 0: _ = ah_slide_increment(tree,leaf_to_increment,order)
    tree.nodes[tree.root].weight += 1

fn ah_run(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t, vitter: Bool) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT: return -1
    let n_value = input[0]
    if n_value < 0 or n_value > MAX_SYMBOLS or length != c_size_t(1+Int(n_value)): return -1
    let n = Int(n_value)
    for i in range(n):
        if input[i+1] < 0 or input[i+1] >= ALPHABET: return -1
    var tree = AhTree()
    var seen = 0
    for i in range(n):
        let symbol = Int(input[i+1])
        let is_new = tree.leaf_of[symbol] < 0
        var current = tree.nyt if is_new else tree.leaf_of[symbol]
        if current < 0: return -1
        ah_encode_path(tree,current)
        if is_new: ah_put_value(tree,symbol,4)
        var just_split = False
        if is_new:
            seen += 1
            just_split = seen < ALPHABET
            current = ah_split_nyt(tree,symbol,just_split,not vitter)
        if vitter: ah_update_vitter(tree,current,just_split)
        else: ah_update_fgk(tree,current)
    let packed = (tree.bits.count+7)//8
    let required = 8+packed
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    let count = UInt64(tree.bits.count)
    for i in range(8): output[i] = UInt8((count >> (8*i)) & 255)
    for i in range(packed): output[8+i] = tree.bits.bytes[i]
    return Int64(required)

@export("fgk_adaptive_huffman")
fn fgk_adaptive_huffman(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    return ah_run(input,length,output,capacity,False)

@export("vitter_adaptive_huffman")
fn vitter_adaptive_huffman(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    return ah_run(input,length,output,capacity,True)
