module intersection_of_f2_vector_spaces;

const usz MAX_CASES = 4;
const usz MAX_VECTORS = 8;
const int MAX_BITS = 30;
const usz MAX_INPUT_VALUES = 1 + MAX_CASES * (2 + 2 * MAX_VECTORS) + 1;
const usz MAX_OUTPUT_WORDS = MAX_CASES * (1 + MAX_VECTORS);
const uint MAX_VECTOR = 0x3fffffff;

fn bool insert_independent(uint[MAX_BITS]* basis, uint value) {
    uint row = value;
    for (int bit = MAX_BITS - 1; bit >= 0; bit -= 1) {
        if (((row >> bit) & 1) == 0) continue;
        if (basis[bit.usz()] != 0) row ^= basis[bit.usz()];
        else { basis[bit.usz()] = row; return true; }
    }
    return false;
}

fn usz intersection_basis(uint[MAX_VECTORS]* left, usz n,
    uint[MAX_VECTORS]* right, usz m, uint[MAX_VECTORS]* output) {
    uint[MAX_BITS] right_basis, right_coeff;
    for (int bit = 0; bit < MAX_BITS; bit += 1) {
        right_basis[bit.usz()] = 0;
        right_coeff[bit.usz()] = 0;
    }
    for (usz index = 0; index < m; index += 1) {
        uint row = right[index];
        uint coefficients = 1 << index;
        for (int bit = MAX_BITS - 1; bit >= 0; bit -= 1) {
            if (((row >> bit) & 1) == 0) continue;
            if (right_basis[bit.usz()] != 0) {
                row ^= right_basis[bit.usz()];
                coefficients ^= right_coeff[bit.usz()];
            } else {
                right_basis[bit.usz()] = row;
                right_coeff[bit.usz()] = coefficients;
                break;
            }
        }
    }
    uint[MAX_BITS] quotient_basis, quotient_left_coeff, quotient_right_coeff;
    for (int bit = 0; bit < MAX_BITS; bit += 1) {
        quotient_basis[bit.usz()] = 0;
        quotient_left_coeff[bit.usz()] = 0;
        quotient_right_coeff[bit.usz()] = 0;
    }
    uint[MAX_VECTORS] intersection;
    for (usz index = 0; index < MAX_VECTORS; index += 1) intersection[index] = 0;
    usz intersection_count = 0;
    for (usz index = 0; index < n; index += 1) {
        uint row = left[index];
        uint right_mask = 0;
        for (int bit = MAX_BITS - 1; bit >= 0; bit -= 1) {
            if (((row >> bit) & 1) != 0 && right_basis[bit.usz()] != 0) {
                row ^= right_basis[bit.usz()];
                right_mask ^= right_coeff[bit.usz()];
            }
        }
        uint left_mask = 1 << index;
        for (int bit = MAX_BITS - 1; bit >= 0; bit -= 1) {
            if (((row >> bit) & 1) == 0) continue;
            if (quotient_basis[bit.usz()] != 0) {
                row ^= quotient_basis[bit.usz()];
                left_mask ^= quotient_left_coeff[bit.usz()];
                right_mask ^= quotient_right_coeff[bit.usz()];
            } else {
                quotient_basis[bit.usz()] = row;
                quotient_left_coeff[bit.usz()] = left_mask;
                quotient_right_coeff[bit.usz()] = right_mask;
                break;
            }
        }
        if (row == 0) {
            uint common = 0;
            for (usz source = 0; source < n; source += 1)
                if (((left_mask >> source) & 1) != 0) common ^= left[source];
            intersection[intersection_count] = common;
            intersection_count += 1;
        }
    }

    uint[MAX_BITS] rref;
    for (int bit = 0; bit < MAX_BITS; bit += 1) rref[bit.usz()] = 0;
    for (usz index = 0; index < intersection_count; index += 1) {
        uint row = intersection[index];
        for (int bit = MAX_BITS - 1; bit >= 0; bit -= 1) {
            if (((row >> bit) & 1) == 0) continue;
            if (rref[bit.usz()] != 0) row ^= rref[bit.usz()];
            else {
                rref[bit.usz()] = row;
                for (int pivot = 0; pivot < MAX_BITS; pivot += 1)
                    if (pivot != bit && ((rref[pivot.usz()] >> bit) & 1) != 0)
                        rref[pivot.usz()] ^= row;
                break;
            }
        }
    }
    usz output_count = 0;
    for (int bit = MAX_BITS - 1; bit >= 0; bit -= 1) {
        if (rref[bit.usz()] != 0) {
            output[output_count] = rref[bit.usz()];
            output_count += 1;
        }
    }
    return output_count;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long intersection_of_f2_vector_spaces(long* input, usz length, char* output, usz capacity)
    @export("intersection_of_f2_vector_spaces") {
    if (input == null || length < 1 || length > MAX_INPUT_VALUES) return -1;
    long case_count_value = input[0];
    if (case_count_value < 1 || case_count_value > (long)MAX_CASES) return -1;
    usz case_count = (usz)case_count_value;
    long[MAX_OUTPUT_WORDS] staged;
    usz used = 0, cursor = 1;
    for (usz case_index = 0; case_index < case_count; case_index += 1) {
        if (cursor >= length) return -1;
        long n_value = input[cursor];
        cursor += 1;
        if (n_value < 0 || n_value > (long)MAX_VECTORS) return -1;
        usz n = (usz)n_value;
        if (cursor + n > length) return -1;
        uint[MAX_VECTORS] left;
        uint[MAX_BITS] left_check;
        for (int bit = 0; bit < MAX_BITS; bit += 1) left_check[bit.usz()] = 0;
        for (usz index = 0; index < n; index += 1) {
            long value = input[cursor];
            cursor += 1;
            if (value < 0 || value > (long)MAX_VECTOR) return -1;
            uint vector = (uint)value;
            if (!insert_independent(&left_check[0], vector)) return -1;
            left[index] = vector;
        }
        if (cursor >= length) return -1;
        long m_value = input[cursor];
        cursor += 1;
        if (m_value < 0 || m_value > (long)MAX_VECTORS) return -1;
        usz m = (usz)m_value;
        if (cursor + m > length) return -1;
        uint[MAX_VECTORS] right;
        uint[MAX_BITS] right_check;
        for (int bit = 0; bit < MAX_BITS; bit += 1) right_check[bit.usz()] = 0;
        for (usz index = 0; index < m; index += 1) {
            long value = input[cursor];
            cursor += 1;
            if (value < 0 || value > (long)MAX_VECTOR) return -1;
            uint vector = (uint)value;
            if (!insert_independent(&right_check[0], vector)) return -1;
            right[index] = vector;
        }
        uint[MAX_VECTORS] basis;
        usz dimension = intersection_basis(&left[0], n, &right[0], m, &basis[0]);
        staged[used] = (long)dimension;
        used += 1;
        for (usz index = 0; index < dimension; index += 1) {
            staged[used] = (long)basis[index];
            used += 1;
        }
    }
    if (cursor != length) return -1;
    usz required = 8 * used;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < used; index += 1) store_i64_le(output, 8 * index, staged[index]);
    return (long)required;
}
