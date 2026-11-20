module splash2_volrend_raymarch;

const int MAX_SIDE = 8;
const int MAX_RAYS = 16;
const int MAX_SAMPLES = 32;
const usz MAX_VOXELS = 512;
const usz MAX_PARSEABLE = 3 + 2 * MAX_VOXELS + 6 * MAX_RAYS + 1;
const usz MAX_MASKS = 4 * MAX_VOXELS;
const long Q8 = 256;
const long Q16 = 65536;
const long WEIGHT_DEN = 16777216;
const long ALPHA_DEN = 255 * WEIGHT_DEN;
const long COLOR_DEN = 255 * 255 * WEIGHT_DEN;

fn usz voxel_index(int side, int x, int y, int z) {
    return ((usz)z * (usz)side + (usz)y) * (usz)side + (usz)x;
}

fn usz mask_index(int level, int x, int y, int z) {
    return (((usz)level * 8 + (usz)z) * 8 + (usz)y) * 8 + (usz)x;
}

fn long round_half_up(long numerator, long denominator) {
    return (numerator + denominator / 2) / denominator;
}

fn uint8 to_byte(long q16) {
    return (uint8)((q16 * 255 + Q16 / 2) / Q16);
}

fn void interpolate(int side, uint8* alpha, uint8* gray, long xq, long yq,
                    long zq, long* opacity_q16, long* gray_q16) {
    int[3] low = {(int)(xq / Q8), (int)(yq / Q8), (int)(zq / Q8)};
    int[3] frac = {(int)(xq % Q8), (int)(yq % Q8), (int)(zq % Q8)};
    int[3] high = {low[0] + (low[0] + 1 < side), low[1] + (low[1] + 1 < side), low[2] + (low[2] + 1 < side)};
    long opacity_sum = 0, premul_sum = 0;
    for (int dz = 0; dz < 2; dz++) for (int dy = 0; dy < 2; dy++) for (int dx = 0; dx < 2; dx++) {
        int x = dx == 0 ? low[0] : high[0];
        int y = dy == 0 ? low[1] : high[1];
        int z = dz == 0 ? low[2] : high[2];
        long wx = dx == 0 ? Q8 - frac[0] : frac[0];
        long wy = dy == 0 ? Q8 - frac[1] : frac[1];
        long wz = dz == 0 ? Q8 - frac[2] : frac[2];
        usz at = voxel_index(side, x, y, z);
        long weight = wx * wy * wz;
        opacity_sum += (long)alpha[at] * weight;
        premul_sum += (long)alpha[at] * (long)gray[at] * weight;
    }
    *opacity_q16 = round_half_up(opacity_sum * Q16, ALPHA_DEN);
    *gray_q16 = round_half_up(premul_sum * Q16, COLOR_DEN);
}

