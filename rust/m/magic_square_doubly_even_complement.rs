const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn hash_byte(hash: u64, byte: u8) -> u64 {
    (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME)
}

fn hash_i32(mut hash: u64, value: i32) -> u64 {
    for byte in value.to_le_bytes() {
        hash = hash_byte(hash, byte);
    }
    hash
}

#[no_mangle]
pub extern "C" fn magic_square_doubly_even_complement(n: i64) -> i64 {
    if !(4..=64).contains(&n) || n % 4 != 0 {
        return -1;
    }
    let order = n as i32;
    let ceiling = order * order + 1;
    let mut hash = hash_byte(FNV_OFFSET, order as u8);

    for row in 0..order {
        for column in 0..order {
            let mut value = row * order + column + 1;
            let local_row = row % 4;
            let local_column = column % 4;
            if local_row == local_column || local_row + local_column == 3 {
                value = ceiling - value;
            }
            hash = hash_i32(hash, value);
        }
    }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}
