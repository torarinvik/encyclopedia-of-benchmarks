const DEPTH: usize = 2;
const SIDE: usize = 4;
const MAX_CELLS: usize = 64;
const INVALID_RESULT: f64 = -1.0e300;

const Cell = struct { level: usize, x: usize, y: usize, z: usize };

fn cellSize(cell: Cell) usize { return @as(usize, 1) << (DEPTH - cell.level); }

fn overlapsSource(cell: Cell, sx: usize, sy: usize, sz: usize, radius: usize) bool {
    const point = [_]usize{ sx, sy, sz };
    const lower = [_]usize{ cell.x, cell.y, cell.z };
    const size = cellSize(cell);
    var squared: usize = 0;
    for (0..3) |axis| {
        var gap: usize = 0;
        if (point[axis] < lower[axis]) gap = lower[axis] - point[axis]
        else if (point[axis] > lower[axis] + size) gap = point[axis] - lower[axis] - size;
        squared += gap * gap;
    }
    return squared < radius * radius;
}

fn neighboring(a: Cell, b: Cell) bool {
    const alo = [_]usize{ a.x, a.y, a.z };
    const blo = [_]usize{ b.x, b.y, b.z };
    const asize = cellSize(a);
    const bsize = cellSize(b);
    var touching: usize = 0;
    for (0..3) |axis| {
        const ahi = alo[axis] + asize;
        const bhi = blo[axis] + bsize;
        if (ahi == blo[axis] or bhi == alo[axis]) touching += 1
        else if (ahi <= blo[axis] or bhi <= alo[axis]) return false;
    }
    return touching == 1 or touching == 2;
}

fn splitCell(cells: *[MAX_CELLS]Cell, count: *usize, index: usize) bool {
    const parent = cells[index];
    if (parent.level >= DEPTH or count.* + 7 > MAX_CELLS) return false;
    const child_size = cellSize(parent) / 2;
    var i = count.*;
    while (i > index + 1) {
        i -= 1;
        cells[i + 7] = cells[i];
    }
    var slot = index;
    for (0..2) |bz| for (0..2) |by| for (0..2) |bx| {
        cells[slot] = .{ .level = parent.level + 1, .x = parent.x + bx * child_size,
            .y = parent.y + by * child_size, .z = parent.z + bz * child_size };
        slot += 1;
    };
    count.* += 7;
    return true;
}

fn levelsTooFar(a: Cell, b: Cell) bool {
    return if (a.level > b.level) a.level - b.level > 1 else b.level - a.level > 1;
}

fn balanced(cells: *const [MAX_CELLS]Cell, count: usize) bool {
    for (0..count) |i| for (i + 1..count) |j| {
        if (neighboring(cells[i], cells[j]) and levelsTooFar(cells[i], cells[j])) return false;
    };
    return true;
}

fn balanceMesh(cells: *[MAX_CELLS]Cell, count: *usize) bool {
    while (true) {
        var coarse: ?usize = null;
        outer: for (0..count.*) |i| {
            for (i + 1..count.*) |j| {
                if (neighboring(cells[i], cells[j]) and levelsTooFar(cells[i], cells[j])) {
                    coarse = if (cells[i].level < cells[j].level) i else j;
                    break :outer;
                }
            }
        }
        if (coarse) |index| {
            if (!splitCell(cells, count, index)) return false;
        } else return true;
    }
}

fn isChild(cell: Cell, level: usize, x: usize, y: usize, z: usize, size: usize) bool {
    return cell.level == level and cell.x >= x and cell.x < x + size and
        cell.y >= y and cell.y < y + size and cell.z >= z and cell.z < z + size;
}

