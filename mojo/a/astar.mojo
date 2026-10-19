from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn astar_grid_write(output: UnsafePointer[UInt8, MutAnyOrigin], byte_offset: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8): output[byte_offset + b] = UInt8((bits >> UInt(8 * b)) & 255)

@export("astar")
fn astar(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 6: return -1
    let rows = input[0]
    let cols = input[1]
    let sx = input[2]
    let sy = input[3]
    let gx = input[4]
    let gy = input[5]
    if rows < 1 or rows > 16 or cols < 1 or cols > 16 or sx < 0 or sx >= rows or sy < 0 or sy >= cols or gx < 0 or gx >= rows or gy < 0 or gy >= cols: return -1
    var dx = List[Int](capacity=8)
    var dy = List[Int](capacity=8)
    dx.append(-1); dx.append(-1); dx.append(-1); dx.append(0); dx.append(0); dx.append(1); dx.append(1); dx.append(1)
    dy.append(-1); dy.append(0); dy.append(1); dy.append(-1); dy.append(1); dy.append(-1); dy.append(0); dy.append(1)
    var nx = List[Int64](length=256, fill=0)
    var ny = List[Int64](length=256, fill=0)
    var ng = List[Int64](length=256, fill=0)
    var nf = List[Int64](length=256, fill=0)
    var parent = List[Int64](length=256, fill=-1)
    var open = List[Int](capacity=256)
    var node_count = 1
    nx[0] = sx; ny[0] = sy; ng[0] = 0; nf[0] = 0
    open.append(0)
    var current = 0
    var found = False
    while len(open) > 0:
        var best = 0
        for i in range(1, len(open)):
            if nf[open[i]] < nf[open[best]]: best = i
        current = open[best]
        for i in range(best + 1, len(open)): open[i - 1] = open[i]
        open.pop()
        if nx[current] == gx and ny[current] == gy:
            found = True
            break
        for neighbor in range(8):
            let x = nx[current] + dx[neighbor]
            let y = ny[current] + dy[neighbor]
            if x < 0 or x >= rows or y < 0 or y >= cols: continue
            if node_count >= 256 or len(open) >= 256: return -1
            let g = ng[current] + 1
            let ex = gx - x
            let ey = gy - y
            nx[node_count] = x
            ny[node_count] = y
            ng[node_count] = g
            nf[node_count] = g + ex * ex + ey * ey
            parent[node_count] = Int64(current)
            open.append(node_count)
            node_count += 1
    if not found: return -1
    var path = List[Int](capacity=256)
    var cursor = current
    while cursor >= 0:
        path.append(cursor)
        cursor = Int(parent[cursor])
    let bytes = len(path) * 16
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(path)):
        let node = path[len(path) - 1 - i]
        astar_grid_write(output, i * 16, nx[node])
        astar_grid_write(output, i * 16 + 8, ny[node])
    return Int64(bytes)
