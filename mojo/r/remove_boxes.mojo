from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

const MAX_BOXES = 18
const MAX_PARSEABLE_LENGTH = MAX_BOXES + 2

fn remove_boxes_solve(left: Int, right: Int, carry: Int, colors: List[Int],
                      counts: List[Int], mut memo: List[Int64]) -> Int64:
    if left > right: return 0
    let index = (left * MAX_BOXES + right) * (MAX_BOXES + 1) + carry
    if memo[index] >= 0: return memo[index]
    let attached = counts[left] + carry
    var best = Int64(attached * attached) + remove_boxes_solve(
        left + 1, right, 0, colors, counts, mut memo)
    for later in range(left + 1, right + 1):
        if colors[later] == colors[left]:
            let joined = (remove_boxes_solve(left + 1, later - 1, 0, colors, counts, mut memo)
                + remove_boxes_solve(later, right, attached, colors, counts, mut memo))
            if joined > best: best = joined
    memo[index] = best
    return best

@export("remove_boxes")
fn remove_boxes(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    if values[0] < 0 or values[0] > Int64(MAX_BOXES): return -1
    let n = Int(values[0])
    if length != c_size_t(n + 1): return -1
    var colors = List[Int](length=MAX_BOXES, fill=0)
    var counts = List[Int](length=MAX_BOXES, fill=0)
    var groups = 0
    for index in range(n):
        let raw_color = values[index + 1]
        if raw_color < 0 or raw_color > 7: return -1
        let color = Int(raw_color)
        if groups > 0 and colors[groups - 1] == color:
            counts[groups - 1] += 1
        else:
            colors[groups] = color
            counts[groups] = 1
            groups += 1
    if groups == 0: return 0
    var memo = List[Int64](length=MAX_BOXES * MAX_BOXES * (MAX_BOXES + 1), fill=-1)
    return remove_boxes_solve(0, groups - 1, 0, colors, counts, mut memo)
