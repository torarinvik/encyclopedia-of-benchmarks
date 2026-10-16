package generic_hash_map
import "core:c"

hash_value :: proc "contextless" (h0: u64, value: i64) -> u64 {
    h := h0
    bits := transmute(u64)value
    for i := u32(0); i < 8; i += 1 { h = (h ~ ((bits >> (8*i)) & 255)) * 0x100000001b3 }
    return h
}

@(export)
generic_hash_map :: proc "c" (a: [^]i64, n: c.size_t) -> i64 {
    if a == nil || n < 1 || n > 385 || a[0] < 0 || a[0] > 128 || n != c.size_t(1 + 3*a[0]) do return -1
    keys: [64]i64
    vals: [64]i64
    next: [64]i32
    head: [128]i32
    active: [64]bool
    for i := 0; i < 64; i += 1 { next[i] = -1 }
    for i := 0; i < 128; i += 1 { head[i] = -1 }
    size := 0; bc := 16; h := u64(0xcbf29ce484222325)
    for oi := 0; oi < int(a[0]); oi += 1 {
        op := a[1+3*oi]; key := a[2+3*oi]; value := a[3+3*oi]
        if key < 0 || key > 1000000 do return -1
        b := int(key % i64(bc)); found := i32(-1)
        for j := head[b]; j >= 0; j = next[j] { if keys[j] == key { found = j; break } }
        if op == 0 {
            if value < -1000000 || value > 1000000 do return -1
            if found >= 0 { vals[found] = value } else {
                if size >= 64 do return -1
                slot := 0; for active[slot] { slot += 1 }
                active[slot] = true; keys[slot] = key; vals[slot] = value; next[slot] = head[b]; head[b] = i32(slot); size += 1
                if size*4 > bc*3 && bc < 128 { bc *= 2; for i := 0; i < 128; i += 1 { head[i] = -1 }; for q := 0; q < 64; q += 1 { if active[q] { b = int(keys[q] % i64(bc)); next[q] = head[b]; head[b] = i32(q) } } }
            }
        } else if op == 1 || op == 3 {
            if value != 0 do return -1
            observed := i64(0)
            if op == 1 { observed = -9223372036854775807 - 1; if found >= 0 { observed = vals[found] } } else if found >= 0 { observed = 1 }
            h = hash_value(h, observed)
        } else if op == 2 {
            if value != 0 do return -1
            if found >= 0 { prev := i32(-1); for j := head[b]; j >= 0; j = next[j] { if j == found { if prev < 0 { head[b] = next[j] } else { next[prev] = next[j] }; break }; prev = j }; active[found] = false; size -= 1 }
        } else if op == 4 { if key != 0 || value != 0 do return -1; h = hash_value(h, i64(size)) } else { return -1 }
    }
    h = hash_value(h, i64(size)); used: [64]bool
    for rank := 0; rank < size; rank += 1 { best := -1; for i := 0; i < 64; i += 1 { if active[i] && !used[i] && (best < 0 || keys[i] < keys[best]) { best = i } }; used[best] = true; h = hash_value(hash_value(h, keys[best]), vals[best]) }
    return transmute(i64)h
}
