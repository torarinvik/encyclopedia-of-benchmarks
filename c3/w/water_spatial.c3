module water_spatial;

const usz MAX_MOLECULES = 64;
const usz MAX_GRID_SIDE = 8;
const usz MAX_CELLS = 512;
const usz MAX_INPUT_LENGTH = 4 + 4 * MAX_MOLECULES;
const long SCALE = 1000000;

fn long trunc_div_i64(long numerator, long denominator) {
    return numerator < 0 ? -((-numerator) / denominator) : numerator / denominator;
}

fn void store_i64_le(char *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long water_spatial(long *input, usz length, char *output, usz capacity)
    @export("water_spatial") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = input[0], grid_value = input[1], cutoff_value = input[2];
    if (count_value < 0 || count_value > 64 || grid_value < 1 || grid_value > 8
            || cutoff_value < 1 || cutoff_value > 4) return -1;
    usz count = (usz)count_value;
    usz grid = (usz)grid_value;
    long cutoff = cutoff_value;
    if (length != 3 + 4 * count) return -1;
    long extent = (long)grid * cutoff;
    for (usz i = 0; i < count; i++) {
        usz base = 3 + 4 * i;
        if (input[base] < 0 || input[base] >= extent
                || input[base + 1] < 0 || input[base + 1] >= extent
                || input[base + 2] < 0 || input[base + 2] >= extent
                || input[base + 3] < -4 || input[base + 3] > 4) return -1;
    }
    usz output_bytes = 8 * (3 * count + 2);
    if (output == null || capacity < output_bytes) return -2;

    long[MAX_CELLS] head;
    long[MAX_MOLECULES] next;
    long[MAX_MOLECULES] force_x;
    long[MAX_MOLECULES] force_y;
    long[MAX_MOLECULES] force_z;
    for (usz cell = 0; cell < MAX_CELLS; cell++) head[cell] = -1;
    for (usz i = 0; i < count; i++) {
        usz base = 3 + 4 * i;
        long cx = input[base] / cutoff;
        long cy = input[base + 1] / cutoff;
        long cz = input[base + 2] / cutoff;
        usz cell = (usz)(cx + (long)grid * (cy + (long)grid * cz));
        next[i] = head[cell];
        head[cell] = (long)i;
        force_x[i] = 0; force_y[i] = 0; force_z[i] = 0;
    }
    long energy = 0, pairs = 0;
    long cutoff_squared = cutoff * cutoff;
    for (usz i = 0; i < count; i++) {
        usz base_i = 3 + 4 * i;
        long cx = input[base_i] / cutoff;
        long cy = input[base_i + 1] / cutoff;
        long cz = input[base_i + 2] / cutoff;
        for (long oz = -1; oz <= 1; oz++) {
            long nz = cz + oz;
            if (nz < 0 || nz >= (long)grid) continue;
            for (long oy = -1; oy <= 1; oy++) {
                long ny = cy + oy;
                if (ny < 0 || ny >= (long)grid) continue;
                for (long ox = -1; ox <= 1; ox++) {
                    long nx = cx + ox;
                    if (nx < 0 || nx >= (long)grid) continue;
                    usz cell = (usz)(nx + (long)grid * (ny + (long)grid * nz));
                    long candidate = head[cell];
                    while (candidate >= 0) {
                        usz j = (usz)candidate;
                        if (j > i) {
                            usz base_j = 3 + 4 * j;
                            long dx = input[base_j] - input[base_i];
                            long dy = input[base_j + 1] - input[base_i + 1];
                            long dz = input[base_j + 2] - input[base_i + 2];
                            long r2 = dx * dx + dy * dy + dz * dz;
                            if (r2 < cutoff_squared) {
                                long product = input[base_i + 3] * input[base_j + 3];
                                energy += trunc_div_i64(product * (cutoff_squared - r2) * SCALE,
                                                        (1 + r2) * (1 + cutoff_squared));
                                long denominator = (1 + r2) * (1 + r2);
                                long px = trunc_div_i64(-2 * product * dx * SCALE, denominator);
                                long py = trunc_div_i64(-2 * product * dy * SCALE, denominator);
                                long pz = trunc_div_i64(-2 * product * dz * SCALE, denominator);
                                force_x[i] += px; force_x[j] -= px;
                                force_y[i] += py; force_y[j] -= py;
                                force_z[i] += pz; force_z[j] -= pz;
                                pairs++;
                            }
                        }
                        candidate = next[j];
                    }
                }
            }
        }
    }
    for (usz i = 0; i < count; i++) {
        store_i64_le(output, 8 * (3 * i), force_x[i]);
        store_i64_le(output, 8 * (3 * i + 1), force_y[i]);
        store_i64_le(output, 8 * (3 * i + 2), force_z[i]);
    }
    store_i64_le(output, 8 * (3 * count), energy);
    store_i64_le(output, 8 * (3 * count + 1), pairs);
    return (long)output_bytes;
}
