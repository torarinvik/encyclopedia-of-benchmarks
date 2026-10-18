const LIMBS: usize = 4;

unsafe fn divide_words(dividend: &[u32; LIMBS], divisor: &[u32; LIMBS],
                       quotient: &mut [u32; LIMBS], remainder: &mut [u32; LIMBS]) {
    let mut rem = [0u32; LIMBS + 1];
    for offset in 0..LIMBS * 32 {
        let bit = LIMBS * 32 - 1 - offset;
        let mut carry = (dividend[bit / 32] >> (bit % 32)) & 1;
        for i in 0..LIMBS {
            let next = rem[i] >> 31;
            rem[i] = (rem[i] << 1) | carry;
            carry = next;
        }
        rem[LIMBS] = carry;
        let mut comparison = if rem[LIMBS] == 0 { 0i8 } else { 1i8 };
        if comparison == 0 {
            for i in (0..LIMBS).rev() {
                if rem[i] > divisor[i] { comparison = 1; break; }
                if rem[i] < divisor[i] { comparison = -1; break; }
            }
        }
        if comparison >= 0 {
            let mut borrow = 0u64;
            for i in 0..LIMBS {
                let sub = divisor[i] as u64 + borrow;
                let old = rem[i] as u64;
                if old >= sub { rem[i] = (old - sub) as u32; borrow = 0; }
                else { rem[i] = (old + 0x1_0000_0000u64 - sub) as u32; borrow = 1; }
            }
            rem[LIMBS] = (rem[LIMBS] as u64 - borrow) as u32;
            quotient[bit / 32] |= 1u32 << (bit % 32);
        }
    }
    remainder.copy_from_slice(&rem[..LIMBS]);
}

#[no_mangle]
pub unsafe extern "C" fn uint128_t(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > 10 || length != 1 + 2 * LIMBS { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] != 0 && values[0] != 1 { return -1; }
    let mut dividend = [0u32; LIMBS];
    let mut divisor = [0u32; LIMBS];
    let mut divisor_nonzero = false;
    for i in 0..LIMBS {
        let a = values[1 + i]; let b = values[1 + LIMBS + i];
        if !(0..=4_294_967_295i64).contains(&a) || !(0..=4_294_967_295i64).contains(&b) { return -1; }
        dividend[i] = a as u32; divisor[i] = b as u32; divisor_nonzero |= divisor[i] != 0;
    }
    if !divisor_nonzero { return -1; }
    if output.is_null() || capacity < 16 { return -2; }
    let mut quotient = [0u32; LIMBS]; let mut remainder = [0u32; LIMBS];
    divide_words(&dividend, &divisor, &mut quotient, &mut remainder);
    let answer = if values[0] == 0 { &quotient } else { &remainder };
    for i in 0..LIMBS { for byte in 0..4 { *output.add(i * 4 + byte) = (answer[i] >> (byte * 8)) as u8; } }
    16
}
