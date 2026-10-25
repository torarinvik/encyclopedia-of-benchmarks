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
const MAX_VARS: usize = 5;
const MAX_TERMS: usize = 32;

fn cube_covers(fixed: u32, value: u32, minterm: u32) -> bool {
    minterm & fixed == value
}

#[no_mangle]
pub unsafe extern "C" fn mallocbench_espresso(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let vars_value = values[0];
    if vars_value < 1 || vars_value > MAX_VARS as i64 || values[1] < 0 || values[2] < 0 { return -1; }
    let vars = vars_value as usize;
    let minterms = 1usize << vars;
    let valid = (1u64 << minterms) - 1;
    let onset = values[1] as u64;
    let dcset = values[2] as u64;
    if ((onset | dcset) & !valid) != 0 || (onset & dcset) != 0 { return -1; }

    let mut fixed = [0u32; MAX_TERMS];
    let mut value = [0u32; MAX_TERMS];
    let mut count = 0usize;
    let full = (minterms - 1) as u32;
    for m in 0..minterms {
        if onset & (1u64 << m) != 0 {
            fixed[count] = full;
            value[count] = m as u32;
            count += 1;
        }
    }
    let allowed = onset | dcset;
    for i in 0..count {
        for bit in 0..vars {
            let candidate_fixed = fixed[i] & !(1u32 << bit);
            let candidate_value = value[i] & candidate_fixed;
            let mut legal = true;
            for m in 0..minterms {
                if cube_covers(candidate_fixed, candidate_value, m as u32) && allowed & (1u64 << m) == 0 {
                    legal = false;
                    break;
                }
            }
            if legal { fixed[i] = candidate_fixed; value[i] = candidate_value; }
        }
    }
    let mut active = [false; MAX_TERMS];
    for i in 0..count { active[i] = true; }
    for i in 0..count {
        let mut redundant = true;
        for m in 0..minterms {
            if onset & (1u64 << m) == 0 || !cube_covers(fixed[i], value[i], m as u32) { continue; }
            let mut covered = false;
            for j in 0..count {
                if j != i && active[j] && cube_covers(fixed[j], value[j], m as u32) { covered = true; break; }
            }
            if !covered { redundant = false; break; }
        }
        if redundant { active[i] = false; }
    }
    let mut cubes = 0i64;
    let mut literals = 0i64;
    for i in 0..count {
        if !active[i] { continue; }
        cubes += 1;
        literals += fixed[i].count_ones() as i64;
    }
    cubes * 1024 + literals
}
