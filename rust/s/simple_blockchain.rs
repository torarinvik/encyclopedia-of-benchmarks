include!("../s/sha256.rs");

const MAX_VALUES: usize = 465;
const MAX_CHAIN: usize = 8;
const MAX_DATA: usize = 64;
const MAX_HEADER: usize = 160;
const NONCE_ATTEMPTS: i64 = 4096;
const MAX_OUTPUT: usize = 728;

#[derive(Clone, Copy)]
struct Block {
    timestamp_sec: i64,
    data: [u8; MAX_DATA],
    data_length: usize,
    previous_hash: [u8; 64],
    previous_hash_length: usize,
    nonce: i64,
    hash: [u8; 64],
}

impl Default for Block {
    fn default() -> Self {
        Self {
            timestamp_sec: 0,
            data: [0; MAX_DATA],
            data_length: 0,
            previous_hash: [0; 64],
            previous_hash_length: 0,
            nonce: 0,
            hash: [0; 64],
        }
    }
}

fn append_decimal(buffer: &mut [i64; MAX_HEADER], mut position: usize, mut value: i64) -> usize {
    let mut digits = [0_i64; 20];
    let mut count = 0;
    loop {
        digits[count] = b'0' as i64 + value % 10;
        count += 1;
        value /= 10;
        if value == 0 {
            break;
        }
    }
    while count != 0 {
        count -= 1;
        buffer[position] = digits[count];
        position += 1;
    }
    position
}

fn make_header(index: usize, block: &Block, nonce: i64, header: &mut [i64; MAX_HEADER]) -> usize {
    let mut length = append_decimal(header, 0, index as i64);
    length = append_decimal(header, length, block.timestamp_sec);
    header[length] = b'.' as i64;
    length += 1;
    header[length] = b'0' as i64;
    length += 1;
    for i in 0..block.data_length {
        header[length] = block.data[i] as i64;
        length += 1;
    }
    for i in 0..block.previous_hash_length {
        header[length] = block.previous_hash[i] as i64;
        length += 1;
    }
    append_decimal(header, length, nonce)
}

fn to_hex(digest: &[u8; 32], output: &mut [u8; 64]) {
    const HEX: &[u8; 16] = b"0123456789abcdef";
    for i in 0..32 {
        output[2 * i] = HEX[(digest[i] >> 4) as usize];
        output[2 * i + 1] = HEX[(digest[i] & 15) as usize];
    }
}

fn compute_hash(index: usize, block: &Block, nonce: i64, output: &mut [u8; 64]) -> bool {
    let mut header = [0_i64; MAX_HEADER];
    let mut digest = [0_u8; 32];
    let length = make_header(index, block, nonce, &mut header);
    let result = unsafe { sha256(header.as_ptr(), length, digest.as_mut_ptr(), digest.len()) };
    if result != 32 {
        return false;
    }
    to_hex(&digest, output);
    true
}

fn has_prefix(hash: &[u8; 64], difficulty: i64) -> bool {
    hash[..difficulty as usize].iter().all(|&byte| byte == b'0')
}

fn is_valid(blocks: &[Block; MAX_CHAIN], chain_length: usize, difficulty: i64) -> bool {
    for i in 1..chain_length {
        if blocks[i].previous_hash_length != 64
            || blocks[i].previous_hash != blocks[i - 1].hash
            || !has_prefix(&blocks[i].hash, difficulty)
        {
            return false;
        }
        let mut recomputed = [0_u8; 64];
        if !compute_hash(i, &blocks[i], blocks[i].nonce, &mut recomputed)
            || blocks[i].hash != recomputed
        {
            return false;
        }
    }
    true
}

fn write_i64(payload: &mut [u8; MAX_OUTPUT], mut position: usize, value: i64) -> usize {
    for (offset, byte) in value.to_le_bytes().iter().enumerate() {
        payload[position + offset] = *byte;
    }
    position += 8;
    position
}

#[no_mangle]
pub unsafe extern "C" fn simple_blockchain(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_VALUES {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let difficulty = values[0];
    let chain_length_value = values[1];
    if !(1..=2).contains(&difficulty) || !(1..=MAX_CHAIN as i64).contains(&chain_length_value) {
        return -1;
    }
    let chain_length = chain_length_value as usize;
    const MAX_TIMESTAMP: i64 = 2_147_483_647;
    if !(0..=MAX_TIMESTAMP).contains(&values[2]) {
        return -1;
    }

    let mut blocks = [Block::default(); MAX_CHAIN];
    blocks[0].timestamp_sec = values[2];
    const GENESIS: &[u8] = b"Genesis Block";
    blocks[0].data[..GENESIS.len()].copy_from_slice(GENESIS);
    blocks[0].data_length = GENESIS.len();
    blocks[0].previous_hash[0] = b'0';
    blocks[0].previous_hash_length = 1;

    let mut cursor = 3;
    for i in 1..chain_length {
        if cursor + 2 > length {
            return -1;
        }
        let timestamp_sec = values[cursor];
        let data_length_value = values[cursor + 1];
        cursor += 2;
        if !(0..=MAX_TIMESTAMP).contains(&timestamp_sec)
            || !(0..=MAX_DATA as i64).contains(&data_length_value)
        {
            return -1;
        }
        let data_length = data_length_value as usize;
        if cursor + data_length > length {
            return -1;
        }
        blocks[i].timestamp_sec = timestamp_sec;
        blocks[i].data_length = data_length;
        for j in 0..data_length {
            if !(0..=127).contains(&values[cursor + j]) {
                return -1;
            }
            blocks[i].data[j] = values[cursor + j] as u8;
        }
        cursor += data_length;
    }
    if cursor != length {
        return -1;
    }

    for i in 0..chain_length {
        if i > 0 {
            blocks[i].previous_hash.copy_from_slice(&blocks[i - 1].hash);
            blocks[i].previous_hash_length = 64;
        }
        let mut mined = false;
        for nonce in 0..NONCE_ATTEMPTS {
            let mut candidate = [0_u8; 64];
            if !compute_hash(i, &blocks[i], nonce, &mut candidate) {
                return -1;
            }
            if has_prefix(&candidate, difficulty) {
                blocks[i].nonce = nonce;
                blocks[i].hash = candidate;
                mined = true;
                break;
            }
        }
        if !mined {
            return -3;
        }
    }

    let valid = if is_valid(&blocks, chain_length, difficulty) { 1 } else { 0 };
    let mut payload = [0_u8; MAX_OUTPUT];
    let mut written = 0;
    written = write_i64(&mut payload, written, 0);
    written = write_i64(&mut payload, written, chain_length_value);
    for i in 0..chain_length {
        written = write_i64(&mut payload, written, i as i64);
        written = write_i64(&mut payload, written, blocks[i].timestamp_sec);
        written = write_i64(&mut payload, written, blocks[i].nonce);
        payload[written..written + 64].copy_from_slice(&blocks[i].hash);
        written += 64;
    }
    written = write_i64(&mut payload, written, valid);
    if output.is_null() || output_capacity < written {
        return -2;
    }
    std::ptr::copy_nonoverlapping(payload.as_ptr(), output, written);
    written as i64
}
