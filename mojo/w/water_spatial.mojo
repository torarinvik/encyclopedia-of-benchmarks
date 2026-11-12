from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_MOLECULES = 64
alias MAX_GRID_SIDE = 8
alias MAX_CELLS = 512
alias MAX_INPUT_LENGTH = 4 + 4 * MAX_MOLECULES
alias SCALE = Int64(1_000_000)

fn water_spatial_trunc_div(numerator: Int64, denominator: Int64) -> Int64:
    if numerator < 0: return -((-numerator) // denominator)
    return numerator // denominator

fn water_spatial_store_i64(output: UnsafePointer[UInt8, MutAnyOrigin],
                            offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("water_spatial")
fn water_spatial(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT_LENGTH:
        return -1
    let count_value = input[0]
    let grid_value = input[1]
    let cutoff = input[2]
    if count_value < 0 or count_value > MAX_MOLECULES
            or grid_value < 1 or grid_value > MAX_GRID_SIDE or cutoff < 1 or cutoff > 4:
        return -1
    let count = Int(count_value)
    let grid = Int(grid_value)
    if length != c_size_t(3 + 4 * count): return -1
    let extent = Int64(grid) * cutoff
    for index in range(count):
        let base = 3 + 4 * index
        if input[base] < 0 or input[base] >= extent
                or input[base + 1] < 0 or input[base + 1] >= extent
                or input[base + 2] < 0 or input[base + 2] >= extent
                or input[base + 3] < -4 or input[base + 3] > 4:
            return -1
    let output_bytes = 8 * (3 * count + 2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2

    var head = InlineArray[Int64, MAX_CELLS]()
    var next = InlineArray[Int64, MAX_MOLECULES]()
    var force_x = InlineArray[Int64, MAX_MOLECULES]()
    var force_y = InlineArray[Int64, MAX_MOLECULES]()
    var force_z = InlineArray[Int64, MAX_MOLECULES]()
    for cell in range(MAX_CELLS): head[cell] = -1
    for index in range(count):
        let base = 3 + 4 * index
        let cx = Int(input[base] // cutoff)
        let cy = Int(input[base + 1] // cutoff)
        let cz = Int(input[base + 2] // cutoff)
        let cell = cx + grid * (cy + grid * cz)
        next[index] = head[cell]
        head[cell] = Int64(index)

    var energy: Int64 = 0
    var pairs: Int64 = 0
    let cutoff_squared = cutoff * cutoff
    for index in range(count):
        let base_i = 3 + 4 * index
        let cx = Int(input[base_i] // cutoff)
        let cy = Int(input[base_i + 1] // cutoff)
        let cz = Int(input[base_i + 2] // cutoff)
        for oz in range(-1, 2):
            let nz = cz + oz
            if nz < 0 or nz >= grid: continue
            for oy in range(-1, 2):
                let ny = cy + oy
                if ny < 0 or ny >= grid: continue
                for ox in range(-1, 2):
                    let nx = cx + ox
                    if nx < 0 or nx >= grid: continue
                    let cell = nx + grid * (ny + grid * nz)
                    var candidate = head[cell]
                    while candidate >= 0:
                        let other = Int(candidate)
                        if other > index:
                            let base_j = 3 + 4 * other
                            let dx = input[base_j] - input[base_i]
                            let dy = input[base_j + 1] - input[base_i + 1]
                            let dz = input[base_j + 2] - input[base_i + 2]
                            let r2 = dx * dx + dy * dy + dz * dz
                            if r2 < cutoff_squared:
                                let product = input[base_i + 3] * input[base_j + 3]
                                energy += water_spatial_trunc_div(
                                    product * (cutoff_squared - r2) * SCALE,
                                    (1 + r2) * (1 + cutoff_squared))
                                let denominator = (1 + r2) * (1 + r2)
                                let px = water_spatial_trunc_div(-2 * product * dx * SCALE, denominator)
                                let py = water_spatial_trunc_div(-2 * product * dy * SCALE, denominator)
                                let pz = water_spatial_trunc_div(-2 * product * dz * SCALE, denominator)
                                force_x[index] += px; force_x[other] -= px
                                force_y[index] += py; force_y[other] -= py
                                force_z[index] += pz; force_z[other] -= pz
                                pairs += 1
                        candidate = next[other]
    for index in range(count):
        water_spatial_store_i64(output, 8 * (3 * index), force_x[index])
        water_spatial_store_i64(output, 8 * (3 * index + 1), force_y[index])
        water_spatial_store_i64(output, 8 * (3 * index + 2), force_z[index])
    water_spatial_store_i64(output, 8 * (3 * count), energy)
    water_spatial_store_i64(output, 8 * (3 * count + 1), pairs)
    return Int64(output_bytes)
