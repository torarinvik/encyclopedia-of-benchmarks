module planted_3sat_clause_generator

// Unverified deterministic planted 3-SAT generator draft.
@[export: 'planted_3sat_clause_generator']
pub fn planted_3sat_clause_generator(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 5 || length > 83 { return -1 }
    unsafe {
        if input[0] < 3 || input[0] > 16 || input[1] < 0 || input[1] > 32 { return -1 }
        n, m := int(input[0]), int(input[1])
        if length != usize(2+n+2*m) { return -1 }
        for i in 0 .. n { if input[2+i] != 0 && input[2+i] != 1 { return -1 } }
        choices := n*(n-1)*(n-2)/6
        mut literals := [96]i64{}
        for clause in 0 .. m {
            raw, mask := input[2+n+2*clause], input[3+n+2*clause]
            if raw < 0 || raw >= i64(choices) || mask < 1 || mask > 7 { return -1 }
            mut rank := int(raw)
            mut next := 0
            for position in 0 .. 3 {
                mut variable := next
                for variable < n-(2-position) {
                    remaining := n-variable-1
                    ways := if position == 0 { remaining*(remaining-1)/2 } else if position == 1 { remaining } else { 1 }
                    if rank >= ways { rank -= ways; variable++; continue }
                    value := i64(variable+1)
                    literals[3*clause+position] = if input[2+variable] == ((mask >> position) & 1) { value } else { -value }
                    next = variable+1
                    break
                }
            }
        }
        bytes := 24*m
        if bytes == 0 { return 0 }
        if output == nil || capacity < usize(bytes) { return -2 }
        for i in 0 .. 3*m {
            bits := u64(literals[i])
            for b in 0 .. 8 { output[8*i+b] = u8(bits >> (8*b)) }
        }
        return i64(bytes)
    }
}
