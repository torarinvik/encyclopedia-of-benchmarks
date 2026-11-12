module npb_ua_mesh_adaptation;

const int DEPTH = 2;
const int SIDE = 4;
const usz MAX_CELLS = 64;
const double INVALID_RESULT = -1.0e300;

struct Cell { int level; int x; int y; int z; }

fn int cell_size(Cell cell) { return 1 << (DEPTH - cell.level); }
fn int magnitude(int value) { return value < 0 ? -value : value; }

fn bool overlaps_source(Cell cell, int sx, int sy, int sz, int radius) {
    int[3] point = {sx, sy, sz};
    int[3] lower = {cell.x, cell.y, cell.z};
    int size = cell_size(cell), squared = 0;
    for (int axis = 0; axis < 3; axis += 1) {
        int distance = 0;
        if (point[axis] < lower[axis]) distance = lower[axis] - point[axis];
        else if (point[axis] > lower[axis] + size) distance = point[axis] - lower[axis] - size;
        squared += distance * distance;
    }
    return squared < radius * radius;
}

fn bool neighboring(Cell a, Cell b) {
    int[3] al = {a.x, a.y, a.z}, bl = {b.x, b.y, b.z};
    int as = cell_size(a), bs = cell_size(b), touching = 0;
    for (int axis = 0; axis < 3; axis += 1) {
        int ah = al[axis] + as, bh = bl[axis] + bs;
        if (ah == bl[axis] || bh == al[axis]) touching += 1;
        else if (ah <= bl[axis] || bh <= al[axis]) return false;
    }
    return touching == 1 || touching == 2;
}

fn bool split_cell(Cell* cells, usz* count, usz index) {
    Cell parent = cells[index];
    if (parent.level >= DEPTH || *count + 7 > MAX_CELLS) return false;
    int child_size = cell_size(parent) / 2;
    usz i = *count;
    while (i > index + 1) { i -= 1; cells[i + 7] = cells[i]; }
    usz slot = index;
    for (int bz = 0; bz < 2; bz += 1) for (int by = 0; by < 2; by += 1) for (int bx = 0; bx < 2; bx += 1) {
        cells[slot] = {parent.level + 1, parent.x + bx * child_size, parent.y + by * child_size, parent.z + bz * child_size};
        slot += 1;
    }
    *count += 7;
    return true;
}

fn bool balanced(Cell* cells, usz count) {
    for (usz i = 0; i < count; i += 1) for (usz j = i + 1; j < count; j += 1) {
        if (neighboring(cells[i], cells[j]) && magnitude(cells[i].level - cells[j].level) > 1) return false;
    }
    return true;
}

fn bool balance_mesh(Cell* cells, usz* count) {
    while (true) {
        long coarse = -1;
        for (usz i = 0; i < *count && coarse < 0; i += 1) for (usz j = i + 1; j < *count; j += 1) {
            if (!neighboring(cells[i], cells[j]) || magnitude(cells[i].level - cells[j].level) <= 1) continue;
            coarse = cells[i].level < cells[j].level ? (long)i : (long)j;
            break;
        }
        if (coarse < 0) return true;
        if (!split_cell(cells, count, (usz)coarse)) return false;
    }
}

fn bool is_child(Cell cell, int level, int x, int y, int z, int size) {
    return cell.level == level && cell.x >= x && cell.x < x + size && cell.y >= y && cell.y < y + size && cell.z >= z && cell.z < z + size;
}

