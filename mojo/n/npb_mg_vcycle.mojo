from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias SIDE = 4
alias CELLS = 64

fn _mg_index(x: Int, y: Int, z: Int, n: Int) -> Int:
    return x + n * (y + n * z)

fn _mg_stencil(src: InlineArray[Float64, CELLS], inout dst: InlineArray[Float64, CELLS],
               n: Int, center: Float64, face: Float64, edge: Float64, corner: Float64):
    for z in range(n):
        for y in range(n):
            for x in range(n):
                let q = _mg_index(x, y, z, n)
                var total = center * src[q]
                for dz in range(-1, 2):
                    for dy in range(-1, 2):
                        for dx in range(-1, 2):
                            let distance = abs(dx) + abs(dy) + abs(dz)
                            if distance == 0: continue
                            let weight = face if distance == 1 else (edge if distance == 2 else corner)
                            let neighbor = _mg_index((x+dx+n)%n, (y+dy+n)%n, (z+dz+n)%n, n)
                            total += weight * src[neighbor]
                dst[q] = total

fn _mg_restrict(fine: InlineArray[Float64, CELLS], n: Int,
                inout coarse: InlineArray[Float64, CELLS]):
    let half = n // 2
    for z in range(half):
        for y in range(half):
            for x in range(half):
                var total: Float64 = 0.0
                for dz in range(-1, 2):
                    for dy in range(-1, 2):
                        for dx in range(-1, 2):
                            let wx = 1.0 if dx == 0 else 0.5
                            let wy = 1.0 if dy == 0 else 0.5
                            let wz = 1.0 if dz == 0 else 0.5
                            let q = _mg_index((2*x+dx+n)%n, (2*y+dy+n)%n, (2*z+dz+n)%n, n)
                            total += wx * wy * wz * fine[q]
                coarse[_mg_index(x, y, z, half)] = 0.5 * total

fn _mg_interpolate(coarse: InlineArray[Float64, CELLS], half: Int,
                   inout fine: InlineArray[Float64, CELLS]):
    let n = 2 * half
    for z in range(n):
        for y in range(n):
            for x in range(n):
                let bx = x // 2; let by = y // 2; let bz = z // 2
                let nx = 2 if x % 2 == 1 else 1
                let ny = 2 if y % 2 == 1 else 1
                let nz = 2 if z % 2 == 1 else 1
                let wx = 0.5 if x % 2 == 1 else 1.0
                let wy = 0.5 if y % 2 == 1 else 1.0
                let wz = 0.5 if z % 2 == 1 else 1.0
                var total: Float64 = 0.0
                for iz in range(nz):
                    for iy in range(ny):
                        for ix in range(nx):
                            total += wx*wy*wz*coarse[_mg_index((bx+ix)%half,(by+iy)%half,(bz+iz)%half,half)]
                fine[_mg_index(x,y,z,n)] = total

fn _mg_vcycle4(rhs: InlineArray[Float64, CELLS], inout solution: InlineArray[Float64, CELLS]):
    var coarse_rhs = InlineArray[Float64, CELLS]()
    var coarse_solution = InlineArray[Float64, CELLS]()
    var prolonged = InlineArray[Float64, CELLS]()
    var applied = InlineArray[Float64, CELLS]()
    var remaining = InlineArray[Float64, CELLS]()
    var post = InlineArray[Float64, CELLS]()
    _mg_restrict(rhs, SIDE, coarse_rhs)
    _mg_stencil(coarse_rhs, coarse_solution, 2, -3.0/8.0, 1.0/32.0, -1.0/64.0, 0.0)
    _mg_interpolate(coarse_solution, 2, prolonged)
    _mg_stencil(prolonged, applied, SIDE, -8.0/3.0, 0.0, 1.0/6.0, 1.0/12.0)
    for q in range(CELLS): remaining[q] = rhs[q] - applied[q]
    _mg_stencil(remaining, post, SIDE, -3.0/8.0, 1.0/32.0, -1.0/64.0, 0.0)
    for q in range(CELLS): solution[q] = prolonged[q] + post[q]

@export("npb_mg_vcycle")
fn npb_mg_vcycle(input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
                 output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 2 or input_length > 34:
        return -1
    let iterations_value = input[0]
    let count_value = input[1]
    if iterations_value != iterations_value or count_value != count_value:
        return -1
    if iterations_value < 1.0 or iterations_value > 4.0 or count_value < 0.0 or count_value > 8.0:
        return -1
    if iterations_value != Float64(Int(iterations_value)) or count_value != Float64(Int(count_value)):
        return -1
    let iterations = Int(iterations_value)
    let count = Int(count_value)
    if input_length != c_size_t(2 + 4*count): return -1
    var rhs = InlineArray[Float64, CELLS]()
    var seen = InlineArray[Bool, CELLS]()
    for source in range(count):
        let base = 2 + 4*source
        let xv = input[base]; let yv = input[base+1]; let zv = input[base+2]; let value = input[base+3]
        if xv != xv or yv != yv or zv != zv or value != value:
            return -1
        if xv < 0.0 or xv >= 4.0 or yv < 0.0 or yv >= 4.0 or zv < 0.0 or zv >= 4.0 or value < -4.0 or value > 4.0:
            return -1
        if xv != Float64(Int(xv)) or yv != Float64(Int(yv)) or zv != Float64(Int(zv)):
            return -1
        let q = _mg_index(Int(xv), Int(yv), Int(zv), SIDE)
        if seen[q]: return -1
        seen[q] = True
        rhs[q] = value
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < 1:
        return -2
    var solution = InlineArray[Float64, CELLS]()
    var applied = InlineArray[Float64, CELLS]()
    var residual = InlineArray[Float64, CELLS]()
    var correction = InlineArray[Float64, CELLS]()
    for _ in range(iterations):
        _mg_stencil(solution, applied, SIDE, -8.0/3.0, 0.0, 1.0/6.0, 1.0/12.0)
        for q in range(CELLS): residual[q] = rhs[q] - applied[q]
        _mg_vcycle4(residual, correction)
        for q in range(CELLS): solution[q] += correction[q]
    var checksum: Float64 = 0.0
    for q in range(CELLS): checksum += solution[q]
    output[0] = checksum
    return 1
