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
module mallocbench_espresso

const max_vars = 5
const max_terms = 32

fn cube_covers(fixed u32, value u32, minterm u32) bool {
	return (minterm & fixed) == value
}

@[export: 'mallocbench_espresso']
pub fn mallocbench_espresso(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 3 { return -1 }
		vars_value := input[0]
		if vars_value < 1 || vars_value > max_vars || input[1] < 0 || input[2] < 0 { return -1 }
		vars := u32(vars_value)
		minterms := u32(1) << vars
		valid := (u64(1) << minterms) - 1
		onset := u64(input[1])
		dcset := u64(input[2])
		if ((onset | dcset) & ~valid) != 0 || (onset & dcset) != 0 { return -1 }

		mut fixed := [max_terms]u32{}
		mut values := [max_terms]u32{}
		mut count := 0
		full := minterms - 1
		for m in u32(0) .. minterms {
			if (onset & (u64(1) << m)) != 0 {
				fixed[count] = full
				values[count] = m
				count++
			}
		}
		allowed := onset | dcset
		for i in 0 .. count {
			for bit in u32(0) .. vars {
				candidate_fixed := fixed[i] & ~(u32(1) << bit)
				candidate_value := values[i] & candidate_fixed
				mut legal := true
				for m in u32(0) .. minterms {
					if cube_covers(candidate_fixed, candidate_value, m) && (allowed & (u64(1) << m)) == 0 {
						legal = false
						break
					}
				}
				if legal {
					fixed[i] = candidate_fixed
					values[i] = candidate_value
				}
			}
		}
		mut active := [max_terms]bool{}
		for i in 0 .. count { active[i] = true }
		for i in 0 .. count {
			mut redundant := true
			for m in u32(0) .. minterms {
				if (onset & (u64(1) << m)) == 0 || !cube_covers(fixed[i], values[i], m) { continue }
				mut covered := false
				for j in 0 .. count {
					if j != i && active[j] && cube_covers(fixed[j], values[j], m) {
						covered = true
						break
					}
				}
				if !covered {
					redundant = false
					break
				}
			}
			if redundant { active[i] = false }
		}
		mut cubes := i64(0)
		mut literals := i64(0)
		for i in 0 .. count {
			if !active[i] { continue }
			cubes++
			for bit in u32(0) .. vars { literals += i64((fixed[i] >> bit) & 1) }
		}
		return cubes * 1024 + literals
	}
}
