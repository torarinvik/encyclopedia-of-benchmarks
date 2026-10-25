module parboil_cutcp;

extern fn float floorf(float value);
extern fn float ceilf(float value);
extern fn float sqrtf(float value);
extern fn float roundf(float value);

const int MAX_DIM = 4;
const int MAX_ATOMS = 4;
const int MAX_INPUT = 25;
const int MAX_GRID = 64;
const float INV_CELL_LENGTH = 0.25f;

struct Atom { float x; float y; float z; float q; }

fn float decode_component(long raw) { return raw.float() / 1000000.0f; }

fn void write_i32_le(uchar* output, usz offset, int value) {
    uint bits = (uint)value;
    output[offset] = (uchar)bits;
    output[offset + 1] = (uchar)(bits >> 8);
    output[offset + 2] = (uchar)(bits >> 16);
    output[offset + 3] = (uchar)(bits >> 24);
}

fn long parboil_cutcp(long* input, usz input_length, uchar* output, usz output_capacity)
    @export("parboil_cutcp") {
    if (input == null || input_length < 13 || input_length > MAX_INPUT) return -1;
    if (input[0] < 2 || input[0] > MAX_DIM || input[1] < 2 || input[1] > MAX_DIM
            || input[2] < 2 || input[2] > MAX_DIM || input[3] < 1 || input[3] > MAX_ATOMS) return -1;
    int nx = input[0].int(), ny = input[1].int(), nz = input[2].int(), natoms = input[3].int();
    if (input_length != 9 + 4 * natoms) return -1;
    long xlo_raw = input[4], ylo_raw = input[5], zlo_raw = input[6];
    long spacing_raw = input[7], cutoff_raw = input[8];
    if (xlo_raw < -16000000 || xlo_raw > 16000000 || ylo_raw < -16000000 || ylo_raw > 16000000
            || zlo_raw < -16000000 || zlo_raw > 16000000 || xlo_raw % 1000000 != 0
            || ylo_raw % 1000000 != 0 || zlo_raw % 1000000 != 0
            || spacing_raw < 1000000 || spacing_raw > 4000000 || spacing_raw % 1000000 != 0
            || cutoff_raw < 250000 || cutoff_raw > 4000000) return -1;
    for (usz n = 0; n < natoms.usz(); n++) {
        usz offset = 9 + 4 * n;
        if (input[offset] < 0 || input[offset] >= nx - 1 || input[offset + 1] < 0
                || input[offset + 1] >= ny - 1 || input[offset + 2] < 0
                || input[offset + 2] >= nz - 1 || input[offset + 3] < -1000000
                || input[offset + 3] > 1000000) return -1;
    }
    usz points = nx.usz() * ny.usz() * nz.usz();
    usz output_bytes = 4 * points;
    if (output == null || output_capacity < output_bytes) return -2;

    float xlo = decode_component(xlo_raw), ylo = decode_component(ylo_raw), zlo = decode_component(zlo_raw);
    float spacing = decode_component(spacing_raw), cutoff = decode_component(cutoff_raw);
    float half_spacing = spacing * 0.5f;
    [MAX_ATOMS]Atom atoms = zeroed;
    for (usz n = 0; n < natoms.usz(); n++) {
        usz offset = 9 + 4 * n;
        int ix = input[offset].int(), iy = input[offset + 1].int(), iz = input[offset + 2].int();
        atoms[n] = Atom{xlo + (ix.float() * spacing + half_spacing),
                        ylo + (iy.float() * spacing + half_spacing),
                        zlo + (iz.float() * spacing + half_spacing),
                        decode_component(input[offset + 3])};
    }
    float min_x = atoms[0].x, max_x = atoms[0].x;
    float min_y = atoms[0].y, max_y = atoms[0].y;
    float min_z = atoms[0].z, max_z = atoms[0].z;
    for (int n = 1; n < natoms; n++) {
        if (atoms[n].x < min_x) min_x = atoms[n].x;
        if (atoms[n].x > max_x) max_x = atoms[n].x;
        if (atoms[n].y < min_y) min_y = atoms[n].y;
        if (atoms[n].y > max_y) max_y = atoms[n].y;
        if (atoms[n].z < min_z) min_z = atoms[n].z;
        if (atoms[n].z > max_z) max_z = atoms[n].z;
    }
    int nx_cell = floorf((max_x - min_x) * INV_CELL_LENGTH).int() + 1;
    int ny_cell = floorf((max_y - min_y) * INV_CELL_LENGTH).int() + 1;
    int nz_cell = floorf((max_z - min_z) * INV_CELL_LENGTH).int() + 1;
    int cell_count = nx_cell * ny_cell * nz_cell;
    [MAX_GRID]int first = zeroed;
    [MAX_ATOMS]int next = zeroed;
    for (int c = 0; c < cell_count; c++) first[c.usz()] = -1;
    for (int n = 0; n < natoms; n++) next[n.usz()] = -1;
    for (int n = 0; n < natoms; n++) {
        if (atoms[n.usz()].q == 0.0f) continue;
        int i = floorf((atoms[n.usz()].x - min_x) * INV_CELL_LENGTH).int();
        int j = floorf((atoms[n.usz()].y - min_y) * INV_CELL_LENGTH).int();
        int k = floorf((atoms[n.usz()].z - min_z) * INV_CELL_LENGTH).int();
        int cell = (k * ny_cell + j) * nx_cell + i;
        next[n.usz()] = first[cell.usz()];
        first[cell.usz()] = n;
    }

    float cutoff_squared = cutoff * cutoff;
    float inv_cutoff_squared = 1.0f / cutoff_squared;
    float inv_spacing = 1.0f / spacing;
    int radius = ceilf(cutoff * inv_spacing).int() - 1;
    [MAX_GRID]float grid = zeroed;
    for (int c = 0; c < cell_count; c++) {
        int n = first[c.usz()];
        while (n != -1) {
            float x = atoms[n.usz()].x - xlo;
            float y = atoms[n.usz()].y - ylo;
            float z = atoms[n.usz()].z - zlo;
            float q = atoms[n.usz()].q;
            int ic = (x * inv_spacing).int(), jc = (y * inv_spacing).int(), kc = (z * inv_spacing).int();
            int ia = ic - radius, ib = ic + radius + 1;
            int ja = jc - radius, jb = jc + radius + 1;
            int ka = kc - radius, kb = kc + radius + 1;
            if (ia < 0) ia = 0;
            if (ib >= nx) ib = nx - 1;
            if (ja < 0) ja = 0;
            if (jb >= ny) jb = ny - 1;
            if (ka < 0) ka = 0;
            if (kb >= nz) kb = nz - 1;
            float xstart = ia.float() * spacing - x;
            float ystart = ja.float() * spacing - y;
            float dz = ka.float() * spacing - z;
            for (int k = ka; k <= kb; k++, dz += spacing) {
                int koff = k * ny;
                float dz2 = dz * dz;
                float dy = ystart;
                for (int j = ja; j <= jb; j++, dy += spacing) {
                    int jkoff = (koff + j) * nx;
                    float dydz2 = dy * dy + dz2;
                    if (dydz2 >= cutoff_squared) continue;
                    float dx = xstart;
                    for (int i = ia; i <= ib; i++, dx += spacing) {
                        float r2 = dx * dx + dydz2;
                        if (r2 >= cutoff_squared) continue;
                        float s = 1.0f - r2 * inv_cutoff_squared;
                        float e = q * (1.0f / sqrtf(r2)) * s * s;
                        grid[(jkoff + i).usz()] += e;
                    }
                }
            }
            n = next[n.usz()];
        }
    }
    for (usz point = 0; point < points; point++)
        write_i32_le(output, 4 * point, roundf(grid[point].float() * 1000.0f).int());
    return output_bytes.long();
}
