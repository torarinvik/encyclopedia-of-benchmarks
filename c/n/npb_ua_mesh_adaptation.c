#include <stddef.h>
#include <stdint.h>

#define UA_DEPTH 2
#define UA_SIDE 4
#define UA_MAX_CELLS 64
#define UA_MAX_INPUT_LENGTH 261
#define UA_INVALID (-1.0e300)

typedef struct { int level, x, y, z; } UaCell;

static int cell_size(UaCell cell) { return 1 << (UA_DEPTH - cell.level); }
static int int_abs(int value) { return value < 0 ? -value : value; }

static int overlaps_source(UaCell cell, int sx, int sy, int sz, int radius) {
    int size = cell_size(cell);
    int centers[3] = {sx, sy, sz};
    int lower[3] = {cell.x, cell.y, cell.z};
    int distance_squared = 0;
    for (int axis = 0; axis < 3; ++axis) {
        int distance = 0;
        if (centers[axis] < lower[axis]) distance = lower[axis] - centers[axis];
        else if (centers[axis] > lower[axis] + size) distance = centers[axis] - lower[axis] - size;
        distance_squared += distance * distance;
    }
    return distance_squared < radius * radius;
}

static int neighboring(UaCell a, UaCell b) {
    int al[3] = {a.x, a.y, a.z}, bl[3] = {b.x, b.y, b.z};
    int as = cell_size(a), bs = cell_size(b), touching = 0;
    for (int axis = 0; axis < 3; ++axis) {
        int ah = al[axis] + as, bh = bl[axis] + bs;
        if (ah == bl[axis] || bh == al[axis]) ++touching;
        else if (ah <= bl[axis] || bh <= al[axis]) return 0;
    }
    return touching == 1 || touching == 2;
}

static int split_cell(UaCell cells[UA_MAX_CELLS], int *count, int index) {
    UaCell parent = cells[index];
    if (parent.level >= UA_DEPTH || *count + 7 > UA_MAX_CELLS) return 0;
    int child_size = cell_size(parent) / 2;
    for (int i = *count - 1; i > index; --i) cells[i + 7] = cells[i];
    int slot = index;
    for (int bz = 0; bz < 2; ++bz) for (int by = 0; by < 2; ++by) for (int bx = 0; bx < 2; ++bx) {
        cells[slot++] = (UaCell){parent.level + 1, parent.x + bx * child_size,
                                 parent.y + by * child_size, parent.z + bz * child_size};
    }
    *count += 7;
    return 1;
}

static int balanced(UaCell cells[UA_MAX_CELLS], int count) {
    for (int i = 0; i < count; ++i) for (int j = i + 1; j < count; ++j) {
        if (neighboring(cells[i], cells[j]) && int_abs(cells[i].level - cells[j].level) > 1) return 0;
    }
    return 1;
}

static int balance_mesh(UaCell cells[UA_MAX_CELLS], int *count) {
    for (;;) {
        int coarse = -1;
        for (int i = 0; i < *count && coarse < 0; ++i) for (int j = i + 1; j < *count; ++j) {
            if (!neighboring(cells[i], cells[j]) || int_abs(cells[i].level - cells[j].level) <= 1) continue;
            coarse = cells[i].level < cells[j].level ? i : j;
            break;
        }
        if (coarse < 0) return 1;
        if (!split_cell(cells, count, coarse)) return 0;
    }
}

static int is_child(UaCell cell, int level, int x, int y, int z, int size) {
    return cell.level == level && cell.x >= x && cell.x < x + size &&
        cell.y >= y && cell.y < y + size && cell.z >= z && cell.z < z + size;
}

static int coarsen_once(UaCell cells[UA_MAX_CELLS], int *count, int sx, int sy, int sz, int radius) {
    for (int seed = 0; seed < *count; ++seed) {
        UaCell child = cells[seed];
        if (child.level == 0) continue;
        int parent_level = child.level - 1;
        int parent_size = 1 << (UA_DEPTH - parent_level);
        int child_size = parent_size / 2;
        int px = (child.x / parent_size) * parent_size;
        int py = (child.y / parent_size) * parent_size;
        int pz = (child.z / parent_size) * parent_size;
        UaCell parent = {parent_level, px, py, pz};
        if (overlaps_source(parent, sx, sy, sz, radius)) continue;
        int found[8];
        for (int q = 0; q < 8; ++q) found[q] = -1;
        for (int i = 0; i < *count; ++i) if (is_child(cells[i], child.level, px, py, pz, parent_size)) {
            int bx = (cells[i].x - px) / child_size;
            int by = (cells[i].y - py) / child_size;
            int bz = (cells[i].z - pz) / child_size;
            found[bx + 2 * by + 4 * bz] = i;
        }
        int complete = 1;
        for (int q = 0; q < 8; ++q) if (found[q] < 0) complete = 0;
        if (!complete) continue;
        int safe = 1;
        for (int i = 0; i < *count; ++i) {
            int sibling = 0;
            for (int q = 0; q < 8; ++q) if (found[q] == i) sibling = 1;
            if (!sibling && neighboring(parent, cells[i]) && int_abs(parent_level - cells[i].level) > 1) safe = 0;
        }
        if (!safe) continue;
        UaCell compact[UA_MAX_CELLS];
        int compact_count = 0, inserted = 0;
        for (int i = 0; i < *count; ++i) {
            int sibling = 0;
            for (int q = 0; q < 8; ++q) if (found[q] == i) sibling = 1;
            if (!sibling) compact[compact_count++] = cells[i];
            else if (!inserted) { compact[compact_count++] = parent; inserted = 1; }
        }
        for (int i = 0; i < compact_count; ++i) cells[i] = compact[i];
        *count = compact_count;
        return 1;
    }
    return 0;
}

