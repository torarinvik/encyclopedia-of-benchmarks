package radio_network_bgi_broadcast

import "core:c"

MAX_N :: 8
MAX_INPUT :: 203
MAX_OUTPUT :: 88

ceil_log2 :: proc(value: int) -> int {
    exponent := 0
    power := 1
    for power < value { power *= 2; exponent += 1 }
    return exponent
}

put64 :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
radio_network_bgi_broadcast :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT do return -1
    n64, source64, delta64 := input[0], input[1], input[2]
    if n64 < 2 || n64 > 8 || source64 < 0 || source64 >= n64 || delta64 < 2 || delta64 > 8 do return -1
    n, source, delta := int(n64), int(source64), int(delta64)
    k, t := 2*ceil_log2(delta), ceil_log2(2*n)
    tape_at, tape_count := 3+n, n*t*k
    if length != c.size_t(tape_at+tape_count) do return -1
    full := (u64(1) << n)-1
    adjacency: [MAX_N]u64
    for v := 0; v < n; v += 1 {
        raw := input[3+v]
        if raw < 0 || (u64(raw) & ~full) != 0 || (u64(raw) & (u64(1) << v)) != 0 do return -1
        adjacency[v] = u64(raw)
        degree := 0
        for u := 0; u < n; u += 1 { if ((adjacency[v] >> u) & 1) != 0 { degree += 1 } }
        if degree > delta do return -1
    }
    for u := 0; u < n; u += 1 { for v := 0; v < n; v += 1 {
        if ((adjacency[u] >> v) & 1) != ((adjacency[v] >> u) & 1) do return -1
    } }
    for i := 0; i < tape_count; i += 1 { if input[tape_at+i] != 0 && input[tape_at+i] != 1 do return -1 }
    output_bytes := 8*(n+3)
    if output == nil || capacity < c.size_t(output_bytes) do return -2
    informed: [MAX_N]bool
    active: [MAX_N]bool
    newly: [MAX_N]bool
    calls: [MAX_N]int
    first_slot: [MAX_N]i64
    for v := 0; v < n; v += 1 { first_slot[v] = -1 }
    informed[source] = true; first_slot[source] = 0
    transmissions: i64 = 0
    phases: i64 = 0
    for phase := 0; phase < n*t; phase += 1 {
        starters := 0
        for v := 0; v < n; v += 1 {
            active[v] = informed[v] && calls[v] < t
            newly[v] = false
            if active[v] { starters += 1 }
        }
        if starters == 0 do break
        for slot := 0; slot < k; slot += 1 {
            for sender := 0; sender < n; sender += 1 { if active[sender] { transmissions += 1 } }
            for receiver := 0; receiver < n; receiver += 1 {
                if informed[receiver] || newly[receiver] do continue
                sender_count := 0
                for sender := 0; sender < n; sender += 1 {
                    if active[sender] && ((adjacency[sender] >> receiver) & 1) != 0 { sender_count += 1 }
                }
                if sender_count == 1 { newly[receiver] = true; first_slot[receiver] = i64(phase*k+slot) }
            }
            for sender := 0; sender < n; sender += 1 { if active[sender] {
                at := tape_at + (sender*t+calls[sender])*k + slot
                if slot+1 == k || input[at] == 0 { active[sender] = false }
            } }
        }
        for v := 0; v < n; v += 1 {
            if informed[v] && calls[v] < t { calls[v] += 1 }
            if newly[v] { informed[v] = true }
        }
        phases = i64(phase+1)
    }
    staged: [MAX_OUTPUT]u8
    put64(&staged[0],0,n64); put64(&staged[0],8,phases); put64(&staged[0],16,transmissions)
    for v := 0; v < n; v += 1 { put64(&staged[0],24+8*v,first_slot[v]) }
    for i := 0; i < output_bytes; i += 1 { output[i] = staged[i] }
    return i64(output_bytes)
}
