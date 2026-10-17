const MAX_OPERATIONS: usize = 256;
const MAX_QUEUE_LENGTH: usize = 64;
const MAX_VALID_INPUT_LENGTH: usize = 513;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 514;
const FNV_OFFSET: u64 = 14_695_981_039_346_656_037;
const FNV_PRIME: u64 = 1_099_511_628_211;

fn hash_byte(hash: &mut u64, byte: u8) {
    *hash = (*hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME);
}

fn hash_u16(hash: &mut u64, value: u16) {
    for byte in 0..2 { hash_byte(hash, (value >> (8 * byte)) as u8); }
}

fn hash_i32(hash: &mut u64, value: i32) {
    for byte in 0..4 { hash_byte(hash, ((value as u32) >> (8 * byte)) as u8); }
}

fn hash_i64(hash: &mut u64, value: i64) {
    for byte in 0..8 { hash_byte(hash, ((value as u64) >> (8 * byte)) as u8); }
}

#[no_mangle]
pub unsafe extern "C" fn clojure_persistent_list_queue(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_OPERATIONS as i64 { return -1; }
    let operation_count = values[0] as usize;
    if length != 1 + operation_count * 2 || length > MAX_VALID_INPUT_LENGTH { return -1; }

    let mut newest_first = [0_i32; MAX_QUEUE_LENGTH];
    let mut queue_size = 0_usize;
    let mut results = [0_i64; MAX_OPERATIONS];
    let mut opcodes = [0_u8; MAX_OPERATIONS];
    for operation in 0..operation_count {
        let offset = 1 + 2 * operation;
        let opcode_value = values[offset];
        let argument = values[offset + 1];
        if !(0..=3).contains(&opcode_value) { return -1; }
        let opcode = opcode_value as u8;
        opcodes[operation] = opcode;
        if opcode == 0 {
            if argument < i32::MIN as i64 || argument > i32::MAX as i64 || queue_size >= MAX_QUEUE_LENGTH { return -1; }
            for index in (1..=queue_size).rev() { newest_first[index] = newest_first[index - 1]; }
            newest_first[0] = argument as i32;
            queue_size += 1;
            results[operation] = queue_size as i64;
        } else if opcode == 1 {
            if argument != 0 { return -1; }
            if queue_size > 0 { queue_size -= 1; }
            results[operation] = queue_size as i64;
        } else if opcode == 2 {
            if argument != 0 { return -1; }
            results[operation] = if queue_size == 0 { i64::MIN } else { newest_first[queue_size - 1] as i64 };
        } else {
            if argument != 0 { return -1; }
            results[operation] = if queue_size == 0 { 1 } else { 0 };
        }
    }

    let mut hash = FNV_OFFSET;
    hash_u16(&mut hash, operation_count as u16);
    for operation in 0..operation_count {
        hash_byte(&mut hash, opcodes[operation]);
        hash_i64(&mut hash, results[operation]);
    }
    hash_u16(&mut hash, queue_size as u16);
    for index in (0..queue_size).rev() { hash_i32(&mut hash, newest_first[index]); }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}
