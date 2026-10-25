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
#include <cstddef>
#include <cstdint>

namespace {
constexpr unsigned MAX_VARS = 5;
constexpr unsigned MAX_TERMS = 32;

bool cube_covers(unsigned fixed, unsigned value, unsigned minterm) {
    return (minterm & fixed) == value;
}
}

extern "C" std::int64_t mallocbench_espresso(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length != 3) return -1;
    const auto vars_value = input[0];
    if (vars_value < 1 || vars_value > MAX_VARS || input[1] < 0 || input[2] < 0) return -1;
    const unsigned vars = static_cast<unsigned>(vars_value);
    const unsigned minterms = 1u << vars;
    const auto valid = (std::uint64_t{1} << minterms) - 1;
    const auto onset = static_cast<std::uint64_t>(input[1]);
    const auto dcset = static_cast<std::uint64_t>(input[2]);
    if (((onset | dcset) & ~valid) != 0 || (onset & dcset) != 0) return -1;

    unsigned fixed[MAX_TERMS]{}, value[MAX_TERMS]{};
    unsigned count = 0;
    const unsigned full = minterms - 1;
    for (unsigned m = 0; m < minterms; ++m) {
        if ((onset & (std::uint64_t{1} << m)) != 0) {
            fixed[count] = full;
            value[count++] = m;
        }
    }
    const auto allowed = onset | dcset;
    for (unsigned i = 0; i < count; ++i) {
        for (unsigned bit = 0; bit < vars; ++bit) {
            const unsigned candidate_fixed = fixed[i] & ~(1u << bit);
            const unsigned candidate_value = value[i] & candidate_fixed;
            bool legal = true;
            for (unsigned m = 0; m < minterms; ++m) {
                if (cube_covers(candidate_fixed, candidate_value, m) &&
                    (allowed & (std::uint64_t{1} << m)) == 0) {
                    legal = false;
                    break;
                }
            }
            if (legal) { fixed[i] = candidate_fixed; value[i] = candidate_value; }
        }
    }
    bool active[MAX_TERMS]{};
    for (unsigned i = 0; i < count; ++i) active[i] = true;
    for (unsigned i = 0; i < count; ++i) {
        bool redundant = true;
        for (unsigned m = 0; m < minterms && redundant; ++m) {
            if ((onset & (std::uint64_t{1} << m)) == 0 || !cube_covers(fixed[i], value[i], m)) continue;
            bool covered = false;
            for (unsigned j = 0; j < count; ++j) {
                if (j != i && active[j] && cube_covers(fixed[j], value[j], m)) { covered = true; break; }
            }
            if (!covered) redundant = false;
        }
        if (redundant) active[i] = false;
    }
    unsigned cubes = 0, literals = 0;
    for (unsigned i = 0; i < count; ++i) {
        if (!active[i]) continue;
        ++cubes;
        for (unsigned bit = 0; bit < vars; ++bit) literals += (fixed[i] >> bit) & 1u;
    }
    return static_cast<std::int64_t>(cubes) * 1024 + literals;
}
