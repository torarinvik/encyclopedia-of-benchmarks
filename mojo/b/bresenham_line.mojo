from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn bres_put_i32(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64) -> None:
    let bits = UInt32(value if value >= 0 else value + 4_294_967_296)
    for b in range(4): output[offset + b] = UInt8((bits >> (8 * b)) & 255)

@export("bresenham_line")
fn bresenham_line(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 4: return -1
    let x0 = input[0]; let y0 = input[1]; let x1 = input[2]; let y1 = input[3]
    if x0 < -1_000_000 or x0 > 1_000_000 or y0 < -1_000_000 or y0 > 1_000_000 or x1 < -1_000_000 or x1 > 1_000_000 or y1 < -1_000_000 or y1 > 1_000_000: return -1
    let dx = abs(x1 - x0); let ady = abs(y1 - y0); let steps = max(dx, ady)
    if steps > 4096: return -1
    let count = Int(steps + 1); let required = count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var x = x0; var y = y0; let sx = 1 if x0 < x1 else -1; let sy = 1 if y0 < y1 else -1
    let dy = -ady; var error = dx + dy; var index = 0
    while True:
        bres_put_i32(output, index * 8, x); bres_put_i32(output, index * 8 + 4, y); index += 1
        if x == x1 and y == y1: break
        let e2 = 2 * error
        if e2 > dy: error += dy; x += sx
        if e2 < dx: error += dx; y += sy
    return Int64(required)
