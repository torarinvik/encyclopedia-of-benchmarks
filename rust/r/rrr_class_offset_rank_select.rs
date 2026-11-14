fn decode(class_count: u32, mut offset: usize) -> u8 {
    for candidate in 0_u16..256 {
        if candidate.count_ones() == class_count {
            if offset == 0 { return candidate as u8; }
            offset -= 1;
        }
    }
    0
}

#[no_mangle]
pub unsafe extern "C" fn rrr_class_offset_rank_select(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(3..=35).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=63).contains(&values[0]) || values[1] < 0 || !(0..=16).contains(&values[2]) { return -1; }
    let n = values[0] as usize;
    let bits = values[1] as u64;
    let q = values[2] as usize;
    if bits >> n != 0 || length != 3+2*q { return -1; }
    for i in 0..q {
        let op = values[3+2*i];
        let index = values[4+2*i];
        if (op != 0 && op != 1) || index < 1 || (op == 0 && index > n as i64) || (op == 1 && index > 64) { return -1; }
    }
    if output.is_null() || capacity < 8*q { return -2; }
    let mut classes = [0_u32; 8];
    let mut offsets = [0_usize; 8];
    let mut prefix = [0_usize; 9];
    let blocks = (n+7)/8;
    for block in 0..blocks {
        let byte = ((bits >> (8*block)) & 255) as u16;
        classes[block] = byte.count_ones();
        offsets[block] = (0..byte).filter(|v| v.count_ones() == classes[block]).count();
        prefix[block+1] = prefix[block] + classes[block] as usize;
    }
    for i in 0..q {
        let op = values[3+2*i];
        let index = values[4+2*i] as usize;
        let mut answer = -1_i64;
        if op == 0 {
            let block = (index-1)/8;
            let byte = decode(classes[block], offsets[block]);
            let mut count = prefix[block];
            for bit in 0..index-8*block { count += ((byte >> bit) & 1) as usize; }
            answer = count as i64;
        } else {
            let mut block = 0;
            while block < blocks && prefix[block+1] < index { block += 1; }
            if block < blocks {
                let mut remaining = index-prefix[block];
                let byte = decode(classes[block], offsets[block]);
                for bit in 0..8.min(n-8*block) {
                    if (byte >> bit) & 1 != 0 {
                        remaining -= 1;
                        if remaining == 0 { answer = (8*block+bit+1) as i64; break; }
                    }
                }
            }
        }
        let encoded = answer.to_le_bytes();
        std::ptr::copy_nonoverlapping(encoded.as_ptr(), output.add(8*i), 8);
    }
    (8*q) as i64
}