fn coarsenOnce(cells: *[MAX_CELLS]Cell, count: *usize, sx: usize, sy: usize, sz: usize, radius: usize) bool {
    for (0..count.*) |seed| {
        const child = cells[seed];
        if (child.level == 0) continue;
        const parent_level = child.level - 1;
        const parent_size = @as(usize, 1) << (DEPTH - parent_level);
        const child_size = parent_size / 2;
        const px = child.x / parent_size * parent_size;
        const py = child.y / parent_size * parent_size;
        const pz = child.z / parent_size * parent_size;
        const parent = Cell{ .level = parent_level, .x = px, .y = py, .z = pz };
        if (overlapsSource(parent, sx, sy, sz, radius)) continue;
        var found: [8]isize = undefined;
        for (0..8) |q| found[q] = -1;
        for (0..count.*) |i| {
            if (isChild(cells[i], child.level, px, py, pz, parent_size)) {
                const bx = (cells[i].x - px) / child_size;
                const by = (cells[i].y - py) / child_size;
                const bz = (cells[i].z - pz) / child_size;
                found[bx + 2 * by + 4 * bz] = @intCast(i);
            }
        }
        var complete = true;
        for (0..8) |q| if (found[q] < 0) { complete = false; };
        if (!complete) continue;
        var safe = true;
        for (0..count.*) |i| {
            var sibling = false;
            for (0..8) |q| if (found[q] == @as(isize, @intCast(i))) { sibling = true; };
            if (!sibling and neighboring(parent, cells[i]) and levelsTooFar(parent, cells[i])) safe = false;
        }
        if (!safe) continue;
        var compact: [MAX_CELLS]Cell = undefined;
        var compact_count: usize = 0;
        var inserted = false;
        for (0..count.*) |i| {
            var sibling = false;
            for (0..8) |q| if (found[q] == @as(isize, @intCast(i))) { sibling = true; };
            if (!sibling) {
                compact[compact_count] = cells[i];
                compact_count += 1;
            } else if (!inserted) {
                compact[compact_count] = parent;
                compact_count += 1;
                inserted = true;
            }
        }
        for (0..compact_count) |i| cells[i] = compact[i];
        count.* = compact_count;
        return true;
    }
    return false;
}

fn lessCell(a: Cell, b: Cell) bool {
    if (a.level != b.level) return a.level < b.level;
    if (a.z != b.z) return a.z < b.z;
    if (a.y != b.y) return a.y < b.y;
    return a.x < b.x;
}

export fn npb_ua_mesh_adaptation(input: ?[*]const i64, length: usize) f64 {
    const values = input orelse return INVALID_RESULT;
    if (length < 9 or length > 261) return INVALID_RESULT;
    for (0..3) |q| if (values[q] < 0 or values[q] > SIDE) return INVALID_RESULT;
    if (values[3] < 1 or values[3] > SIDE or values[4] < 1 or values[4] > MAX_CELLS) return INVALID_RESULT;
    const sx: usize = @intCast(values[0]);
    const sy: usize = @intCast(values[1]);
    const sz: usize = @intCast(values[2]);
    const radius: usize = @intCast(values[3]);
    var count: usize = @intCast(values[4]);
    if (length != 5 + 4 * count) return INVALID_RESULT;
    var cells: [MAX_CELLS]Cell = undefined;
    var covered: [MAX_CELLS]bool = [_]bool{false} ** MAX_CELLS;
    for (0..count) |i| {
        const lr = values[5 + 4 * i];
        const xr = values[6 + 4 * i];
        const yr = values[7 + 4 * i];
        const zr = values[8 + 4 * i];
        if (lr < 0 or lr > DEPTH or xr < 0 or xr > SIDE or yr < 0 or yr > SIDE or zr < 0 or zr > SIDE) return INVALID_RESULT;
        const cell = Cell{ .level = @intCast(lr), .x = @intCast(xr), .y = @intCast(yr), .z = @intCast(zr) };
        const size = cellSize(cell);
        if (cell.x + size > SIDE or cell.y + size > SIDE or cell.z + size > SIDE or
            cell.x % size != 0 or cell.y % size != 0 or cell.z % size != 0) return INVALID_RESULT;
        cells[i] = cell;
        for (cell.z..cell.z + size) |z| for (cell.y..cell.y + size) |y| for (cell.x..cell.x + size) |x| {
            const q = x + SIDE * (y + SIDE * z);
            if (covered[q]) return INVALID_RESULT;
            covered[q] = true;
        };
    }
    for (covered) |is_covered| if (!is_covered) return INVALID_RESULT;
    if (!balanced(&cells, count)) return INVALID_RESULT;
    var i: usize = 0;
    while (i < count) {
        if (cells[i].level < DEPTH and overlapsSource(cells[i], sx, sy, sz, radius)) {
            if (!splitCell(&cells, &count, i)) return INVALID_RESULT;
        } else i += 1;
    }
    if (!balanceMesh(&cells, &count)) return INVALID_RESULT;
    while (coarsenOnce(&cells, &count, sx, sy, sz, radius)) {}
    if (!balanceMesh(&cells, &count)) return INVALID_RESULT;
    for (1..count) |index| {
        const key = cells[index];
        var j = index;
        while (j > 0 and lessCell(key, cells[j - 1])) {
            cells[j] = cells[j - 1];
            j -= 1;
        }
        cells[j] = key;
    }
    var checksum: f64 = 0.0;
    for (0..count) |q| {
        const code = cells[q].level * 1000 + cells[q].x * 100 + cells[q].y * 10 + cells[q].z;
        checksum += @as(f64, @floatFromInt(q + 1)) * @as(f64, @floatFromInt(code));
    }
    return checksum;
}
