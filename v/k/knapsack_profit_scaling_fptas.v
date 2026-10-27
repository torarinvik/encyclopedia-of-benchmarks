fn store_i64_le(output &u8, offset int, value i64) {
    bits := u64(value)
    for b in 0 .. 8 { output[offset+b] = u8((bits >> (8*b)) & 255) }
}

@[export: 'knapsack_profit_scaling_fptas']
pub fn knapsack_profit_scaling_fptas(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || length < 4 || length > 26 { return -1 }
        cap := input[0]; n64 := input[1]
        if cap < 1 || cap > 100 || n64 < 1 || n64 > 12 || length != usize(2 + 2*n64) { return -1 }
        n := int(n64)
        mut weights := []i64{len: n, init: 0}; mut profits := []i64{len: n, init: 0}
        for i in 0 .. n {
            weights[i] = input[2+2*i]; profits[i] = input[3+2*i]
            if weights[i] < 1 || weights[i] > 100 || profits[i] < 1 || profits[i] > 10000 { return -1 }
        }
        if output == nil || capacity < 16 { return -2 }
        mut order := []int{len: n, init: 0}; mut eligible := 0
        for i in 0 .. n { if weights[i] <= cap { order[eligible] = i; eligible++ } }
        for i in 1 .. eligible {
            key := order[i]; mut j := i
            for j > 0 && profits[key]*weights[order[j-1]] > profits[order[j-1]]*weights[key] { order[j] = order[j-1]; j-- }
            order[j] = key
        }
        mut upper := i64(0); mut room := cap
        for k in 0 .. eligible {
            i := order[k]
            if weights[i] <= room { upper += profits[i]; room -= weights[i] }
            else { upper += profits[i]*room/weights[i]; break }
        }
        mut dp_weight := []i64{len: 577, init: cap+1}; mut dp_mask := []i64{len: 577, init: 0}
        dp_weight[0] = 0; mut reachable := 0
        for i in 0 .. n {
            if weights[i] > cap || upper == 0 { continue }
            value := int(4*i64(n)*profits[i]/upper)
            if value == 0 { continue }
            mut q := reachable
            for q >= 0 {
                if dp_weight[q] <= cap {
                    next := q+value; nw := dp_weight[q]+weights[i]; nm := dp_mask[q] | (i64(1)<<i)
                    if nw < dp_weight[next] || (nw == dp_weight[next] && nm < dp_mask[next]) { dp_weight[next] = nw; dp_mask[next] = nm }
                }
                if q == 0 { break }; q--
            }
            reachable += value
        }
        mut best := 0
        for q in 1 .. 577 { if dp_weight[q] <= cap { best = q } }
        mask := dp_mask[best]; mut selected_profit := i64(0)
        for i in 0 .. n { if ((u64(mask)>>i)&1) != 0 { selected_profit += profits[i] } }
        store_i64_le(output, 0, mask); store_i64_le(output, 8, selected_profit)
        return 16
    }
}
