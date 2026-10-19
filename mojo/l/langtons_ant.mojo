from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("langtons_ant")
fn langtons_ant(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 1 or v[0] < 0 or v[0] > 6: return -1
    var black = InlineArray[Int64, 25](fill=0)
    for i in range(25): black[i] = 1
    var x = 2; var y = 2; var d = 3
    var dx = InlineArray[Int64, 4](fill=0); dx[0] = -1; dx[1] = 0; dx[2] = 1; dx[3] = 0
    var dy = InlineArray[Int64, 4](fill=0); dy[0] = 0; dy[1] = 1; dy[2] = 0; dy[3] = -1
    for _ in range(Int(v[0])):
        d = (d + (if black[x * 5 + y] == 0: 1 else: 3)) % 4
        let ox = x; let oy = y
        x += dx[d]; y += dy[d]
        if x < 0 or x >= 5 or y < 0 or y >= 5: return -1
        black[ox * 5 + oy] = 1 - black[ox * 5 + oy]
    var mask: Int64 = 0
    for i in range(25):
        if black[i] == 0: mask |= Int64(1) << i
    return mask | ((x * 5 + y) << 25) | (d << 30)
