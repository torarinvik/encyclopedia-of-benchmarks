const MAX_UNIVERSE: usize = 32;
const MAX_OPERATIONS: usize = 30;
const MAX_LENGTH: usize = 63;

#[no_mangle]
pub unsafe extern "C" fn sparse_set_dense_array(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=MAX_LENGTH).contains(&length) { return -1; }
    let words = std::slice::from_raw_parts(input,length);
    if words[0] < 1 || words[0] > MAX_UNIVERSE as i64
            || words[1] < 0 || words[1] > MAX_OPERATIONS as i64 { return -1; }
    let universe = words[0] as usize;
    let count = words[1] as usize;
    if length != 2+2*count { return -1; }
    for i in 0..count {
        let opcode = words[2+2*i];
        let key = words[3+2*i];
        if !(0..=3).contains(&opcode) || key < 0 || key >= universe as i64 { return -1; }
        if opcode == 3 && key != 0 { return -1; }
    }

    let mut dense = [0_i64; MAX_UNIVERSE];
    let mut sparse = [universe; MAX_UNIVERSE];
    let mut size = 0_usize;
    let mut answers = 0_i64;
    for i in 0..count {
        let opcode = words[2+2*i] as usize;
        let key = words[3+2*i] as usize;
        let index = sparse[key];
        let present = index < size && dense[index] == key as i64;
        let mut status = 0_i64;
        if opcode == 0 {
            if !present {
                dense[size] = key as i64;
                sparse[key] = size;
                size += 1;
                status = 1;
            }
        } else if opcode == 1 {
            if present {
                let last = dense[size-1] as usize;
                dense[index] = last as i64;
                sparse[last] = index;
                size -= 1;
                status = 1;
            }
        } else if opcode == 2 {
            status = present as i64;
        } else {
            status = (size != 0) as i64;
            size = 0;
        }
        answers = (answers << 1) | status;
    }
    let mut final_mask = 0_i64;
    for &key in &dense[..size] { final_mask |= 1_i64 << key; }
    (final_mask << count) | answers
}
