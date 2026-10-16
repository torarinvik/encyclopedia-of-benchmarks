const MAX_ORDER: i64 = 31;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn hash_byte(hash: u64, byte: u8) -> u64 {
    (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME)
}

fn hash_i32(mut hash: u64, value: i32) -> u64 {
    for byte in value.to_le_bytes() { hash = hash_byte(hash, byte); }
    hash
}

#[no_mangle]
pub extern "C" fn magic_square(n: i64) -> i64 {
    if n < 1 || n > MAX_ORDER || n % 2 == 0 { return -1; }
    let order = n as usize;
    let mut square = [0i32; 31 * 31];
    let mut row = order / 2;
    let mut column = order - 1;
    square[row * 31 + column] = 1;
    for value in 2..=order * order {
        let next_row = (row + order - 1) % order;
        let next_column = (column + 1) % order;
        if square[next_row * 31 + next_column] == 0 {
            row = next_row;
            column = next_column;
        } else {
            column = (column + order - 1) % order;
        }
        square[row * 31 + column] = value as i32;
    }
    let mut hash = hash_byte(FNV_OFFSET, order as u8);
    for r in 0..order {
        for c in 0..order { hash = hash_i32(hash, square[r * 31 + c]); }
    }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}
