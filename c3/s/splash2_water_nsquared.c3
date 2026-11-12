module splash2_water_nsquared;

const int MAX_N = 64;
const usz MAX_INPUT = 3 + 4 * MAX_N;
const usz MAX_PARSEABLE = MAX_INPUT + 1;
const int MAX_OUTPUT_WORDS = 3 * MAX_N + 2;
const long SCALE = 1000000;

fn void store_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long splash2_water_nsquared(long* input, usz length, char* output, usz capacity)
    @export("splash2_water_nsquared") {
    if (input == null || length < 3 || length > MAX_PARSEABLE) return -1;
    long n_value = input[0], grid = input[1], radius = input[2];
    if (n_value < 0 || n_value > MAX_N || grid < 1 || grid > 8 || radius < 1 || radius > 4) return -1;
    usz n = (usz)n_value;
    if (length != 3 + 4 * n) return -1;
    long side = grid * radius, radius2 = radius * radius;
    long[MAX_N] x = zeroed, y = zeroed, z = zeroed, charge = zeroed;
    for (usz i = 0; i < n; i++) {
        usz at = 3 + 4 * i;
        x[i] = input[at]; y[i] = input[at + 1]; z[i] = input[at + 2]; charge[i] = input[at + 3];
        if (x[i] < 0 || x[i] >= side || y[i] < 0 || y[i] >= side || z[i] < 0 || z[i] >= side || charge[i] < -4 || charge[i] > 4) return -1;
    }
    long[MAX_N][3] force = zeroed;
    long energy = 0, pairs = 0;
    for (usz i = 0; i < n; i++) for (usz j = i + 1; j < n; j++) {
        long dx = x[j] - x[i], dy = y[j] - y[i], dz = z[j] - z[i];
        long r2 = dx * dx + dy * dy + dz * dz;
        if (r2 >= radius2) continue;
        long product = charge[i] * charge[j];
        energy += (product * (radius2 - r2) * SCALE) / ((1 + r2) * (1 + radius2));
        long denominator = (1 + r2) * (1 + r2);
        long fx = (-2 * product * dx * SCALE) / denominator;
        long fy = (-2 * product * dy * SCALE) / denominator;
        long fz = (-2 * product * dz * SCALE) / denominator;
        force[i][0] += fx; force[i][1] += fy; force[i][2] += fz;
        force[j][0] -= fx; force[j][1] -= fy; force[j][2] -= fz;
        pairs++;
    }
    usz words = 3 * n + 2, bytes = 8 * words;
    if (output == null || capacity < bytes) return -2;
    long[MAX_OUTPUT_WORDS] result = zeroed;
    for (usz i = 0; i < n; i++) for (usz axis = 0; axis < 3; axis++) result[3 * i + axis] = force[i][axis];
    result[3 * n] = energy; result[3 * n + 1] = pairs;
    for (usz word = 0; word < words; word++) store_le(output, 8 * word, result[word]);
    return (long)bytes;
}
