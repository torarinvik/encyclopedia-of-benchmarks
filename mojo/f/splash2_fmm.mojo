from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
from math import ln, abs

alias MAX_PARTICLES = 48
alias BOXES = 16
alias ORDER = 32
alias STRIDE = ORDER + 1

@export("splash2_fmm")
fn splash2_fmm(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 7 or input_length > 145:
        return -1
    let requested = input[0]
    if requested != requested or requested < 2.0 or requested > 48.0 or Float64(Int(requested)) != requested:
        return -1
    let count = Int(requested)
    if input_length != c_size_t(1 + 3 * count): return -1

    var x = InlineArray[Float64, MAX_PARTICLES]()
    var y = InlineArray[Float64, MAX_PARTICLES]()
    var charge = InlineArray[Float64, MAX_PARTICLES]()
    var box = InlineArray[Int, MAX_PARTICLES]()
    for i in range(count):
        let px = input[1 + 3 * i]
        let py = input[2 + 3 * i]
        let q = input[3 + 3 * i]
        if px != px or px < 0.0 or px >= 8.0 or Float64(Int(px)) != px:
            return -1
        if py != py or py < 0.0 or py >= 8.0 or Float64(Int(py)) != py:
            return -1
        if q != q or q < -3.0 or q > 3.0 or Float64(Int(q)) != q:
            return -1
        x[i] = px; y[i] = py; charge[i] = q
        box[i] = (Int(py) // 2) * 4 + Int(px) // 2
        for j in range(i):
            if x[i] == x[j] and y[i] == y[j]: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < c_size_t(count):
        return -2

    var mr = InlineArray[Float64, BOXES * STRIDE]()
    var mi = InlineArray[Float64, BOXES * STRIDE]()
    var lr = InlineArray[Float64, BOXES * STRIDE]()
    var li = InlineArray[Float64, BOXES * STRIDE]()
    for i in range(count):
        let b = box[i]
        let bx = b % 4
        let by = b // 4
        let zr = x[i] - Float64(2 * bx + 1)
        let zi = y[i] - Float64(2 * by + 1)
        var pr = Float64(1.0); var pi = Float64(0.0)
        mr[b * STRIDE] = mr[b * STRIDE] + charge[i]
        for k in range(1, ORDER + 1):
            let nr = pr * zr - pi * zi
            let ni = pr * zi + pi * zr
            pr = nr; pi = ni
            mr[b * STRIDE + k] = mr[b * STRIDE + k] + charge[i] * pr
            mi[b * STRIDE + k] = mi[b * STRIDE + k] + charge[i] * pi

    for target in range(BOXES):
        let tx = target % 4; let ty = target // 4
        for source in range(BOXES):
            let sx = source % 4; let sy = source // 4
            let dbx = tx - sx; let dby = ty - sy
            if abs(dbx) <= 1 and abs(dby) <= 1: continue
            let dx = 2.0 * Float64(dbx); let dy = 2.0 * Float64(dby)
            let r2 = dx * dx + dy * dy
            var ir = InlineArray[Float64, 2 * ORDER + 1]()
            var ii = InlineArray[Float64, 2 * ORDER + 1]()
            ir[0] = 1.0
            let odr = dx / r2; let odi = -dy / r2
            for p in range(1, 2 * ORDER + 1):
                ir[p] = ir[p - 1] * odr - ii[p - 1] * odi
                ii[p] = ir[p - 1] * odi + ii[p - 1] * odr
            var constant = mr[source * STRIDE] * 0.5 * ln(r2)
            for k in range(1, ORDER + 1):
                constant = constant - (mr[source * STRIDE + k] * ir[k] - mi[source * STRIDE + k] * ii[k]) / Float64(k)
            lr[target * STRIDE] = lr[target * STRIDE] + constant
            for n in range(1, ORDER + 1):
                var sr = Float64(0.0); var si = Float64(0.0)
                for k in range(1, ORDER + 1):
                    var choose = Float64(1.0)
                    for j in range(1, n + 1):
                        choose = choose * Float64(k + j - 1) / Float64(j)
                    let scale = choose / Float64(k)
                    let p = k + n
                    sr = sr + scale * (mr[source * STRIDE + k] * ir[p] - mi[source * STRIDE + k] * ii[p])
                    si = si + scale * (mr[source * STRIDE + k] * ii[p] + mi[source * STRIDE + k] * ir[p])
                let qsign = Float64(1.0) if n % 2 == 1 else Float64(-1.0)
                let msign = Float64(-1.0) if n % 2 == 1 else Float64(1.0)
                lr[target * STRIDE + n] = lr[target * STRIDE + n] + mr[source * STRIDE] * (qsign / Float64(n)) * ir[n] - msign * sr
                li[target * STRIDE + n] = li[target * STRIDE + n] + mr[source * STRIDE] * (qsign / Float64(n)) * ii[n] - msign * si

    for i in range(count):
        let b = box[i]; let bx = b % 4; let by = b // 4
        let wr = x[i] - Float64(2 * bx + 1); let wi = y[i] - Float64(2 * by + 1)
        var pr = Float64(1.0); var pi = Float64(0.0)
        var value = lr[b * STRIDE]
        for n in range(1, ORDER + 1):
            let nr = pr * wr - pi * wi
            let ni = pr * wi + pi * wr
            pr = nr; pi = ni
            value = value + lr[b * STRIDE + n] * pr - li[b * STRIDE + n] * pi
        for j in range(count):
            if j == i: continue
            let sb = box[j]; let sx = sb % 4; let sy = sb // 4
            if abs(bx - sx) > 1 or abs(by - sy) > 1: continue
            let dx = x[j] - x[i]; let dy = y[j] - y[i]
            value = value + charge[j] * 0.5 * ln(dx * dx + dy * dy)
        output[i] = value
    return Int64(count)
