#include <cstddef>
#include <cstdint>
#include <cstdlib>

namespace {
constexpr int kDepth = 2;
constexpr int kSide = 4;
constexpr int kMaxCells = 64;
constexpr std::size_t kMaxInputLength = 261;
constexpr double kInvalid = -1.0e300;
struct Cell { int level, x, y, z; };

int cell_size(Cell cell) { return 1 << (kDepth - cell.level); }
int magnitude(int value) { return value < 0 ? -value : value; }

bool overlaps_source(Cell cell, int sx, int sy, int sz, int radius) {
    const int point[3] = {sx, sy, sz};
    const int lower[3] = {cell.x, cell.y, cell.z};
    const int size = cell_size(cell);
    int distance_squared = 0;
    for (int axis = 0; axis < 3; ++axis) {
        int distance = 0;
        if (point[axis] < lower[axis]) distance = lower[axis] - point[axis];
        else if (point[axis] > lower[axis] + size) distance = point[axis] - lower[axis] - size;
        distance_squared += distance * distance;
    }
    return distance_squared < radius * radius;
}

bool neighboring(Cell a, Cell b) {
    const int alo[3] = {a.x, a.y, a.z}, blo[3] = {b.x, b.y, b.z};
    const int as = cell_size(a), bs = cell_size(b);
    int touching = 0;
    for (int axis = 0; axis < 3; ++axis) {
        const int ah = alo[axis] + as, bh = blo[axis] + bs;
        if (ah == blo[axis] || bh == alo[axis]) ++touching;
        else if (ah <= blo[axis] || bh <= alo[axis]) return false;
    }
    return touching == 1 || touching == 2;
}

bool split_cell(Cell cells[kMaxCells], int& count, int index) {
    const Cell parent = cells[index];
    if (parent.level >= kDepth || count + 7 > kMaxCells) return false;
    const int child_size = cell_size(parent) / 2;
    for (int i = count - 1; i > index; --i) cells[i + 7] = cells[i];
    int slot = index;
    for (int bz = 0; bz < 2; ++bz) for (int by = 0; by < 2; ++by) for (int bx = 0; bx < 2; ++bx) {
        cells[slot++] = {parent.level + 1, parent.x + bx * child_size,
                         parent.y + by * child_size, parent.z + bz * child_size};
    }
    count += 7;
    return true;
}

bool balanced(const Cell cells[kMaxCells], int count) {
    for (int i = 0; i < count; ++i) for (int j = i + 1; j < count; ++j) {
        if (neighboring(cells[i], cells[j]) && magnitude(cells[i].level - cells[j].level) > 1) return false;
    }
    return true;
}

bool balance_mesh(Cell cells[kMaxCells], int& count) {
    for (;;) {
        int coarse = -1;
        for (int i = 0; i < count && coarse < 0; ++i) for (int j = i + 1; j < count; ++j) {
            if (!neighboring(cells[i], cells[j]) || magnitude(cells[i].level - cells[j].level) <= 1) continue;
            coarse = cells[i].level < cells[j].level ? i : j;
            break;
        }
        if (coarse < 0) return true;
        if (!split_cell(cells, count, coarse)) return false;
    }
}

bool is_child(Cell cell, int level, int x, int y, int z, int size) {
    return cell.level == level && cell.x >= x && cell.x < x + size &&
        cell.y >= y && cell.y < y + size && cell.z >= z && cell.z < z + size;
}

bool coarsen_once(Cell cells[kMaxCells], int& count, int sx, int sy, int sz, int radius) {
    for (int seed = 0; seed < count; ++seed) {
        const Cell child = cells[seed];
        if (child.level == 0) continue;
        const int parent_level = child.level - 1;
        const int parent_size = 1 << (kDepth - parent_level);
        const int child_size = parent_size / 2;
        const int px = child.x / parent_size * parent_size;
        const int py = child.y / parent_size * parent_size;
        const int pz = child.z / parent_size * parent_size;
        const Cell parent{parent_level, px, py, pz};
        if (overlaps_source(parent, sx, sy, sz, radius)) continue;
        int found[8];
        for (int q = 0; q < 8; ++q) found[q] = -1;
        for (int i = 0; i < count; ++i) if (is_child(cells[i], child.level, px, py, pz, parent_size)) {
            const int bx = (cells[i].x - px) / child_size;
            const int by = (cells[i].y - py) / child_size;
            const int bz = (cells[i].z - pz) / child_size;
            found[bx + 2 * by + 4 * bz] = i;
        }
        bool complete = true;
        for (int q = 0; q < 8; ++q) if (found[q] < 0) complete = false;
        if (!complete) continue;
        bool safe = true;
        for (int i = 0; i < count; ++i) {
            bool sibling = false;
            for (int q = 0; q < 8; ++q) if (found[q] == i) sibling = true;
            if (!sibling && neighboring(parent, cells[i]) && magnitude(parent_level - cells[i].level) > 1) safe = false;
        }
        if (!safe) continue;
        Cell compact[kMaxCells];
        int compact_count = 0;
        bool inserted = false;
        for (int i = 0; i < count; ++i) {
            bool sibling = false;
            for (int q = 0; q < 8; ++q) if (found[q] == i) sibling = true;
            if (!sibling) compact[compact_count++] = cells[i];
            else if (!inserted) { compact[compact_count++] = parent; inserted = true; }
        }
        for (int i = 0; i < compact_count; ++i) cells[i] = compact[i];
        count = compact_count;
        return true;
    }
    return false;
}

bool less_cell(Cell a, Cell b) {
    if (a.level != b.level) return a.level < b.level;
    if (a.z != b.z) return a.z < b.z;
    if (a.y != b.y) return a.y < b.y;
    return a.x < b.x;
}
} // namespace

