# GNU Go 1.1, Copyright Free Software Foundation; Man L. Li, Wayne Iba, Bob Webber.
# This independently written derivative is licensed under GPL version 1; see LICENSE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn suicide_liberties(board: List[Int], start: Int, color: Int) -> Int:
    var seen = List[Bool](length=361, fill=False)
    var liberty = List[Bool](length=361, fill=False)
    var stack = List[Int](capacity=361)
    stack.append(start); seen[start] = True
    var count = 0
    while len(stack) > 0:
        let position = stack.pop()
        let row = position//19; let column = position%19
        var neighbors = List[Int](capacity=4)
        if row > 0: neighbors.append(position-19)
        if row < 18: neighbors.append(position+19)
        if column > 0: neighbors.append(position-1)
        if column < 18: neighbors.append(position+1)
        for next in neighbors:
            if board[next] == 0:
                if not liberty[next]: liberty[next] = True; count += 1
            elif board[next] == color and not seen[next]:
                seen[next] = True; stack.append(next)
    return count

@export("prolangs_c_gnugo_suicide")
fn prolangs_c_gnugo_suicide(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 246: return -1
    let row = input[0]; let column = input[1]; let own = input[2]; let opponent = input[3]; let ko = input[4]; let count = input[5]
    if row < 0 or row >= 19 or column < 0 or column >= 19 or (own != 1 and own != 2) or (opponent != 1 and opponent != 2) or own == opponent or ko < -1 or ko >= 361 or count < 0 or count > 120: return -1
    if length != c_size_t(6+2*Int(count)): return -1
    var board = List[Int](length=361, fill=0)
    for i in range(Int(count)):
        let position = input[6+2*i]; let color = input[7+2*i]
        if position < 0 or position >= 361 or (color != 1 and color != 2): return -1
        if board[Int(position)] != 0: return -1
        board[Int(position)] = Int(color)
    let target = Int(row*19+column)
    if board[target] != 0: return -1
    board[target] = Int(opponent)
    if suicide_liberties(board,target,Int(opponent)) > 0: return 0
    var dead = 0
    for i in range(361):
        if board[i] == Int(own) and suicide_liberties(board,i,Int(own)) == 0: dead += 1
    if dead == 0 or (dead == 1 and ko == Int64(target)): return 1
    return 0
