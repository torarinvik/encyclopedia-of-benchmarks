/* Clean-room bounded simulator for the Embench NSicherNeu Petri/T-Net path. */
#include <stddef.h>
#include <stdint.h>

#define NSICHNEU_INPUT_COUNT 9u
#define NSICHNEU_OUTPUT_COUNT 17u
#define NSICHNEU_MAX_RUNS 64

int64_t nsichneu(const int64_t *input, size_t input_length,
                 uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length != NSICHNEU_INPUT_COUNT ||
        input[0] < 1 || input[0] > NSICHNEU_MAX_RUNS) return -1;
    for (size_t index = 1; index < input_length; ++index)
        if (input[index] < -1000 || input[index] > 1000) return -1;
    if (output == NULL || output_capacity < NSICHNEU_OUTPUT_COUNT * 8u) return -2;

    int64_t p1[3] = {input[1], input[2], input[3]};
    int64_t p2[5] = {input[4], input[5], input[6], input[7], input[8]};
    int64_t p3[6] = {0, 0, 0, 0, 0, 0};
    int64_t p1_count = 3;
    int64_t p2_count = 5;
    int64_t p3_count = 0;

    for (int64_t run = 0; run < input[0]; ++run) {
        p1_count = 3;
        p2_count = 5;
        p3_count = 0;

        /* T1 examines the six lexicographically ordered permutations of P1. */
        for (size_t first = 0; first < 3; ++first) {
            for (size_t second = 0; second < 3; ++second) {
                if (second == first) continue;
                for (size_t third = 0; third < 3; ++third) {
                    if (third == first || third == second) continue;
                    if (p1_count >= 3 && p3_count + 3 <= 6 &&
                        p1[second] == p1[third]) {
                        const int64_t x = p1[first];
                        const int64_t y = p1[second];
                        if (x < y) {
                            p1_count -= 3;
                            p3[p3_count] = x;
                            p3[p3_count + 1] = y;
                            p3[p3_count + 2] = x - y;
                            p3_count += 3;
                        }
                    }
                }
            }
        }

        /* T2 examines each four-slot subset, then its 24 ordered permutations. */
        for (size_t subset_number = 0; subset_number < 5; ++subset_number) {
            const size_t omitted = 4 - subset_number;
            size_t subset[4];
            size_t count = 0;
            for (size_t index = 0; index < 5; ++index)
                if (index != omitted) subset[count++] = index;

            for (size_t a = 0; a < 4; ++a) {
                for (size_t b = 0; b < 4; ++b) {
                    if (b == a) continue;
                    for (size_t c = 0; c < 4; ++c) {
                        if (c == a || c == b) continue;
                        for (size_t d = 0; d < 4; ++d) {
                            if (d == a || d == b || d == c) continue;
                            const size_t i0 = subset[a];
                            const size_t i1 = subset[b];
                            const size_t i2 = subset[c];
                            const size_t i3 = subset[d];
                            if (p2_count >= 4 && p3_count + 3 <= 6 &&
                                p2[i1] == p2[i2] && p2[i1] == p2[i3]) {
                                const int64_t x = p2[i0];
                                const int64_t y = p2[i1];
                                if (y > x) {
                                    p2_count -= 4;
                                    p3[p3_count] = x;
                                    p3[p3_count + 1] = y;
                                    p3[p3_count + 2] = x + y;
                                    p3_count += 3;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    int64_t snapshot[NSICHNEU_OUTPUT_COUNT];
    size_t position = 0;
    snapshot[position++] = p1_count;
    for (size_t index = 0; index < 3; ++index) snapshot[position++] = p1[index];
    snapshot[position++] = p2_count;
    for (size_t index = 0; index < 5; ++index) snapshot[position++] = p2[index];
    snapshot[position++] = p3_count;
    for (size_t index = 0; index < 6; ++index) snapshot[position++] = p3[index];

    for (size_t index = 0; index < NSICHNEU_OUTPUT_COUNT; ++index) {
        const uint64_t value = (uint64_t)snapshot[index];
        for (size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = (uint8_t)(value >> (byte * 8));
    }
    return NSICHNEU_OUTPUT_COUNT * 8;
}
