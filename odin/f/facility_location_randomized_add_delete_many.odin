package facility_location_randomized_add_delete_many
import "core:c"
MAX_N :: 5
MAX_F :: 5
MAX_Q :: 8
MAX_P :: 10
MAX_PARSEABLE :: 128

put :: proc(out: [^]u8, at: int, value: i64) { bits := u64(value); for i := 0; i < 8; i += 1 { out[at+i] = u8(bits & 255); bits >>= 8 } }
state_cost :: proc(n, f: int, d: ^([MAX_P][MAX_P]i64), demand, assignment: ^([MAX_N]i64), fee: ^([MAX_F]i64), mask: u32) -> i64 {
    total: i64 = 0
    for s := 0; s < f; s += 1 { if mask & (u32(1) << s) != 0 { total += fee[s] } }
    for j := 0; j < n; j += 1 { total += demand[j] * d[j][n+int(assignment[j])] }
    return total
}

@(export)
facility_location_randomized_add_delete_many :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 12 || length > MAX_PARSEABLE do return -1
    n0, f0, q0, raw := input[0], input[1], input[2], input[3]
    if n0 < 1 || n0 > 5 || f0 < 1 || f0 > 5 || q0 < 1 || q0 > 8 || raw <= 0 || u64(raw) >= (u64(1) << int(f0)) do return -1
    n, f, q := int(n0), int(f0), int(q0); p := n+f
    if length != c.size_t(4+2*n+p*p+f+q) do return -1
    mask := u32(raw)
    assignment: [MAX_N]i64; demand: [MAX_N]i64; d: [MAX_P][MAX_P]i64; fee: [MAX_F]i64; tape: [MAX_Q]i64
    pos := 4
    for j := 0; j < n; j += 1 { assignment[j] = input[pos]; pos += 1; if assignment[j] < 0 || assignment[j] >= f0 || mask & (u32(1) << int(assignment[j])) == 0 do return -1 }
    for j := 0; j < n; j += 1 { demand[j] = input[pos]; pos += 1; if demand[j] < 1 || demand[j] > 10 do return -1 }
    for i := 0; i < p; i += 1 { for j := 0; j < p; j += 1 { v := input[pos]; pos += 1; if v < 0 || v > 1000 do return -1; d[i][j] = v } }
    for i := 0; i < p; i += 1 { if d[i][i] != 0 do return -1; for j := 0; j < p; j += 1 { if i != j && d[i][j] == 0 do return -1; if d[i][j] != d[j][i] do return -1; for k := 0; k < p; k += 1 { if d[i][j] > d[i][k]+d[k][j] do return -1 } } }
    for s := 0; s < f; s += 1 { fee[s] = input[pos]; pos += 1; if fee[s] < 0 || fee[s] > 1000 do return -1 }
    for t := 0; t < q; t += 1 { tape[t] = input[pos]; pos += 1; if tape[t] < 0 || tape[t] >= f0 do return -1 }
    costs: [MAX_Q]i64; accepted: [MAX_Q]i64
    current := state_cost(n,f,&d,&demand,&assignment,&fee,mask); count: i64 = 0
    for step := 0; step < q; step += 1 {
        candidate := int(tape[step]); bit := u32(1) << candidate; did: i64 = 0
        if mask & bit == 0 {
            closer: [MAX_N]bool; gain := -fee[candidate]
            for j := 0; j < n; j += 1 { old := int(assignment[j]); if d[j][n+candidate] < d[j][n+old] { closer[j] = true; gain += demand[j]*(d[j][n+old]-d[j][n+candidate]) } }
            drop: u32 = 0
            for s := 0; s < f; s += 1 { if mask & (u32(1)<<s) != 0 { cg := fee[s]; for j := 0; j < n; j += 1 { if int(assignment[j]) == s && !closer[j] { cg += demand[j]*(d[j][n+s]-d[j][n+candidate]) } }; if cg > 0 { drop |= u32(1)<<s; gain += cg } } }
            if gain > 0 { mask = (mask|bit)&~drop; for j := 0; j < n; j += 1 { if closer[j] || drop & (u32(1)<<int(assignment[j])) != 0 { assignment[j] = i64(candidate) } }; current = state_cost(n,f,&d,&demand,&assignment,&fee,mask); did=1; count+=1 }
        }
        costs[step]=current; accepted[step]=did
    }
    bytes := 8*(2*q+3+n); if output == nil || capacity < c.size_t(bytes) do return -2
    pos=0; for t := 0; t < q; t += 1 { put(output,pos,costs[t]); pos+=8 }; for t := 0; t < q; t += 1 { put(output,pos,accepted[t]); pos+=8 }
    put(output,pos,current); pos+=8; put(output,pos,i64(mask)); pos+=8; for j := 0; j < n; j += 1 { put(output,pos,assignment[j]); pos+=8 }; put(output,pos,count); pos+=8
    return i64(pos)
}
