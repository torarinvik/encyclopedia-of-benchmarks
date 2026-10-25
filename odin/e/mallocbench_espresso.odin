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
package mallocbench_espresso

import "core:c"

MAX_VARS :: 5
MAX_TERMS :: 32

cube_covers :: proc "contextless" (fixed, value, minterm: u32) -> bool {
	return (minterm & fixed) == value
}

@(export)
mallocbench_espresso :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	vars_value := input[0]
	if vars_value < 1 || vars_value > MAX_VARS || input[1] < 0 || input[2] < 0 do return -1
	vars := u32(vars_value)
	minterms := 1u32 << vars
	valid := (u64(1) << minterms) - 1
	onset, dcset := u64(input[1]), u64(input[2])
	if ((onset | dcset) & ~valid) != 0 || (onset & dcset) != 0 do return -1

	fixed: [MAX_TERMS]u32
	values: [MAX_TERMS]u32
	count := 0
	full := minterms - 1
	for m := u32(0); m < minterms; m += 1 {
		if (onset & (u64(1) << m)) != 0 {
			fixed[count], values[count] = full, m
			count += 1
		}
	}
	allowed := onset | dcset
	for i := 0; i < count; i += 1 {
		for bit := u32(0); bit < vars; bit += 1 {
			candidate_fixed := fixed[i] & ~(u32(1) << bit)
			candidate_value := values[i] & candidate_fixed
			legal := true
			for m := u32(0); m < minterms; m += 1 {
				if cube_covers(candidate_fixed, candidate_value, m) && (allowed & (u64(1) << m)) == 0 {
					legal = false
					break
				}
			}
			if legal { fixed[i], values[i] = candidate_fixed, candidate_value }
		}
	}
	active: [MAX_TERMS]bool
	for i := 0; i < count; i += 1 { active[i] = true }
	for i := 0; i < count; i += 1 {
		redundant := true
		for m := u32(0); m < minterms; m += 1 {
			if (onset & (u64(1) << m)) == 0 || !cube_covers(fixed[i], values[i], m) do continue
			covered := false
			for j := 0; j < count; j += 1 {
				if j != i && active[j] && cube_covers(fixed[j], values[j], m) { covered = true; break }
			}
			if !covered { redundant = false; break }
		}
		if redundant { active[i] = false }
	}
	cubes, literals := 0, 0
	for i := 0; i < count; i += 1 {
		if !active[i] do continue
		cubes += 1
		for bit := u32(0); bit < vars; bit += 1 { literals += int((fixed[i] >> bit) & 1) }
	}
	return i64(cubes) * 1024 + i64(literals)
}
