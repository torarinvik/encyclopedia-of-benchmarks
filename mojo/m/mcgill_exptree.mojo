from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn exptree_search(inout work: InlineArray[Int64, 8], count: Int, depth: Int, limit: Int,
                  used: Int, goal: Int64, inout best: Int64) -> Bool:
    if depth == limit:
        let value = work[count + depth - 1]
        if abs(value - goal) < abs(best - goal): best = value
        return best == goal
    for op in range(1, 5):
        for first in range(count + depth):
            if (used & (1 << first)) != 0: continue
            for second in range(first):
                if (used & (1 << second)) != 0: continue
                var left = work[first]
                var right = work[second]
                if (op == 3 or op == 4) and (left == 1 or right == 1): continue
                if left == 0 or right == 0: continue
                if op == 4 and left % right != 0: continue
                if (op == 2 or op == 4) and left < right:
                    let temp = left
                    left = right
                    right = temp
                if op == 1: work[count + depth] = left + right
                elif op == 2: work[count + depth] = left - right
                elif op == 3: work[count + depth] = left * right
                else: work[count + depth] = left // right
                if exptree_search(work, count, depth + 1, limit,
                                   used | (1 << first) | (1 << second), goal, best): return True
    return False

@export("mcgill_exptree")
fn mcgill_exptree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 6: return -1
    let goal = input[0]
    let raw_count = input[1]
    if goal < 1 or goal > 1000000000 or raw_count < 1 or raw_count > 4: return -1
    let count = Int(raw_count)
    if Int(length) != count + 2: return -1
    var work = InlineArray[Int64, 8](fill=0)
    var best: Int64 = 0
    for i in range(count):
        let value = input[2 + i]
        if value < 1 or value > 100: return -1
        work[i] = value
        if abs(value - goal) < abs(best - goal): best = value
    if best == goal: return best
    for limit in range(1, count):
        if exptree_search(work, count, 0, limit, 0, goal, best): break
    return best
