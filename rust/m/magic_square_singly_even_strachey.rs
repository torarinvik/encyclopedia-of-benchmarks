const MAX_ORDER: i64 = 30;
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
pub extern "C" fn magic_square_singly_even_strachey(n: i64) -> i64 {
    if n < 6 || n > MAX_ORDER || n % 4 != 2 { return -1; }
    let order = n as usize;
    let half = order / 2;
    let k = half / 2;
    let block_size = half * half;
    let mut odd = [0i32; 30 * 30];
    let mut square = [0i32; 30 * 30];

    let (mut row, mut column) = (0, half / 2);
    odd[row * 30 + column] = 1;
    for value in 2..=block_size {
        let next_row = (row + half - 1) % half;
        let next_column = (column + 1) % half;
        if odd[next_row * 30 + next_column] == 0 {
            row = next_row;
            column = next_column;
        } else {
            row = (row + 1) % half;
        }
        odd[row * 30 + column] = value as i32;
    }

    for r in 0..half {
        for c in 0..half {
            let value = odd[r * 30 + c];
            square[r * 30 + c] = value;
            square[r * 30 + half + c] = value + (2 * block_size) as i32;
            square[(half + r) * 30 + c] = value + (3 * block_size) as i32;
            square[(half + r) * 30 + half + c] = value + block_size as i32;
        }
    }

    for r in 0..half {
        for c in 0..k { square.swap(r * 30 + c, (half + r) * 30 + c); }
        for c in half - (k - 1)..half { square.swap(r * 30 + half + c, (half + r) * 30 + half + c); }
    }
    square.swap(k * 30, (half + k) * 30);
    square.swap(k * 30 + k, (half + k) * 30 + k);

    let mut hash = hash_byte(FNV_OFFSET, order as u8);
    for r in 0..order { for c in 0..order { hash = hash_i32(hash, square[r * 30 + c]); } }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}
