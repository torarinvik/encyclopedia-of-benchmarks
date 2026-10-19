from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn boundary_fill_put(output: UnsafePointer[UInt8, MutAnyOrigin], index: Int, value: Int64) -> None:
    let bits = UInt64(value)
    for b in range(8): output[index * 8 + b] = UInt8((bits >> (8 * b)) & 255)

@export("boundary_fill")
fn boundary_fill(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 1030: return -1
    let wv = input[0]; let hv = input[1]; let sx = input[2]; let sy = input[3]; let color = input[4]; let boundary = input[5]
    if wv < 1 or wv > 32 or hv < 1 or hv > 32 or color < -2_147_483_648 or color > 2_147_483_647 or boundary < -2_147_483_648 or boundary > 2_147_483_647: return -1
    let w = Int(wv); let h = Int(hv); let cells = w * h
    if length != c_size_t(6 + cells) or sx < 0 or sx >= wv or sy < 0 or sy >= hv: return -1
    var image = List[Int64](capacity=cells)
    for i in range(cells):
        let v = input[6 + i]
        if v < -2_147_483_648 or v > 2_147_483_647: return -1
        image.append(v)
    let start = Int(sx) * h + Int(sy)
    if image[start] != color and image[start] != boundary:
        var stack = List[Int](capacity=cells); stack.append(start); image[start] = color
        while len(stack) > 0:
            let u = stack.pop(); let x = u // h; let y = u % h
            for dx in range(-1, 2):
                for dy in range(-1, 2):
                    if dx == 0 and dy == 0: continue
                    let nx = x + dx; let ny = y + dy
                    if nx < 0 or nx >= w or ny < 0 or ny >= h: continue
                    let v = nx * h + ny
                    if image[v] != color and image[v] != boundary: image[v] = color; stack.append(v)
    let needed = cells * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed): return -2
    for i in range(cells): boundary_fill_put(output, i, image[i])
    return Int64(needed)
