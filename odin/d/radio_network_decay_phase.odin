package radio_network_decay_phase

import "core:c"

MAX_N :: 8
MAX_INPUT :: 75

put64 :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
radio_network_decay_phase :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT do return -1
    n64, k64, initial := input[0], input[1], input[2]
    if n64 < 2 || n64 > 8 || k64 < 1 || k64 > 8 || length != c.size_t(3+n64+n64*k64) do return -1
    n, k := int(n64), int(k64)
    full := (u64(1) << n)-1
    if initial <= 0 || (u64(initial) & ~full) != 0 do return -1
    adjacency: [MAX_N]u64
    for v := 0; v < n; v += 1 {
        raw := input[3+v]
        if raw < 0 || (u64(raw) & ~full) != 0 || (u64(raw) & (u64(1) << v)) != 0 do return -1
        adjacency[v] = u64(raw)
    }
    for u := 0; u < n; u += 1 { for v := 0; v < n; v += 1 {
        if ((adjacency[u] >> v) & 1) != ((adjacency[v] >> u) & 1) do return -1
    } }
    tape_at := 3+n
    for i := 0; i < n*k; i += 1 do if input[tape_at+i] != 0 && input[tape_at+i] != 1 do return -1
    if output == nil || capacity < 16 do return -2
    active: [MAX_N]bool
    for v := 0; v < n; v += 1 { active[v] = ((u64(initial) >> v) & 1) != 0 }
    newly: u64 = 0
    transmissions: i64 = 0
    for slot := 0; slot < k; slot += 1 {
        for sender := 0; sender < n; sender += 1 { if active[sender] { transmissions += 1 } }
        for receiver := 0; receiver < n; receiver += 1 {
            if ((u64(initial) >> receiver) & 1) != 0 do continue
            count := 0
            for sender := 0; sender < n; sender += 1 { if active[sender] && ((adjacency[sender] >> receiver) & 1) != 0 { count += 1 } }
            if count == 1 { newly |= u64(1) << receiver }
        }
        for sender := 0; sender < n; sender += 1 { if active[sender] && (input[tape_at+sender*k+slot] == 0 || slot+1 == k) { active[sender] = false } }
    }
    staged: [16]u8
    put64(&staged[0], 0, i64(newly)); put64(&staged[0], 8, transmissions)
    for i := 0; i < 16; i += 1 { output[i] = staged[i] }
    return 16
}