fn bool coarsen_once(Cell* cells, usz* count, int sx, int sy, int sz, int radius) {
    for (usz seed = 0; seed < *count; seed += 1) {
        Cell child = cells[seed];
        if (child.level == 0) continue;
        int parent_level = child.level - 1;
        int parent_size = 1 << (DEPTH - parent_level), child_size = parent_size / 2;
        int px = child.x / parent_size * parent_size;
        int py = child.y / parent_size * parent_size;
        int pz = child.z / parent_size * parent_size;
        Cell parent = {parent_level, px, py, pz};
        if (overlaps_source(parent, sx, sy, sz, radius)) continue;
        int[8] found; for (int q = 0; q < 8; q += 1) found[q] = -1;
        for (usz i = 0; i < *count; i += 1) if (is_child(cells[i], child.level, px, py, pz, parent_size)) {
            int bx = (cells[i].x - px) / child_size, by = (cells[i].y - py) / child_size, bz = (cells[i].z - pz) / child_size;
            found[bx + 2 * by + 4 * bz] = (int)i;
        }
        bool complete = true;
        for (int q = 0; q < 8; q += 1) if (found[q] < 0) complete = false;
        if (!complete) continue;
        bool safe = true;
        for (usz i = 0; i < *count; i += 1) {
            bool sibling = false;
            for (int q = 0; q < 8; q += 1) if (found[q] == (int)i) sibling = true;
            if (!sibling && neighboring(parent, cells[i]) && magnitude(parent_level - cells[i].level) > 1) safe = false;
        }
        if (!safe) continue;
        Cell[64] compact = zeroed; usz compact_count = 0; bool inserted = false;
        for (usz i = 0; i < *count; i += 1) {
            bool sibling = false;
            for (int q = 0; q < 8; q += 1) if (found[q] == (int)i) sibling = true;
            if (!sibling) { compact[compact_count] = cells[i]; compact_count += 1; }
            else if (!inserted) { compact[compact_count] = parent; compact_count += 1; inserted = true; }
        }
        for (usz i = 0; i < compact_count; i += 1) cells[i] = compact[i];
        *count = compact_count;
        return true;
    }
    return false;
}

fn bool less_cell(Cell a, Cell b) {
    if (a.level != b.level) return a.level < b.level;
    if (a.z != b.z) return a.z < b.z;
    if (a.y != b.y) return a.y < b.y;
    return a.x < b.x;
}

fn double npb_ua_mesh_adaptation(long* input, usz length) @export("npb_ua_mesh_adaptation") {
    if (input == null || length < 9 || length > 261) return INVALID_RESULT;
    for (int q = 0; q < 3; q += 1) if (input[q] < 0 || input[q] > SIDE) return INVALID_RESULT;
    if (input[3] < 1 || input[3] > SIDE || input[4] < 1 || input[4] > 64) return INVALID_RESULT;
    int sx = (int)input[0], sy = (int)input[1], sz = (int)input[2], radius = (int)input[3];
    usz count = (usz)input[4];
    if (length != 5 + 4 * count) return INVALID_RESULT;
    Cell[64] cells = zeroed; bool[64] covered = zeroed;
    for (usz i = 0; i < count; i += 1) {
        long lr = input[5 + 4 * i], xr = input[6 + 4 * i], yr = input[7 + 4 * i], zr = input[8 + 4 * i];
        if (lr < 0 || lr > DEPTH || xr < 0 || xr > SIDE || yr < 0 || yr > SIDE || zr < 0 || zr > SIDE) return INVALID_RESULT;
        Cell cell = {(int)lr, (int)xr, (int)yr, (int)zr};
        int size = cell_size(cell);
        if (cell.x + size > SIDE || cell.y + size > SIDE || cell.z + size > SIDE || cell.x % size != 0 || cell.y % size != 0 || cell.z % size != 0) return INVALID_RESULT;
        cells[i] = cell;
        for (int z = cell.z; z < cell.z + size; z += 1) for (int y = cell.y; y < cell.y + size; y += 1) for (int x = cell.x; x < cell.x + size; x += 1) {
            usz q = (usz)(x + SIDE * (y + SIDE * z)); if (covered[q]) return INVALID_RESULT; covered[q] = true;
        }
    }
    for (usz q = 0; q < 64; q += 1) if (!covered[q]) return INVALID_RESULT;
    if (!balanced(&cells[0], count)) return INVALID_RESULT;
    usz i = 0;
    while (i < count) {
        if (cells[i].level < DEPTH && overlaps_source(cells[i], sx, sy, sz, radius)) {
            if (!split_cell(&cells[0], &count, i)) return INVALID_RESULT;
        } else i += 1;
    }
    if (!balance_mesh(&cells[0], &count)) return INVALID_RESULT;
    while (coarsen_once(&cells[0], &count, sx, sy, sz, radius)) { }
    if (!balance_mesh(&cells[0], &count)) return INVALID_RESULT;
    for (usz a = 1; a < count; a += 1) {
        Cell key = cells[a]; usz j = a;
        while (j > 0 && less_cell(key, cells[j - 1])) { cells[j] = cells[j - 1]; j -= 1; }
        cells[j] = key;
    }
    double checksum = 0.0;
    for (usz q = 0; q < count; q += 1) {
        int code = cells[q].level * 1000 + cells[q].x * 100 + cells[q].y * 10 + cells[q].z;
        checksum += (double)(q + 1) * (double)code;
    }
    return checksum;
}
