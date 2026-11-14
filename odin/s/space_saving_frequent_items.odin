package space_saving_frequent_items

import "core:c"

Entry :: struct { item, estimate, error: i64 }

@(export)
space_saving_frequent_items :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 67 do return -1
    kr, nr := input[0], input[1]
    if kr < 1 || kr > 8 || nr < 0 || nr > 64 || length != c.size_t(2+nr) do return -1
    k, n := int(kr), int(nr)
    for i := 0; i < n; i += 1 { if input[2+i] < -1000 || input[2+i] > 1000 do return -1 }
    entries: [8]Entry
    used := 0
    for i := 0; i < n; i += 1 {
        item := input[2+i]
        slot := 0
        for slot < used && entries[slot].item != item { slot += 1 }
        if slot < used { entries[slot].estimate += 1; continue }
        if used < k { entries[used] = Entry{item,1,0}; used += 1; continue }
        victim := 0
        for j := 1; j < used; j += 1 {
            if entries[j].estimate < entries[victim].estimate || (entries[j].estimate == entries[victim].estimate && entries[j].item < entries[victim].item) { victim = j }
        }
        minimum := entries[victim].estimate
        entries[victim] = Entry{item,minimum+1,minimum}
    }
    for i := 1; i < used; i += 1 {
        value := entries[i]
        j := i
        for j > 0 && entries[j-1].item > value.item { entries[j] = entries[j-1]; j -= 1 }
        entries[j] = value
    }
    words := 1+3*used
    bytes := 8*words
    if output == nil || capacity < c.size_t(bytes) do return -2
    fields: [25]i64
    fields[0] = i64(used)
    for i := 0; i < used; i += 1 {
        fields[1+3*i] = entries[i].item; fields[2+3*i] = entries[i].estimate; fields[3+3*i] = entries[i].error
    }
    staged: [200]u8
    for i := 0; i < words; i += 1 {
        bits := transmute(u64)fields[i]
        for b := 0; b < 8; b += 1 { staged[8*i+b] = u8((bits >> (8*b)) & 255) }
    }
    for i := 0; i < bytes; i += 1 { output[i] = staged[i] }
    return i64(bytes)
}
