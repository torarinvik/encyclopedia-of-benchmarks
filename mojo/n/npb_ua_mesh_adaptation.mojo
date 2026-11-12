from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime DEPTH = 2
comptime SIDE = 4
comptime MAX_CELLS = 64
comptime INVALID_RESULT: Float64 = -1e300


@fieldwise_init
struct Cell:
    var level: Int
    var x: Int
    var y: Int
    var z: Int


fn cell_size(cell: Cell) -> Int:
    return 1 << (DEPTH - cell.level)


fn overlaps_source(cell: Cell, sx: Int, sy: Int, sz: Int, radius: Int) -> Bool:
    let point = InlineArray[Int, 3](sx, sy, sz)
    let lower = InlineArray[Int, 3](cell.x, cell.y, cell.z)
    let size = cell_size(cell)
    var squared = 0
    for axis in range(3):
        var gap = 0
        if point[axis] < lower[axis]:
            gap = lower[axis] - point[axis]
        elif point[axis] > lower[axis] + size:
            gap = point[axis] - lower[axis] - size
        squared += gap * gap
    return squared < radius * radius


fn neighboring(a: Cell, b: Cell) -> Bool:
    let alo = InlineArray[Int, 3](a.x, a.y, a.z)
    let blo = InlineArray[Int, 3](b.x, b.y, b.z)
    let asize = cell_size(a)
    let bsize = cell_size(b)
    var touching = 0
    for axis in range(3):
        let ahi = alo[axis] + asize
        let bhi = blo[axis] + bsize
        if ahi == blo[axis] or bhi == alo[axis]:
            touching += 1
        elif ahi <= blo[axis] or bhi <= alo[axis]:
            return False
    return touching == 1 or touching == 2


fn levels_too_far(a: Cell, b: Cell) -> Bool:
    if a.level > b.level:
        return a.level - b.level > 1
    return b.level - a.level > 1


fn split_cell(mut cells: InlineArray[Cell, 64], mut count: Int, index: Int) -> Bool:
    let parent = cells[index]
    if parent.level >= DEPTH or count + 7 > MAX_CELLS:
        return False
    let child_size = cell_size(parent) // 2
    var i = count
    while i > index + 1:
        i -= 1
        cells[i + 7] = cells[i]
    var slot = index
    for bz in range(2):
        for by in range(2):
            for bx in range(2):
                cells[slot] = Cell(level=parent.level + 1, x=parent.x + bx * child_size,
                    y=parent.y + by * child_size, z=parent.z + bz * child_size)
                slot += 1
    count += 7
    return True


fn balanced(cells: InlineArray[Cell, 64], count: Int) -> Bool:
    for i in range(count):
        for j in range(i + 1, count):
            if neighboring(cells[i], cells[j]) and levels_too_far(cells[i], cells[j]):
                return False
    return True


fn balance_mesh(mut cells: InlineArray[Cell, 64], mut count: Int) -> Bool:
    while True:
        var coarse = -1
        for i in range(count):
            if coarse >= 0:
                break
            for j in range(i + 1, count):
                if neighboring(cells[i], cells[j]) and levels_too_far(cells[i], cells[j]):
                    coarse = i if cells[i].level < cells[j].level else j
                    break
        if coarse < 0:
            return True
        if not split_cell(mut cells, mut count, coarse):
            return False
    return True


fn is_child(cell: Cell, level: Int, x: Int, y: Int, z: Int, size: Int) -> Bool:
    return cell.level == level and cell.x >= x and cell.x < x + size and cell.y >= y and cell.y < y + size and cell.z >= z and cell.z < z + size


