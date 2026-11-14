# Independent bounded Mason puzzle search; see the package rights notes.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn mason_move(position: Int, move: Int, upper: Bool) -> Int:
    let u0 = InlineArray[Int, 18](0, 8, 1, 2, 16, 5, 13, 7, 14, 9, 3, 4, 11, 12, 15, 10, 17, 6)
    let u2 = InlineArray[Int, 18](1, 2, 9, 10, 4, 17, 6, 0, 8, 15, 11, 12, 5, 13, 7, 14, 3, 16)
    let l0 = InlineArray[Int, 18](0, 2, 3, 10, 11, 5, 17, 7, 1, 9, 15, 12, 13, 6, 8, 14, 4, 16)
    let l2 = InlineArray[Int, 18](7, 0, 1, 16, 4, 12, 6, 14, 8, 2, 3, 10, 11, 13, 15, 9, 17, 5)
    if move == 1: return position
    if upper:
        return u0[position] if move == 0 else u2[position]
    return l0[position] if move == 0 else l2[position]

fn mason_near(state: InlineArray[Int, 9]) -> Bool:
    let masks = InlineArray[Int, 18](0x50, 0x70, 0x70, 0x75, 0x0f, 0x0f, 0x0f, 0x70, 0x70, 0x70, 0x7d, 0x2b, 0x2f, 0x0f, 0x50, 0x64, 0x67, 0x0f)
    let targets = InlineArray[Int, 9](1, 2, 4, 8, 16, 32, 64, 64, 64)
    for piece in range(9):
        if (masks[state[piece]] & targets[piece]) == 0: return False
    return True

fn mason_goal(state: InlineArray[Int, 9]) -> Bool:
    return (state[0] == 5 and state[1] == 6 and state[2] == 12 and
            state[3] == 13 and state[4] == 14 and state[5] == 15 and
            state[6] + state[7] + state[8] == 3)

fn mason_search(state: InlineArray[Int, 9], bound: Int, depth: Int, previous: Int) -> Bool:
    let upper = depth % 2 == 0
    if upper:
        if depth == bound - 4 and not mason_near(state): return False
        if mason_goal(state): return True
    if depth >= bound: return False
    for move in range(3):
        if move == previous: continue
        var next = InlineArray[Int, 9](fill=0)
        for piece in range(9):
            next[piece] = mason_move(state[piece], move, upper)
        if mason_search(next, bound, depth + 1, move): return True
    return False

@export("freebench_mason")
fn freebench_mason(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 9: return -1
    var state = InlineArray[Int, 9](fill=0)
    var seen = InlineArray[Bool, 18](fill=False)
    for piece in range(9):
        let raw = input[piece]
        if raw < 0 or raw >= 18: return -1
        let position = Int(raw)
        if seen[position]: return -1
        seen[position] = True
        state[piece] = position
    for step in range(1, 5):
        let bound = step * 2
        if mason_search(state, bound, 0, -1): return Int64(bound)
    return -2