fn long splash2_volrend_raymarch(long* input, usz length, uint8* output, usz capacity)
    @export("splash2_volrend_raymarch") {
    if (input == null || length < 3 || length > MAX_PARSEABLE) return -1;
    long side_raw = input[0], ray_raw = input[1], samples_raw = input[2];
    if ((side_raw != 2 && side_raw != 4 && side_raw != 8) || ray_raw < 1 || ray_raw > MAX_RAYS || samples_raw < 1 || samples_raw > MAX_SAMPLES) return -1;
    int side = (int)side_raw, samples = (int)samples_raw;
    usz ray_count = (usz)ray_raw;
    usz voxel_count = (usz)side * (usz)side * (usz)side;
    usz ray_start = 3 + 2 * voxel_count;
    if (length != ray_start + 6 * ray_count) return -1;

    uint8[MAX_VOXELS] alpha = zeroed, gray = zeroed;
    int[MAX_RAYS * 6] rays = zeroed;
    for (usz voxel = 0; voxel < voxel_count; voxel++) {
        long a = input[3 + 2 * voxel], g = input[4 + 2 * voxel];
        if (a < 0 || a > 255 || g < 0 || g > 255) return -1;
        alpha[voxel] = (uint8)a;
        gray[voxel] = (uint8)g;
    }
    long coord_max = (side - 1) * Q8;
    for (usz ray = 0; ray < ray_count; ray++) {
        usz at = ray_start + 6 * ray;
        for (int axis = 0; axis < 3; axis++) {
            long origin = input[at + (usz)axis];
            long delta = input[at + (usz)axis + 3];
            if (origin < 0 || origin > coord_max || delta < -coord_max || delta > coord_max) return -1;
            rays[6 * ray + (usz)axis] = (int)origin;
            rays[6 * ray + (usz)axis + 3] = (int)delta;
        }
        if (samples > 1 && rays[6 * ray + 3] == 0 && rays[6 * ray + 4] == 0 && rays[6 * ray + 5] == 0) return -1;
        for (int sample = 0; sample < samples; sample++) for (int axis = 0; axis < 3; axis++) {
            long q = (long)rays[6 * ray + (usz)axis] + (long)sample * rays[6 * ray + (usz)axis + 3];
            if (q < 0 || q > coord_max) return -1;
        }
    }
    usz output_bytes = 5 * ray_count;
    if (output == null) return -2;
    if (capacity < output_bytes) return -3;

    uint8[MAX_MASKS] support = zeroed;
    for (int z = 0; z < side; z++) for (int y = 0; y < side; y++) for (int x = 0; x < side; x++) {
        uint8 occupied = 0;
        for (int dz = 0; dz < 2; dz++) for (int dy = 0; dy < 2; dy++) for (int dx = 0; dx < 2; dx++) {
            int nx = x + ((x + 1 < side && dx != 0) ? 1 : 0);
            int ny = y + ((y + 1 < side && dy != 0) ? 1 : 0);
            int nz = z + ((z + 1 < side && dz != 0) ? 1 : 0);
            if (alpha[voxel_index(side, nx, ny, nz)] != 0) occupied = 1;
        }
        support[mask_index(0, x, y, z)] = occupied;
    }
    int levels = 0;
    for (int dimension = side; dimension > 1; dimension >>= 1) levels++;
    for (int level = 1; level <= levels; level++) {
        int dimension = side >> level;
        for (int z = 0; z < dimension; z++) for (int y = 0; y < dimension; y++) for (int x = 0; x < dimension; x++) {
            uint8 occupied = 0;
            for (int dz = 0; dz < 2; dz++) for (int dy = 0; dy < 2; dy++) for (int dx = 0; dx < 2; dx++)
                if (support[mask_index(level - 1, 2 * x + dx, 2 * y + dy, 2 * z + dz)] != 0) occupied = 1;
            support[mask_index(level, x, y, z)] = occupied;
        }
    }
    for (usz ray = 0; ray < ray_count; ray++) {
        long accumulated_alpha = 0, accumulated_gray = 0;
        int used = 0;
        for (int sample = 0; sample < samples; sample++) {
            used = sample + 1;
            long xq = (long)rays[6 * ray] + (long)sample * rays[6 * ray + 3];
            long yq = (long)rays[6 * ray + 1] + (long)sample * rays[6 * ray + 4];
            long zq = (long)rays[6 * ray + 2] + (long)sample * rays[6 * ray + 5];
            int cx = (int)(xq / Q8), cy = (int)(yq / Q8), cz = (int)(zq / Q8);
            bool supported = true;
            for (int level = levels; level >= 0; level--)
                if (support[mask_index(level, cx >> level, cy >> level, cz >> level)] == 0) { supported = false; break; }
            if (supported) {
                long sample_alpha, sample_gray;
                interpolate(side, alpha, gray, xq, yq, zq, &sample_alpha, &sample_gray);
                long remaining = Q16 - accumulated_alpha;
                accumulated_alpha += round_half_up(remaining * sample_alpha, Q16);
                accumulated_gray += round_half_up(remaining * sample_gray, Q16);
                if (accumulated_alpha > Q16) accumulated_alpha = Q16;
                if (accumulated_gray > Q16) accumulated_gray = Q16;
                if (accumulated_alpha == Q16) break;
            }
        }
        usz out = 5 * ray;
        uint8 value = to_byte(accumulated_gray);
        output[out] = value; output[out + 1] = value; output[out + 2] = value;
        output[out + 3] = to_byte(accumulated_alpha); output[out + 4] = (uint8)used;
    }
    return (long)output_bytes;
}
