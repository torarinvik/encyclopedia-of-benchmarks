package two_left_hashing_operation_trace

import "core:c"

@(export)
two_left_hashing_operation_trace :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 5 || length > 162 do return -1
    if input[0] < 1 || input[0] > 40 || length != c.size_t(1+4*input[0]) do return -1
    q := int(input[0])
    for i := 0; i < q; i += 1 {
        op,key,left,right := input[1+4*i],input[2+4*i],input[3+4*i],input[4+4*i]
        if op < 0 || op > 2 || key < 0 || key > 63 || left < 0 || left > 7 || right < 0 || right > 7 do return -1
        for j := 0; j < i; j += 1 { if input[2+4*j] == key && (input[3+4*j] != left || input[4+4*j] != right) do return -1 }
    }
    bytes := 16*q
    if output == nil || capacity < c.size_t(bytes) do return -2
    var heads: [16]int; var sizes: [16]int
    var keys: [32]i64; var next: [32]int
    var statuses: [40]i64; var places: [40]i64
    for b := 0; b < 16; b += 1 { heads[b] = -1 }
    for x := 0; x < 32; x += 1 { keys[x] = -1; next[x] = -1 }
    live := 0
    for i := 0; i < q; i += 1 {
        op,key,lb,rb := int(input[1+4*i]),input[2+4*i],int(input[3+4*i]),8+int(input[4+4*i])
        found,fb := -1,-1
        for side := 0; side < 2; side += 1 {
            bucket := lb; if side == 1 { bucket = rb }
            x := heads[bucket]
            for x >= 0 { if keys[x] == key { found=x;fb=bucket;break };x=next[x] }
            if found >= 0 { break }
        }
        if op == 0 {
            if found >= 0 { statuses[i]=0;places[i]= -1;continue }
            if live == 32 do return -3
            use_left := sizes[lb] <= sizes[rb];bucket := rb;if use_left { bucket=lb }
            node := 0;for keys[node] >= 0 { node += 1 }
            keys[node]=key;next[node]=heads[bucket];heads[bucket]=node;sizes[bucket]+=1;live+=1
            statuses[i]=1;places[i]=1;if use_left { places[i]=0 }
        } else if op == 1 { statuses[i]=0;if found >= 0 { statuses[i]=1 };places[i]= -1
        } else if found < 0 { statuses[i]=0;places[i]= -1
        } else {
            prev,x := -1,heads[fb];for x != found { prev=x;x=next[x] }
            if prev < 0 { heads[fb]=next[x] } else { next[prev]=next[x] }
            keys[x]= -1;next[x]= -1;sizes[fb]-=1;live-=1;statuses[i]=1;places[i]= -1
        }
    }
    for i := 0; i < q; i += 1 { store_i64_le(output,16*i,statuses[i]);store_i64_le(output,16*i+8,places[i]) }
    return i64(bytes)
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for b := 0; b < 8; b += 1 { output[offset+b] = u8((bits >> u64(8*b)) & 255) }
}
