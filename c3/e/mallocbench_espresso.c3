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
module mallocbench_espresso;

const MAX_VARS = 5;
const MAX_TERMS = 32;

fn bool cube_covers(uint fixed, uint value, uint minterm) {
    return (minterm & fixed) == value;
}

fn long mallocbench_espresso(long* input, usz length) @export("mallocbench_espresso") {
    if (input == null || length != 3) return -1;
    long vars_value = input[0];
    if (vars_value < 1 || vars_value > MAX_VARS || input[1] < 0 || input[2] < 0) return -1;
    uint vars = (uint)vars_value;
    uint minterms = 1u << vars;
    ulong valid = (1ul << minterms) - 1;
    ulong onset = (ulong)input[1], dcset = (ulong)input[2];
    if (((onset | dcset) & ~valid) != 0 || (onset & dcset) != 0) return -1;

    uint[MAX_TERMS] fixed, value;
    usz count = 0;
    uint full = minterms - 1;
    for (uint m = 0; m < minterms; m++) {
        if ((onset & (1ul << m)) != 0) {
            fixed[count] = full;
            value[count] = m;
            count++;
        }
    }
    ulong allowed = onset | dcset;
    for (usz i = 0; i < count; i++) {
        for (uint bit = 0; bit < vars; bit++) {
            uint candidate_fixed = fixed[i] & ~(1u << bit);
            uint candidate_value = value[i] & candidate_fixed;
            bool legal = true;
            for (uint m = 0; m < minterms; m++) {
                if (cube_covers(candidate_fixed, candidate_value, m) && (allowed & (1ul << m)) == 0) {
                    legal = false;
                    break;
                }
            }
            if (legal) {
                fixed[i] = candidate_fixed;
                value[i] = candidate_value;
            }
        }
    }
    bool[MAX_TERMS] active;
    for (usz i = 0; i < count; i++) active[i] = true;
    for (usz i = 0; i < count; i++) {
        bool redundant = true;
        for (uint m = 0; m < minterms && redundant; m++) {
            if ((onset & (1ul << m)) == 0 || !cube_covers(fixed[i], value[i], m)) continue;
            bool covered = false;
            for (usz j = 0; j < count; j++) {
                if (j != i && active[j] && cube_covers(fixed[j], value[j], m)) {
                    covered = true;
                    break;
                }
            }
            if (!covered) redundant = false;
        }
        if (redundant) active[i] = false;
    }
    long cubes = 0, literals = 0;
    for (usz i = 0; i < count; i++) {
        if (!active[i]) continue;
        cubes++;
        for (uint bit = 0; bit < vars; bit++) literals += (fixed[i] >> bit) & 1u;
    }
    return cubes * 1024 + literals;
}
