const MAX_CALL_COUNT: i64 = 1_000_000;
const MODULUS: i64 = 139_968;
const FRACTION_SCALE: i64 = 1_000_000_000;
const MAX_OUTPUT_BYTES: usize = 13;

#[no_mangle]
pub unsafe extern "C" fn shootout_random(
    call_count: i64,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if !(1..=MAX_CALL_COUNT).contains(&call_count) {
        return -1;
    }

    let mut state = 42_i64;
    for _ in 0..call_count {
        state = (state * 3_877 + 29_573) % MODULUS;
    }

    let scaled = (100 * state * FRACTION_SCALE + MODULUS / 2) / MODULUS;
    let mut whole = scaled / FRACTION_SCALE;
    let mut fraction = scaled % FRACTION_SCALE;
    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    let mut reversed_digits = [0_u8; 3];
    let mut digit_count = 0;
    loop {
        reversed_digits[digit_count] = b'0' + (whole % 10) as u8;
        digit_count += 1;
        whole /= 10;
        if whole == 0 { break; }
    }

    let mut used = 0;
    while digit_count > 0 {
        digit_count -= 1;
        staged[used] = reversed_digits[digit_count];
        used += 1;
    }
    staged[used] = b'.';
    used += 1;
    let mut place = 100_000_000_i64;
    while place > 0 {
        staged[used] = b'0' + (fraction / place) as u8;
        used += 1;
        fraction %= place;
        place /= 10;
    }
    staged[used] = b'\n';
    used += 1;

    if output.is_null() || output_capacity < used { return -2; }
    for index in 0..used { *output.add(index) = staged[index]; }
    used as i64
}
