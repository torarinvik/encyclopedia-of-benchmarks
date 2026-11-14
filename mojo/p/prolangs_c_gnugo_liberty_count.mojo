# GNU Go 1.1, Copyright Free Software Foundation; Man L. Li, Wayne Iba, Bob Webber.
# This independently written derivative is licensed under GPL version 1; see LICENSE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("prolangs_c_gnugo_liberty_count")
fn prolangs_c_gnugo_liberty_count(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 726: return -1
    let row = input[0]; let column = input[1]; let color = input[2]; let count = input[3]
    if row < 0 or row >= 19 or column < 0 or column >= 19 or (color != 1 and color != 2) or count < 0 or count > 361: return -1
    if length != c_size_t(4+2*Int(count)): return -1
    var board = List[Int](length=361, fill=0)
    for i in range(Int(count)):
        let position = input[4+2*i]; let stone = input[5+2*i]
        if position < 0 or position >= 361 or (stone != 1 and stone != 2): return -1
        if board[Int(position)] != 0: return -1
        board[Int(position)] = Int(stone)
    let start = Int(row*19+column)
    if board[start] != Int(color): return -1
    var seen = List[Bool](length=361, fill=False)
    var liberties = List[Bool](length=361, fill=False)
    var stack = List[Int](capacity=361)
    stack.append(start); seen[start] = True
    var total = Int64(0)
    while len(stack) > 0:
        let position = stack.pop()
        let r = position//19; let c = position%19
        var neighbors = List[Int](capacity=4)
        if r > 0: neighbors.append(position-19)
        if r < 18: neighbors.append(position+19)
        if c > 0: neighbors.append(position-1)
        if c < 18: neighbors.append(position+1)
        for next in neighbors:
            if board[next] == 0:
                if not liberties[next]:
                    liberties[next] = True
                    total += 1
            elif board[next] == Int(color) and not seen[next]:
                seen[next] = True
                stack.append(next)
    return total