fn coarsen_once(mut cells: InlineArray[Cell, 64], mut count: Int,
                sx: Int, sy: Int, sz: Int, radius: Int) -> Bool:
    for seed in range(count):
        let child = cells[seed]
        if child.level == 0:
            continue
        let parent_level = child.level - 1
        let parent_size = 1 << (DEPTH - parent_level)
        let child_size = parent_size // 2
        let px = child.x // parent_size * parent_size
        let py = child.y // parent_size * parent_size
        let pz = child.z // parent_size * parent_size
        let parent = Cell(level=parent_level, x=px, y=py, z=pz)
        if overlaps_source(parent, sx, sy, sz, radius):
            continue
        var found = InlineArray[Int, 8](fill=-1)
        for i in range(count):
            if is_child(cells[i], child.level, px, py, pz, parent_size):
                let bx = (cells[i].x - px) // child_size
                let by = (cells[i].y - py) // child_size
                let bz = (cells[i].z - pz) // child_size
                found[bx + 2 * by + 4 * bz] = i
        var complete = True
        for q in range(8):
            if found[q] < 0:
                complete = False
        if not complete:
            continue
        var safe = True
        for i in range(count):
            var sibling = False
            for q in range(8):
                if found[q] == i:
                    sibling = True
            if not sibling and neighboring(parent, cells[i]) and levels_too_far(parent, cells[i]):
                safe = False
        if not safe:
            continue
        var compact = InlineArray[Cell, 64](fill=Cell(level=0, x=0, y=0, z=0))
        var compact_count = 0
        var inserted = False
        for i in range(count):
            var sibling = False
            for q in range(8):
                if found[q] == i:
                    sibling = True
            if not sibling:
                compact[compact_count] = cells[i]
                compact_count += 1
            elif not inserted:
                compact[compact_count] = parent
                compact_count += 1
                inserted = True
        for i in range(compact_count):
            cells[i] = compact[i]
        count = compact_count
        return True
    return False


fn less_cell(a: Cell, b: Cell) -> Bool:
    if a.level != b.level:
        return a.level < b.level
    if a.z != b.z:
        return a.z < b.z
    if a.y != b.y:
        return a.y < b.y
    return a.x < b.x


@export("npb_ua_mesh_adaptation")
fn npb_ua_mesh_adaptation(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 9 or length > c_size_t(261):
        return INVALID_RESULT
    for q in range(3):
        if input[q] < 0 or input[q] > SIDE:
            return INVALID_RESULT
    if input[3] < 1 or input[3] > SIDE or input[4] < 1 or input[4] > MAX_CELLS:
        return INVALID_RESULT
    let sx = Int(input[0])
    let sy = Int(input[1])
    let sz = Int(input[2])
    let radius = Int(input[3])
    var count = Int(input[4])
    if Int(length) != 5 + 4 * count:
        return INVALID_RESULT

    var cells = InlineArray[Cell, 64](fill=Cell(level=0, x=0, y=0, z=0))
    var covered = InlineArray[Bool, 64](fill=False)
    for i in range(count):
        let lr = input[5 + 4 * i]
        let xr = input[6 + 4 * i]
        let yr = input[7 + 4 * i]
        let zr = input[8 + 4 * i]
        if lr < 0 or lr > DEPTH or xr < 0 or xr > SIDE or yr < 0 or yr > SIDE or zr < 0 or zr > SIDE:
            return INVALID_RESULT
        let cell = Cell(level=Int(lr), x=Int(xr), y=Int(yr), z=Int(zr))
        let size = cell_size(cell)
        if cell.x + size > SIDE or cell.y + size > SIDE or cell.z + size > SIDE or
            cell.x % size != 0 or cell.y % size != 0 or cell.z % size != 0:
            return INVALID_RESULT
        cells[i] = cell
        for z in range(cell.z, cell.z + size):
            for y in range(cell.y, cell.y + size):
                for x in range(cell.x, cell.x + size):
                    let q = x + SIDE * (y + SIDE * z)
                    if covered[q]:
                        return INVALID_RESULT
                    covered[q] = True
    for q in range(MAX_CELLS):
        if not covered[q]:
            return INVALID_RESULT
    if not balanced(cells, count):
        return INVALID_RESULT
    var i = 0
    while i < count:
        if cells[i].level < DEPTH and overlaps_source(cells[i], sx, sy, sz, radius):
            if not split_cell(mut cells, mut count, i):
                return INVALID_RESULT
        else:
            i += 1
    if not balance_mesh(mut cells, mut count):
        return INVALID_RESULT
    while coarsen_once(mut cells, mut count, sx, sy, sz, radius):
        pass
    if not balance_mesh(mut cells, mut count):
        return INVALID_RESULT
    for i in range(1, count):
        let key = cells[i]
        var j = i
        while j > 0 and less_cell(key, cells[j - 1]):
            cells[j] = cells[j - 1]
            j -= 1
        cells[j] = key
    var checksum = Float64(0.0)
    for q in range(count):
        let code = cells[q].level * 1000 + cells[q].x * 100 + cells[q].y * 10 + cells[q].z
        checksum += Float64(q + 1) * Float64(code)
    return checksum
