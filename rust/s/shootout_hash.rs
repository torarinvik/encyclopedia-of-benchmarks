const MAX_N: i64 = 3_500_000;
const BUCKET_PRIMES: [u32; 28] = [
    53, 97, 193, 389, 769, 1543, 3079, 6151, 12289, 24593,
    49157, 98317, 196613, 393241, 786433, 1572869, 3145739,
    6291469, 12582917, 25165843, 50331653, 100663319, 201326611,
    402653189, 805306457, 1610612741, 3221225473, 4294967291,
];

fn bucket_count_for(n: u32) -> usize {
    BUCKET_PRIMES.iter().copied().find(|&prime| prime >= n).unwrap() as usize
}

fn hash_key(mut value: u32, base: u32, buckets: usize) -> usize {
    let mut reverse = [0_u8; 16];
    let mut length = 0;
    loop {
        let digit = value % base;
        reverse[length] = if digit < 10 { b'0' + digit as u8 } else { b'a' + (digit - 10) as u8 };
        length += 1;
        value /= base;
        if value == 0 { break; }
    }
    let mut hash = 0_u64;
    while length > 0 {
        length -= 1;
        hash = 5 * hash + u64::from(reverse[length]);
    }
    (hash % buckets as u64) as usize
}

fn hex_key_matches_decimal(mut hex_value: u32, mut decimal_value: u32) -> bool {
    while hex_value != 0 && decimal_value != 0 {
        let digit = hex_value & 15;
        if digit >= 10 || digit != decimal_value % 10 { return false; }
        hex_value >>= 4;
        decimal_value /= 10;
    }
    hex_value == 0 && decimal_value == 0
}

#[no_mangle]
pub extern "C" fn shootout_hash(n: i64) -> i64 {
    if !(0..=MAX_N).contains(&n) { return -1; }
    let bound = n as u32;
    let bucket_count = bucket_count_for(bound);
    let mut heads = vec![0_u32; bucket_count];
    let mut next = vec![0_u32; bound as usize + 1];

    let mut value = 1_u32;
    while value <= bound {
        let bucket = hash_key(value, 16, bucket_count);
        let mut node = heads[bucket];
        let mut previous = 0_u32;
        while node != 0 {
            if node == value { break; }
            previous = node;
            node = next[node as usize];
        }
        if node == 0 {
            if previous == 0 { heads[bucket] = value; }
            else { next[previous as usize] = value; }
        }
        value += 1;
    }

    let mut found = 0_i64;
    value = bound;
    while value > 0 {
        let bucket = hash_key(value, 10, bucket_count);
        let mut node = heads[bucket];
        while node != 0 {
            if hex_key_matches_decimal(node, value) {
                found += 1;
                break;
            }
            node = next[node as usize];
        }
        value -= 1;
    }
    found
}
