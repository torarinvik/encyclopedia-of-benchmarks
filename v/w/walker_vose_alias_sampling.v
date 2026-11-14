module walker_vose_alias_sampling

@[export: 'walker_vose_alias_sampling']
pub fn walker_vose_alias_sampling(input &i64, length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || length < 3 || length > 83 { return -1 }
        nr := input[0]
        qr := input[1]
        if nr < 1 || nr > 16 || qr < 0 || qr > 32 { return -1 }
        n := int(nr)
        q := int(qr)
        if length != 2+n+2*q { return -1 }
        mut total := i64(0)
        for i in 0 .. n {
            if input[2+i] < 0 || input[2+i] > 100 { return -1 }
            total += input[2+i]
        }
        if total == 0 { return -1 }
        for i in 0 .. q {
            col := input[2+n+2*i]
            ticket := input[3+n+2*i]
            if col < 0 || col >= nr || ticket < 0 || ticket >= total { return -1 }
        }
        if q == 0 { return 0 }
        if output == nil || capacity < usize(8*q) { return -2 }
        mut mass := [16]i64{}
        mut threshold := [16]i64{}
        mut aliases := [16]int{}
        mut small := [16]int{}
        mut large := [16]int{}
        mut ns := 0
        mut nl := 0
        for i in 0 .. n {
            mass[i] = nr*input[2+i]
            threshold[i] = total
            aliases[i] = i
            if mass[i] < total { small[ns] = i; ns++ } else { large[nl] = i; nl++ }
        }
        for ns > 0 && nl > 0 {
            ns--
            nl--
            low := small[ns]
            high := large[nl]
            threshold[low] = mass[low]
            aliases[low] = high
            mass[high] -= total-mass[low]
            if mass[high] < total { small[ns] = high; ns++ } else { large[nl] = high; nl++ }
        }
        mut staged := [256]u8{}
        for i in 0 .. q {
            col := int(input[2+n+2*i])
            chosen := if input[3+n+2*i] < threshold[col] { col } else { aliases[col] }
            bits := u64(chosen)
            for b in 0 .. 8 { staged[8*i+b] = u8((bits >> (8*b)) & 255) }
        }
        for i in 0 .. 8*q { output[i] = staged[i] }
        return i64(8*q)
    }
}
