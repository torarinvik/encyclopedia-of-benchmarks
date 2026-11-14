from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn floorplan_mask_less(a: Int, b: Int, leaves: Int) -> Bool:
    for bit in range(leaves):
        let av = (a >> bit) & 1
        let bv = (b >> bit) & 1
        if av != bv: return av < bv
    return False

fn floorplan_prune(node: Int, leaves: Int, mut heights: List[Int64],
        mut widths: List[Int64], mut masks: List[Int], mut counts: List[Int]):
    let base = 256 * node
    var dominated = List[Bool](length=counts[node], fill=False)
    for i in range(counts[node]):
        for j in range(counts[node]):
            if i == j: continue
            let a = base + i; let b = base + j
            if heights[b] <= heights[a] and widths[b] <= widths[a]:
                if floorplan_mask_less(masks[b], masks[a], leaves) or (masks[b] == masks[a] and j < i):
                    dominated[i] = True
                    break
    var kept = 0
    for i in range(counts[node]):
        if not dominated[i]:
            heights[base + kept] = heights[base + i]
            widths[base + kept] = widths[base + i]
            masks[base + kept] = masks[base + i]
            kept += 1
    counts[node] = kept

@export("slicing_floorplan_stockmeyer")
fn slicing_floorplan_stockmeyer(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 32: return -1
    let leaves0 = input[0]
    if leaves0 < 1 or leaves0 > 8: return -1
    let leaves = Int(leaves0)
    var operations = List[Int](length=15, fill=-1)
    var counts = List[Int](length=15, fill=0)
    var heights = List[Int64](length=3840, fill=0)
    var widths = List[Int64](length=3840, fill=0)
    var masks = List[Int](length=3840, fill=0)
    var stack = List[Int]()
    var node = 0
    var leaf = 0
    var internal = 0
    var position = 1
    while position < Int(length):
        let token = input[position]
        position += 1
        if token == 2:
            if position + 2 > Int(length) or leaf >= leaves or node >= 15: return -1
            let h = input[position]; let w = input[position + 1]
            position += 2
            if h < 1 or h > 20 or w < 1 or w > 20: return -1
            operations[node] = 2
            let base = node * 256
            heights[base] = h; widths[base] = w
            heights[base + 1] = w; widths[base + 1] = h
            masks[base + 1] = 1 << leaf
            counts[node] = 2
            leaf += 1
        elif token == 0 or token == 1:
            if len(stack) < 2 or internal >= leaves - 1 or node >= 15: return -1
            let right = stack.pop(); let left = stack.pop()
            if operations[right] == Int(token): return -1
            operations[node] = Int(token)
            for i in range(counts[left]):
                for j in range(counts[right]):
                    if counts[node] >= 256: return -1
                    let a = left * 256 + i; let b = right * 256 + j
                    let dest = node * 256 + counts[node]
                    if token == 0:
                        heights[dest] = max(heights[a], heights[b])
                        widths[dest] = widths[a] + widths[b]
                    else:
                        heights[dest] = heights[a] + heights[b]
                        widths[dest] = max(widths[a], widths[b])
                    masks[dest] = masks[a] | masks[b]
                    counts[node] += 1
            internal += 1
        else: return -1
        floorplan_prune(node, leaves, heights, widths, masks, counts)
        stack.append(node)
        node += 1
    if leaf != leaves or internal != leaves - 1 or node != 2 * leaves - 1 or len(stack) != 1: return -1
    let root = stack[0]
    if counts[root] == 0: return -1
    var best = root * 256
    for i in range(1, counts[root]):
        let candidate = root * 256 + i
        let area = heights[candidate] * widths[candidate]
        let best_area = heights[best] * widths[best]
        if area < best_area or (area == best_area and (heights[candidate] < heights[best] or
                (heights[candidate] == heights[best] and (widths[candidate] < widths[best] or
                (widths[candidate] == widths[best] and floorplan_mask_less(masks[candidate], masks[best], leaves))))):
            best = candidate
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 32: return -2
    var words = List[Int64]()
    words.append(heights[best] * widths[best]); words.append(heights[best])
    words.append(widths[best]); words.append(Int64(masks[best]))
    for word in range(4):
        for byte in range(8): output[8 * word + byte] = UInt8((words[word] >> (8 * byte)) & 255)
    return 32
