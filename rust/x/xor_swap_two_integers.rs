/// XOR-swap a bounded signed pair and pack the returned values into i64.
#[no_mangle]
pub extern "C" fn xor_swap_two_integers(first: i64, second: i64) -> i64 {
    if !(-32768..=32767).contains(&first) || !(-32768..=32767).contains(&second) { return -1; }
    let mut a = if first < 0 { first + 65_536 } else { first };
    let mut b = if second < 0 { second + 65_536 } else { second };
    a ^= b;
    b ^= a;
    a ^= b;
    let swapped_first = if a >= 32_768 { a - 65_536 } else { a };
    let swapped_second = if b >= 32_768 { b - 65_536 } else { b };
    (swapped_first + 32768) * 65536 + (swapped_second + 32768)
}