extern "C" double npb_ua_mesh_adaptation(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 9 || length > kMaxInputLength) return kInvalid;
    for (int q = 0; q < 3; ++q) if (input[q] < 0 || input[q] > kSide) return kInvalid;
    if (input[3] < 1 || input[3] > kSide || input[4] < 1 || input[4] > kMaxCells) return kInvalid;
    const int sx = static_cast<int>(input[0]), sy = static_cast<int>(input[1]);
    const int sz = static_cast<int>(input[2]), radius = static_cast<int>(input[3]);
    int count = static_cast<int>(input[4]);
    if (length != static_cast<std::size_t>(5 + 4 * count)) return kInvalid;
    Cell cells[kMaxCells];
    bool covered[kMaxCells] = {};
    for (int i = 0; i < count; ++i) {
        const std::int64_t lr = input[5 + 4 * i], xr = input[6 + 4 * i];
        const std::int64_t yr = input[7 + 4 * i], zr = input[8 + 4 * i];
        if (lr < 0 || lr > kDepth || xr < 0 || xr > kSide || yr < 0 || yr > kSide || zr < 0 || zr > kSide) return kInvalid;
        const Cell cell{static_cast<int>(lr), static_cast<int>(xr), static_cast<int>(yr), static_cast<int>(zr)};
        const int size = cell_size(cell);
        if (cell.x + size > kSide || cell.y + size > kSide || cell.z + size > kSide ||
            cell.x % size != 0 || cell.y % size != 0 || cell.z % size != 0) return kInvalid;
        cells[i] = cell;
        for (int z = cell.z; z < cell.z + size; ++z) for (int y = cell.y; y < cell.y + size; ++y) for (int x = cell.x; x < cell.x + size; ++x) {
            const int q = x + kSide * (y + kSide * z);
            if (covered[q]) return kInvalid;
            covered[q] = true;
        }
    }
    for (bool cell : covered) if (!cell) return kInvalid;
    if (!balanced(cells, count)) return kInvalid;
    for (int i = 0; i < count;) {
        if (cells[i].level < kDepth && overlaps_source(cells[i], sx, sy, sz, radius)) {
            if (!split_cell(cells, count, i)) return kInvalid;
        } else ++i;
    }
    if (!balance_mesh(cells, count)) return kInvalid;
    while (coarsen_once(cells, count, sx, sy, sz, radius)) { }
    if (!balance_mesh(cells, count)) return kInvalid;
    for (int i = 1; i < count; ++i) {
        const Cell key = cells[i];
        int j = i;
        while (j > 0 && less_cell(key, cells[j - 1])) { cells[j] = cells[j - 1]; --j; }
        cells[j] = key;
    }
    double checksum = 0.0;
    for (int i = 0; i < count; ++i) {
        const int code = cells[i].level * 1000 + cells[i].x * 100 + cells[i].y * 10 + cells[i].z;
        checksum += static_cast<double>(i + 1) * static_cast<double>(code);
    }
    return checksum;
}
