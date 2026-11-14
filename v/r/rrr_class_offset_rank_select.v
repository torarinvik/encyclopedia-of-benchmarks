module rrr_class_offset_rank_select

fn rrr_popcount(value int) int {
    mut result := 0
    for bit in 0 .. 8 { result += (value >> bit) & 1 }
    return result
}

fn rrr_decode(cls int, offset int) int {
    mut remaining := offset
    for candidate in 0 .. 256 {
        if rrr_popcount(candidate) == cls {
            if remaining == 0 { return candidate }
            remaining--
        }
    }
    return 0
}

@[export: 'rrr_class_offset_rank_select']
pub fn rrr_class_offset_rank_select(input &i64, length usize, output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 3 || length > 35 { return -1 }
    nv := unsafe { input[0] }
    bv := unsafe { input[1] }
    qv := unsafe { input[2] }
    if nv < 1 || nv > 63 || bv < 0 || qv < 0 || qv > 16 { return -1 }
    n := int(nv)
    bits := u64(bv)
    q := int(qv)
    if bits >> n != 0 || length != usize(3+2*q) { return -1 }
    for i in 0 .. q {
        op := unsafe { input[3+2*i] }
        index := unsafe { input[4+2*i] }
        if (op != 0 && op != 1) || index < 1 || (op == 0 && index > nv) || (op == 1 && index > 64) { return -1 }
    }
    if unsafe { output == nil } || capacity < usize(8*q) { return -2 }
    mut classes := [8]int{}
    mut offsets := [8]int{}
    mut prefix := [9]int{}
    blocks := (n+7)/8
    for block_index in 0 .. blocks {
        byte_value := int((bits >> (8*block_index)) & 255)
        classes[block_index] = rrr_popcount(byte_value)
        for candidate in 0 .. byte_value {
            if rrr_popcount(candidate) == classes[block_index] { offsets[block_index]++ }
        }
        prefix[block_index+1] = prefix[block_index]+classes[block_index]
    }
    for i in 0 .. q {
        op := unsafe { input[3+2*i] }
        index := int(unsafe { input[4+2*i] })
        mut answer := -1
        if op == 0 {
            block_index := (index-1)/8
            byte_value := rrr_decode(classes[block_index], offsets[block_index])
            answer = prefix[block_index]
            for bit in 0 .. index-8*block_index { answer += (byte_value >> bit) & 1 }
        } else {
            mut block_index := 0
            for block_index < blocks && prefix[block_index+1] < index { block_index++ }
            if block_index < blocks {
                mut remaining := index-prefix[block_index]
                byte_value := rrr_decode(classes[block_index], offsets[block_index])
                mut bit := 0
                for bit < 8 && 8*block_index+bit < n {
                    if (byte_value >> bit) & 1 != 0 {
                        remaining--
                        if remaining == 0 { answer = 8*block_index+bit+1; break }
                    }
                    bit++
                }
            }
        }
        mut encoded := if answer < 0 { ~u64(0) } else { u64(answer) }
        for byte_index in 0 .. 8 {
            unsafe { output[8*i+byte_index] = u8(encoded & 255) }
            encoded >>= 8
        }
    }
    return i64(8*q)
}
