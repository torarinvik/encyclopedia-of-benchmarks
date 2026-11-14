# Independent bounded Stanford Puzzle search, attributed to Forest Baskett.
# The pinned upstream source has no explicit redistribution grant.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn puzzle_fit(board: InlineArray[Bool, 125], start: Int, dx: Int, dy: Int, dz: Int) -> Bool:
    let x0 = start % 5
    let y0 = (start // 5) % 5
    let z0 = start // 25
    if x0 + dx > 5 or y0 + dy > 5 or z0 + dz > 5: return False
    for z in range(dz):
        for y in range(dy):
            for x in range(dx):
                if board[(z0 + z) * 25 + (y0 + y) * 5 + x0 + x]: return False
    return True

fn puzzle_mark(inout board: InlineArray[Bool, 125], start: Int, dx: Int, dy: Int, dz: Int, occupied: Bool):
    let x0 = start % 5
    let y0 = (start // 5) % 5
    let z0 = start // 25
    for z in range(dz):
        for y in range(dy):
            for x in range(dx): board[(z0 + z) * 25 + (y0 + y) * 5 + x0 + x] = occupied

fn puzzle_search(inout board: InlineArray[Bool, 125], inout remaining: InlineArray[Int, 4],
                 start: Int, inout calls: Int, inout overflow: Bool) -> Bool:
    calls += 1
    if calls > 2005:
        overflow = True
        return False
    let xs = InlineArray[Int, 13](4, 2, 1, 2, 4, 1, 3, 1, 1, 2, 2, 1, 2)
    let ys = InlineArray[Int, 13](2, 1, 4, 4, 1, 2, 1, 3, 1, 2, 1, 2, 2)
    let zs = InlineArray[Int, 13](1, 4, 2, 1, 2, 4, 1, 1, 3, 1, 2, 2, 2)
    for kind in range(13):
        let group = 0 if kind < 6 else (1 if kind < 9 else (2 if kind < 12 else 3))
        if remaining[group] == 0 or not puzzle_fit(board, start, xs[kind], ys[kind], zs[kind]): continue
        puzzle_mark(board, start, xs[kind], ys[kind], zs[kind], True)
        remaining[group] -= 1
        var next = 0
        for i in range(start, 125):
            if not board[i]:
                next = i
                break
        let found = puzzle_search(board, remaining, next, calls, overflow)
        if overflow: return False
        if found or next == 0: return True
        remaining[group] += 1
        puzzle_mark(board, start, xs[kind], ys[kind], zs[kind], False)
    return False

@export("stanford_puzzle")
fn stanford_puzzle(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    if input[0] < 1 or input[0] > 100: return -1
    var checksum: Int64 = 0
    for repetition in range(Int(input[0])):
        var board = InlineArray[Bool, 125](fill=False)
        var remaining = InlineArray[Int, 4](13, 3, 1, 1)
        puzzle_mark(board, 0, 4, 2, 1, True)
        remaining[0] -= 1
        var hole = 0
        for i in range(125):
            if not board[i]:
                hole = i
                break
        if hole == 0: return -1
        var calls = 0
        var overflow = False
        if not puzzle_search(board, remaining, hole, calls, overflow) or overflow: return -1
        let source_hole = (hole % 5 + 1) + 8 * ((hole // 5) % 5 + 1) + 64 * (hole // 25 + 1)
        checksum += Int64(source_hole) * 1000000 + Int64(calls)
    return checksum
