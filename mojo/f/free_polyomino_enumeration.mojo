from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn fp_canonical(xs: InlineArray[Int64, 8], ys: InlineArray[Int64, 8], size: Int) -> InlineArray[Int64, 8]:
    var best = InlineArray[Int64, 8](fill=0)
    var have_best = False
    for mode in range(8):
        var tx = InlineArray[Int64, 8](fill=0)
        var ty = InlineArray[Int64, 8](fill=0)
        var codes = InlineArray[Int64, 8](fill=0)
        var min_x: Int64 = 1000
        var min_y: Int64 = 1000
        for i in range(size):
            var a = ys[i] if mode >= 4 else xs[i]
            var b = xs[i] if mode >= 4 else ys[i]
            if (mode & 1) != 0: a = -a
            if (mode & 2) != 0: b = -b
            tx[i] = a
            ty[i] = b
            if a < min_x: min_x = a
            if b < min_y: min_y = b
        for i in range(size):
            codes[i] = (tx[i] - min_x) * 8 + ty[i] - min_y
            var j = i
            while j > 0 and codes[j] < codes[j - 1]:
                let temp = codes[j]
                codes[j] = codes[j - 1]
                codes[j - 1] = temp
                j -= 1
        var less = not have_best
        if have_best:
            for i in range(size):
                if codes[i] != best[i]:
                    less = codes[i] < best[i]
                    break
        if less:
            for i in range(size): best[i] = codes[i]
            have_best = True
    return best

@export("free_polyomino_enumeration")
fn free_polyomino_enumeration(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    if input[0] < 1 or input[0] > 8: return -1
    let n = Int(input[0])
    var shapes = InlineArray[Int64, 8192](fill=0)
    var current = 0
    var shape_count = 1
    var dx = InlineArray[Int, 4](fill=0)
    var dy = InlineArray[Int, 4](fill=0)
    dx[0] = 1
    dx[1] = -1
    dy[2] = 1
    dy[3] = -1
    for size in range(1, n):
        let next = 1 - current
        var next_count = 0
        for s in range(shape_count):
            for cell in range(size):
                let code = shapes[current * 4096 + s * 8 + cell]
                let x = Int(code // 8)
                let y = Int(code % 8)
                for direction in range(4):
                    let nx = x + dx[direction]
                    let ny = y + dy[direction]
                    var occupied = False
                    if 0 <= nx and nx < 8 and 0 <= ny and ny < 8:
                        let neighbor = Int64(nx * 8 + ny)
                        for i in range(size):
                            if shapes[current * 4096 + s * 8 + i] == neighbor: occupied = True
                    if occupied: continue
                    var xs = InlineArray[Int64, 8](fill=0)
                    var ys = InlineArray[Int64, 8](fill=0)
                    for i in range(size):
                        let previous = shapes[current * 4096 + s * 8 + i]
                        xs[i] = previous // 8
                        ys[i] = previous % 8
                    xs[size] = Int64(nx)
                    ys[size] = Int64(ny)
                    let candidate = fp_canonical(xs, ys, size + 1)
                    var duplicate = False
                    for old in range(next_count):
                        if not duplicate:
                            var same = True
                            for i in range(size + 1):
                                if shapes[next * 4096 + old * 8 + i] != candidate[i]: same = False
                            if same: duplicate = True
                    if not duplicate:
                        if next_count >= 512: return -1
                        for i in range(size + 1): shapes[next * 4096 + next_count * 8 + i] = candidate[i]
                        next_count += 1
        current = next
        shape_count = next_count
    return Int64(shape_count)
