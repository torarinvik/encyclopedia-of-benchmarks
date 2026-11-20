module tetrahedral_element_force_kernel;

const usz MAX_ELEMENTS = 32;
const usz MAX_VALID_INPUT = 3 + 12 * MAX_ELEMENTS;
const usz MAX_INPUT = MAX_VALID_INPUT + 1;

fn void tfk_store(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tetrahedral_element_force_kernel(long* input, usz length, char* output, usz capacity)
    @export("tetrahedral_element_force_kernel") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long m_value = input[0], lambda = input[1], mu = input[2];
    if (m_value < 1 || m_value > (long)MAX_ELEMENTS || lambda < 0 || lambda > 16 ||
        mu < 0 || mu > 16) return -1;
    usz m = (usz)m_value;
    if (length != 3 + 12 * m) return -1;
    for (usz i = 3; i < length; i += 1)
        if (input[i] < -4 || input[i] > 4) return -1;

    usz required = 96 * m;
    if (output == null || capacity < required) return -2;
    for (usz element = 0; element < m; element += 1) {
        long[9] f;
        usz base = 3 + 12 * element;
        for (usz row = 0; row < 3; row += 1) {
            for (usz column = 0; column < 3; column += 1) {
                f[row * 3 + column] = input[base + 3 * (column + 1) + row] - input[base + row];
            }
        }
        long trace_delta = f[0] + f[4] + f[8] - 3;
        long[9] stress;
        for (usz row = 0; row < 3; row += 1) {
            for (usz column = 0; column < 3; column += 1) {
                long diagonal = row == column ? 1 : 0;
                stress[row * 3 + column] = lambda * trace_delta * diagonal +
                    mu * (f[row * 3 + column] + f[column * 3 + row] - 2 * diagonal);
            }
        }
        for (usz axis = 0; axis < 3; axis += 1) {
            long vertex0 = stress[axis * 3] + stress[axis * 3 + 1] + stress[axis * 3 + 2];
            tfk_store(output, 8 * (12 * element + axis), vertex0);
            for (usz vertex = 1; vertex < 4; vertex += 1)
                tfk_store(output, 8 * (12 * element + 3 * vertex + axis),
                          -stress[axis * 3 + vertex - 1]);
        }
    }
    return (long)required;
}
