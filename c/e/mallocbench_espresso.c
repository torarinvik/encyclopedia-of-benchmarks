/*
 * Copyright (c) 1988, 1989, 1990, Regents of the University of California.
 * All rights reserved.
 *
 * Use and copying of this software and preparation of derivative works
 * based upon this software are permitted. However, any distribution of
 * this software or derivative works must include the above copyright
 * notice.
 *
 * This software is made available AS IS, and neither the Electronics
 * Research Laboratory or the University of California make any warranty
 * about the software, its performance or its conformity to any
 * specification.
 *
 * Clean-room bounded EXPAND/IRREDUNDANT profile; no upstream code copied.
 */
#include <stddef.h>
#include <stdint.h>

#define ESP_MAX_VARS 5
#define ESP_MAX_TERMS 32

static int esp_cube_covers(unsigned fixed, unsigned value, unsigned minterm)
{
    return (minterm & fixed) == value;
}

int64_t mallocbench_espresso(const int64_t *input, size_t length)
{
    if (input == NULL || length != 3) return -1;
    const int64_t vars_value = input[0];
    if (vars_value < 1 || vars_value > ESP_MAX_VARS || input[1] < 0 || input[2] < 0) return -1;
    const unsigned vars = (unsigned)vars_value;
    const unsigned minterms = 1u << vars;
    const uint64_t valid = (UINT64_C(1) << minterms) - 1;
    const uint64_t onset = (uint64_t)input[1];
    const uint64_t dcset = (uint64_t)input[2];
    if (((onset | dcset) & ~valid) != 0 || (onset & dcset) != 0) return -1;

    unsigned fixed[ESP_MAX_TERMS], value[ESP_MAX_TERMS];
    unsigned count = 0;
    const unsigned full = minterms - 1;
    for (unsigned m = 0; m < minterms; ++m) {
        if ((onset & (UINT64_C(1) << m)) != 0) {
            fixed[count] = full;
            value[count] = m;
            ++count;
        }
    }

    /* Expand each ON minterm in ascending variable order, retaining a cube
       only when it remains wholly inside ON union don't-care. */
    const uint64_t allowed = onset | dcset;
    for (unsigned i = 0; i < count; ++i) {
        for (unsigned bit = 0; bit < vars; ++bit) {
            const unsigned candidate_fixed = fixed[i] & ~(1u << bit);
            const unsigned candidate_value = value[i] & candidate_fixed;
            int legal = 1;
            for (unsigned m = 0; m < minterms; ++m) {
                if (esp_cube_covers(candidate_fixed, candidate_value, m) &&
                    (allowed & (UINT64_C(1) << m)) == 0) {
                    legal = 0;
                    break;
                }
            }
            if (legal) {
                fixed[i] = candidate_fixed;
                value[i] = candidate_value;
            }
        }
    }

    /* Remove a term only when every ON minterm it covers remains covered. */
    uint8_t active[ESP_MAX_TERMS] = {0};
    for (unsigned i = 0; i < count; ++i) active[i] = 1;
    for (unsigned i = 0; i < count; ++i) {
        int redundant = 1;
        for (unsigned m = 0; m < minterms && redundant; ++m) {
            if ((onset & (UINT64_C(1) << m)) == 0 ||
                !esp_cube_covers(fixed[i], value[i], m)) continue;
            int covered = 0;
            for (unsigned j = 0; j < count; ++j) {
                if (j != i && active[j] && esp_cube_covers(fixed[j], value[j], m)) {
                    covered = 1;
                    break;
                }
            }
            if (!covered) redundant = 0;
        }
        if (redundant) active[i] = 0;
    }

    unsigned cubes = 0, literals = 0;
    for (unsigned i = 0; i < count; ++i) {
        if (!active[i]) continue;
        ++cubes;
        for (unsigned bit = 0; bit < vars; ++bit)
            literals += (fixed[i] >> bit) & 1u;
    }
    return (int64_t)cubes * 1024 + literals;
}
