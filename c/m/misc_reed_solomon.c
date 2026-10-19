/* Derived from the Reed-Solomon program by Simon Rockliff, 26 June 1991.
   See benchmarks/m/misc_reed_solomon/LICENSE.txt for the full permission notice. */
#include <stddef.h>
#include <stdint.h>

#define MESSAGE_BYTES 188
#define PARITY_BYTES 16
#define CODEWORD_BYTES 204
#define FULL_BYTES 255
#define INVALID_RESULT (-1)
#define OUTPUT_ERROR (-2)

static void make_tables(int alpha[255], int index_of[256])
{
    const int polynomial[8] = {1, 0, 1, 1, 1, 0, 0, 0};
    int mask = 1;
    int alpha_8 = 0;
    for (int i = 0; i < 256; ++i) index_of[i] = -1;
    for (int i = 0; i < 8; ++i) {
        alpha[i] = mask;
        index_of[alpha[i]] = i;
        if (polynomial[i] != 0) alpha_8 ^= mask;
        mask <<= 1;
    }
    alpha[8] = alpha_8;
    index_of[alpha_8] = 8;
    mask >>= 1;
    for (int i = 9; i < FULL_BYTES; ++i) {
        if (alpha[i - 1] >= mask)
            alpha[i] = alpha_8 ^ ((alpha[i - 1] ^ mask) << 1);
        else
            alpha[i] = alpha[i - 1] << 1;
        index_of[alpha[i]] = i;
    }
    index_of[0] = -1;
}

static void make_generator(int alpha[255], int index_of[256], int generator[17])
{
    generator[0] = 2;
    generator[1] = 1;
    for (int root = 2; root <= PARITY_BYTES; ++root) {
        generator[root] = 1;
        for (int index = root - 1; index > 0; --index) {
            if (generator[index] != 0)
                generator[index] = generator[index - 1] ^
                    alpha[(index_of[generator[index]] + root) % FULL_BYTES];
            else
                generator[index] = generator[index - 1];
        }
        generator[0] = alpha[(index_of[generator[0]] + root) % FULL_BYTES];
    }
    for (int index = 0; index <= PARITY_BYTES; ++index)
        generator[index] = index_of[generator[index]];
}

static void encode(const int64_t *values, const int alpha[255], const int index_of[256],
                   const int generator[17], uint8_t codeword[CODEWORD_BYTES])
{
    int data[239] = {0};
    int parity[PARITY_BYTES] = {0};
    for (int index = 0; index < MESSAGE_BYTES; ++index)
        data[51 + index] = (int)values[index];
    for (int data_index = 238; data_index >= 0; --data_index) {
        const int feedback = index_of[data[data_index] ^ parity[15]];
        if (feedback != -1) {
            for (int parity_index = 15; parity_index > 0; --parity_index) {
                if (generator[parity_index] != -1)
                    parity[parity_index] = parity[parity_index - 1] ^
                        alpha[(generator[parity_index] + feedback) % FULL_BYTES];
                else
                    parity[parity_index] = parity[parity_index - 1];
            }
            parity[0] = alpha[(generator[0] + feedback) % FULL_BYTES];
        } else {
            for (int parity_index = 15; parity_index > 0; --parity_index)
                parity[parity_index] = parity[parity_index - 1];
            parity[0] = 0;
        }
    }
    for (int index = 0; index < MESSAGE_BYTES; ++index)
        codeword[index] = (uint8_t)values[index];
    for (int index = 0; index < PARITY_BYTES; ++index)
        codeword[MESSAGE_BYTES + index] = (uint8_t)parity[index];
}

static int multiply(int left, int right, const int alpha[255], const int index_of[256])
{
    if (left == 0 || right == 0) return 0;
    int exponent = index_of[left] + index_of[right];
    if (exponent >= FULL_BYTES) exponent -= FULL_BYTES;
    return alpha[exponent];
}

static int divide(int left, int right, const int alpha[255], const int index_of[256])
{
    if (left == 0) return 0;
    int exponent = index_of[left] - index_of[right];
    if (exponent < 0) exponent += FULL_BYTES;
    return alpha[exponent];
}

static int correct_one(uint8_t codeword[CODEWORD_BYTES], int expected_position,
                       const int alpha[255], const int index_of[256])
{
    int syndrome_1 = 0;
    int syndrome_2 = 0;
    for (int full_position = 0; full_position < FULL_BYTES; ++full_position) {
        int symbol = 0;
        if (full_position < PARITY_BYTES)
            symbol = codeword[MESSAGE_BYTES + full_position];
        else if (full_position >= 67)
            symbol = codeword[full_position - 67];
        syndrome_1 ^= multiply(symbol, alpha[full_position % FULL_BYTES], alpha, index_of);
        syndrome_2 ^= multiply(symbol, alpha[(2 * full_position) % FULL_BYTES], alpha, index_of);
    }
    if (syndrome_1 == 0 && syndrome_2 == 0) return 1;
    if (syndrome_1 == 0) return 0;

    const int location = divide(syndrome_2, syndrome_1, alpha, index_of);
    int full_position = -1;
    for (int index = 0; index < FULL_BYTES; ++index)
        if (alpha[index] == location) { full_position = index; break; }
    if (full_position < 0) return 0;
    int transmitted_position;
    if (full_position < PARITY_BYTES)
        transmitted_position = MESSAGE_BYTES + full_position;
    else if (full_position >= 67)
        transmitted_position = full_position - 67;
    else
        return 0;
    if (transmitted_position != expected_position) return 0;
    const int magnitude = divide(syndrome_1, alpha[full_position], alpha, index_of);
    codeword[transmitted_position] ^= (uint8_t)magnitude;
    return 1;
}

int64_t misc_reed_solomon(const int64_t *values, size_t length,
                          uint8_t *output, size_t output_capacity)
{
    if (values == NULL || (length != MESSAGE_BYTES + 1 && length != MESSAGE_BYTES + 3))
        return INVALID_RESULT;
    for (size_t index = 0; index < MESSAGE_BYTES; ++index)
        if (values[index] < 0 || values[index] > 255) return INVALID_RESULT;
    const int64_t error_count = values[MESSAGE_BYTES];
    if ((error_count == 0 && length != MESSAGE_BYTES + 1) ||
        (error_count == 1 && length != MESSAGE_BYTES + 3) ||
        (error_count != 0 && error_count != 1)) return INVALID_RESULT;
    int error_position = -1;
    if (error_count == 1) {
        if (values[MESSAGE_BYTES + 1] < 0 || values[MESSAGE_BYTES + 1] >= CODEWORD_BYTES ||
            values[MESSAGE_BYTES + 2] < 0 || values[MESSAGE_BYTES + 2] > 255)
            return INVALID_RESULT;
        error_position = (int)values[MESSAGE_BYTES + 1];
    }
    if (output == NULL || output_capacity < CODEWORD_BYTES) return OUTPUT_ERROR;

    int alpha[FULL_BYTES];
    int index_of[256];
    int generator[PARITY_BYTES + 1];
    uint8_t staged[CODEWORD_BYTES];
    make_tables(alpha, index_of);
    make_generator(alpha, index_of, generator);
    encode(values, alpha, index_of, generator, staged);
    if (error_count == 1) staged[error_position] = (uint8_t)values[MESSAGE_BYTES + 2];
    if (!correct_one(staged, error_position, alpha, index_of)) return INVALID_RESULT;
    for (size_t index = 0; index < CODEWORD_BYTES; ++index) output[index] = staged[index];
    return CODEWORD_BYTES;
}