static int less_cell(UaCell a, UaCell b) {
    if (a.level != b.level) return a.level < b.level;
    if (a.z != b.z) return a.z < b.z;
    if (a.y != b.y) return a.y < b.y;
    return a.x < b.x;
}

double npb_ua_mesh_adaptation(const int64_t *input, size_t length) {
    if (input == NULL || length < 9 || length > UA_MAX_INPUT_LENGTH) return UA_INVALID;
    if (input[0] < 0 || input[0] > UA_SIDE || input[1] < 0 || input[1] > UA_SIDE ||
        input[2] < 0 || input[2] > UA_SIDE || input[3] < 1 || input[3] > UA_SIDE ||
        input[4] < 1 || input[4] > UA_MAX_CELLS) return UA_INVALID;
    int sx = (int)input[0], sy = (int)input[1], sz = (int)input[2], radius = (int)input[3];
    int raw_count = (int)input[4];
    int count = raw_count;
    if (length != (size_t)(5 + 4 * count)) return UA_INVALID;
    UaCell cells[UA_MAX_CELLS];
    int covered[UA_SIDE * UA_SIDE * UA_SIDE] = {0};
    for (int i = 0; i < count; ++i) {
        int64_t level_raw = input[5 + 4 * i];
        int64_t x_raw = input[6 + 4 * i], y_raw = input[7 + 4 * i], z_raw = input[8 + 4 * i];
        if (level_raw < 0 || level_raw > UA_DEPTH || x_raw < 0 || x_raw > UA_SIDE ||
            y_raw < 0 || y_raw > UA_SIDE || z_raw < 0 || z_raw > UA_SIDE) return UA_INVALID;
        int level = (int)level_raw, x = (int)x_raw, y = (int)y_raw, z = (int)z_raw;
        UaCell cell = {level, x, y, z};
        int size = cell_size(cell);
        if (x < 0 || y < 0 || z < 0 || x + size > UA_SIDE || y + size > UA_SIDE || z + size > UA_SIDE ||
            x % size != 0 || y % size != 0 || z % size != 0) return UA_INVALID;
        cells[i] = cell;
        for (int dz = z; dz < z + size; ++dz) for (int dy = y; dy < y + size; ++dy) for (int dx = x; dx < x + size; ++dx) {
            int q = dx + UA_SIDE * (dy + UA_SIDE * dz);
            if (covered[q]) return UA_INVALID;
            covered[q] = 1;
        }
    }
    for (int q = 0; q < UA_SIDE * UA_SIDE * UA_SIDE; ++q) if (!covered[q]) return UA_INVALID;
    if (!balanced(cells, count)) return UA_INVALID;

    for (int i = 0; i < count;) {
        if (cells[i].level < UA_DEPTH && overlaps_source(cells[i], sx, sy, sz, radius)) {
            if (!split_cell(cells, &count, i)) return UA_INVALID;
        } else ++i;
    }
    if (!balance_mesh(cells, &count)) return UA_INVALID;
    while (coarsen_once(cells, &count, sx, sy, sz, radius)) { }
    if (!balance_mesh(cells, &count)) return UA_INVALID;

    for (int i = 1; i < count; ++i) {
        UaCell key = cells[i];
        int j = i;
        while (j > 0 && less_cell(key, cells[j - 1])) { cells[j] = cells[j - 1]; --j; }
        cells[j] = key;
    }
    double checksum = 0.0;
    for (int i = 0; i < count; ++i) {
        int code = cells[i].level * 1000 + cells[i].x * 100 + cells[i].y * 10 + cells[i].z;
        checksum += (double)(i + 1) * (double)code;
    }
    return checksum;
}
