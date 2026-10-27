fn store_i64_le(output &u8, offset int, value i64) {
    bits := u64(value)
    for b in 0 .. 8 { output[offset+b] = u8((bits >> (8*b)) & 255) }
}

@[export: 'knapsack_profit_scaling_small_large_fptas']
pub fn knapsack_profit_scaling_small_large_fptas(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || length < 4 || length > 18 { return -1 }
        cap := input[0]; n64 := input[1]
        if cap < 1 || cap > 30 || n64 < 1 || n64 > 8 || length != usize(2+2*n64) { return -1 }
        n := int(n64)
        mut weights := []i64{len:n, init:0}; mut profits := []i64{len:n, init:0}
        for i in 0 .. n { weights[i] = input[2+2*i]; profits[i] = input[3+2*i]; if weights[i] < 1 || weights[i] > 30 || profits[i] < 1 || profits[i] > 100 { return -1 } }
        if output == nil || capacity < 16 { return -2 }
        mut order := []int{len:n, init:0}; mut eligible := 0
        for i in 0 .. n { if weights[i] <= cap { order[eligible] = i; eligible++ } }
        for i in 1 .. eligible { key := order[i]; mut j := i; for j > 0 && profits[key]*weights[order[j-1]] > profits[order[j-1]]*weights[key] { order[j] = order[j-1]; j-- }; order[j] = key }
        mut upper_num := i64(0); mut upper_den := i64(1); mut room := cap
        for k in 0 .. eligible { i := order[k]; if weights[i] <= room { upper_num += profits[i]; room -= weights[i] } else { upper_num = upper_num*weights[i]+profits[i]*room; upper_den = weights[i]; break } }
        mut small := []int{len:n, init:0}; mut large := []int{len:n, init:0}; mut ns := 0; mut nl := 0
        for i in 0 .. n { if weights[i] <= cap { if 4*profits[i]*upper_den <= upper_num { small[ns] = i; ns++ } else { large[nl] = i; nl++ } } }
        for i in 1 .. ns { key := small[i]; mut j := i; for j > 0 && profits[key]*weights[small[j-1]] > profits[small[j-1]]*weights[key] { small[j] = small[j-1]; j-- }; small[j] = key }
        mut dpw := []i64{len:129, init:cap+1}; mut dpm := []i64{len:129, init:0}; dpw[0] = 0; mut reachable := 0
        for k in 0 .. nl { i := large[k]; value := if upper_num > 0 { int(16*profits[i]*upper_den/upper_num) } else { 0 }; mut q := reachable; for { if dpw[q] <= cap { dst := q+value; nw := dpw[q]+weights[i]; nm := dpm[q] | (i64(1)<<i); if nw < dpw[dst] || (nw == dpw[dst] && nm < dpm[dst]) { dpw[dst] = nw; dpm[dst] = nm } }; if q == 0 { break }; q-- }; reachable += value }
        mut best_mask := i64(0); mut best_profit := i64(0)
        for q in 0 .. reachable+1 { if dpw[q] <= cap { mut mask := dpm[q]; mut value := i64(0); mut remaining := cap-dpw[q]; for i in 0 .. n { if ((u64(mask)>>i)&1) != 0 { value += profits[i] } }; for k in 0 .. ns { i := small[k]; if weights[i] <= remaining { remaining -= weights[i]; mask |= i64(1)<<i; value += profits[i] } }; if value > best_profit || (value == best_profit && mask < best_mask) { best_profit = value; best_mask = mask } } }
        store_i64_le(output,0,best_mask); store_i64_le(output,8,best_profit); return 16
    }
}
