// Derived from the Reed-Solomon program by Simon Rockliff, 26 June 1991.
// See benchmarks/m/misc_reed_solomon/LICENSE.txt for the complete permission notice.
module misc_reed_solomon;

const usz MESSAGE_BYTES = 188;
const usz PARITY_BYTES = 16;
const usz CODEWORD_BYTES = 204;
const int FULL_BYTES = 255;

fn void make_tables(int* alpha, int* index_of) {
    int[8] polynomial = {1, 0, 1, 1, 1, 0, 0, 0};
    for (int i = 0; i < 256; i++) index_of[i] = -1;
    int mask = 1;
    int alpha_8 = 0;
    for (int i = 0; i < 8; i++) {
        alpha[i] = mask;
        index_of[alpha[i]] = i;
        if (polynomial[i] != 0) alpha_8 ^= mask;
        mask <<= 1;
    }
    alpha[8] = alpha_8;
    index_of[alpha_8] = 8;
    mask >>= 1;
    for (int i = 9; i < FULL_BYTES; i++) {
        if (alpha[i - 1] >= mask) alpha[i] = alpha_8 ^ ((alpha[i - 1] ^ mask) << 1);
        else alpha[i] = alpha[i - 1] << 1;
        index_of[alpha[i]] = i;
    }
    index_of[0] = -1;
}

fn void make_generator(int* alpha, int* index_of, int* generator) {
    generator[0] = 2;
    generator[1] = 1;
    for (int root = 2; root <= 16; root++) {
        generator[root] = 1;
        for (int index = root - 1; index > 0; index--) {
            if (generator[index] != 0)
                generator[index] = generator[index - 1] ^ alpha[(index_of[generator[index]] + root) % FULL_BYTES];
            else generator[index] = generator[index - 1];
        }
        generator[0] = alpha[(index_of[generator[0]] + root) % FULL_BYTES];
    }
    for (int index = 0; index <= 16; index++) generator[index] = index_of[generator[index]];
}

fn void encode(long* values, int* alpha, int* index_of, int* generator, int* codeword) {
    int[239] data = {};
    int[16] parity = {};
    for (int index = 0; index < MESSAGE_BYTES; index++) data[51 + index] = (int)values[index];
    for (int data_index = 238; data_index >= 0; data_index--) {
        int feedback = index_of[data[data_index] ^ parity[15]];
        if (feedback != -1) {
            for (int parity_index = 15; parity_index > 0; parity_index--) {
                if (generator[parity_index] != -1)
                    parity[parity_index] = parity[parity_index - 1] ^ alpha[(generator[parity_index] + feedback) % FULL_BYTES];
                else parity[parity_index] = parity[parity_index - 1];
            }
            parity[0] = alpha[(generator[0] + feedback) % FULL_BYTES];
        } else {
            for (int parity_index = 15; parity_index > 0; parity_index--) parity[parity_index] = parity[parity_index - 1];
            parity[0] = 0;
        }
    }
    for (int index = 0; index < MESSAGE_BYTES; index++) codeword[index] = (int)values[index];
    for (int index = 0; index < PARITY_BYTES; index++) codeword[MESSAGE_BYTES + index] = parity[index];
}

fn int multiply(int left, int right, int* alpha, int* index_of) {
    if (left == 0 || right == 0) return 0;
    int exponent = index_of[left] + index_of[right];
    if (exponent >= FULL_BYTES) exponent -= FULL_BYTES;
    return alpha[exponent];
}

fn int divide(int left, int right, int* alpha, int* index_of) {
    if (left == 0) return 0;
    int exponent = index_of[left] - index_of[right];
    if (exponent < 0) exponent += FULL_BYTES;
    return alpha[exponent];
}

fn bool correct_one(int* codeword, int expected_position, int* alpha, int* index_of) {
    int syndrome_1 = 0;
    int syndrome_2 = 0;
    for (int full_position = 0; full_position < FULL_BYTES; full_position++) {
        int symbol = 0;
        if (full_position < 16) symbol = codeword[188 + full_position];
        else if (full_position >= 67) symbol = codeword[full_position - 67];
        syndrome_1 ^= multiply(symbol, alpha[full_position % FULL_BYTES], alpha, index_of);
        syndrome_2 ^= multiply(symbol, alpha[(2 * full_position) % FULL_BYTES], alpha, index_of);
    }
    if (syndrome_1 == 0 && syndrome_2 == 0) return true;
    if (syndrome_1 == 0) return false;
    int location = divide(syndrome_2, syndrome_1, alpha, index_of);
    int full_position = -1;
    for (int index = 0; index < FULL_BYTES; index++)
        if (alpha[index] == location) { full_position = index; break; }
    if (full_position < 0) return false;
    int transmitted_position;
    if (full_position < 16) transmitted_position = 188 + full_position;
    else if (full_position >= 67) transmitted_position = full_position - 67;
    else return false;
    if (transmitted_position != expected_position) return false;
    int magnitude = divide(syndrome_1, alpha[full_position], alpha, index_of);
    codeword[transmitted_position] ^= magnitude;
    return true;
}

long misc_reed_solomon(long* values, usz length, char* output, usz output_capacity)
    @export("misc_reed_solomon") {
    if (values == null || (length != 189 && length != 191)) return -1;
    for (usz index = 0; index < MESSAGE_BYTES; index++)
        if (values[index] < 0 || values[index] > 255) return -1;
    long error_count = values[188];
    if ((error_count == 0 && length != 189) || (error_count == 1 && length != 191) ||
        (error_count != 0 && error_count != 1)) return -1;
    int error_position = -1;
    if (error_count == 1) {
        if (values[189] < 0 || values[189] >= 204 || values[190] < 0 || values[190] > 255) return -1;
        error_position = (int)values[189];
    }
    if (output == null || output_capacity < CODEWORD_BYTES) return -2;

    int[255] alpha = {};
    int[256] index_of = {};
    int[17] generator = {};
    int[204] staged = {};
    make_tables(&alpha[0], &index_of[0]);
    make_generator(&alpha[0], &index_of[0], &generator[0]);
    encode(values, &alpha[0], &index_of[0], &generator[0], &staged[0]);
    if (error_count == 1) staged[error_position] = (int)values[190];
    if (!correct_one(&staged[0], error_position, &alpha[0], &index_of[0])) return -1;
    for (usz index = 0; index < CODEWORD_BYTES; index++) output[index] = (char)staged[index];
    return (long)CODEWORD_BYTES;
}
