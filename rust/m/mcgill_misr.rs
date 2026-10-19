const MIN_EXPERIMENTS: i64 = 1;
const MAX_EXPERIMENTS: i64 = 1_000;
const MAX_OUTPUT_BYTES: usize = 123;
const MASK_48: u64 = 0xFFFFFFFFFFFF;
const MASK_24: u64 = 0xFFFFFF;

fn next_lrand48(state: &mut u64) -> u32 {
    let low = *state & MASK_24;
    let high = *state >> 24;
    let high_product = (high * 0xECE66D) & MASK_24;
    *state = (low * 0x5DEECE66D + (high_product << 24) + 0xB) & MASK_48;
    (*state >> 17) as u32
}

fn different_experiment(random_state: &mut u64, free_state: &mut [u8; 10]) -> bool {
    let mut faulty_state = *free_state;
    for _ in 0..10 {
        let saved_free = free_state[0];
        let saved_faulty = faulty_state[0];
        let mut random_word = next_lrand48(random_state);
        for cell in 0..9 {
            free_state[cell] = (u32::from(free_state[cell + 1]) + random_word & 1) as u8;
            let random_probability = next_lrand48(random_state);
            if random_probability % 1000 < 250 { random_word ^= 1; }
            faulty_state[cell] = (u32::from(faulty_state[cell + 1]) + random_word & 1) as u8;
            random_word >>= 1;
        }
        random_word = next_lrand48(random_state);
        free_state[9] = (u32::from(saved_free) + random_word & 1) as u8;
        let random_probability = next_lrand48(random_state);
        if random_probability % 10_000 < 2_500 { random_word ^= 1; }
        faulty_state[9] = (u32::from(saved_faulty) + random_word & 1) as u8;
    }
    *free_state != faulty_state
}

fn append_text(buffer: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize, text: &[u8]) {
    for byte in text { buffer[*used] = *byte; *used += 1; }
}

fn append_unsigned(buffer: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize, value: u64) {
    let mut remaining = value;
    let mut reverse = [0_u8; 24];
    let mut count = 0;
    loop {
        reverse[count] = b'0' + (remaining % 10) as u8;
        count += 1;
        remaining /= 10;
        if remaining == 0 { break; }
    }
    while count > 0 { count -= 1; buffer[*used] = reverse[count]; *used += 1; }
}

fn append_probability(buffer: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize,
                      same_count: u64, experiments: u64) {
    let mut mantissa = 0_u64;
    let mut exponent = 0_i32;
    if same_count != 0 {
        let mut scale = 1_u64;
        while same_count * scale < experiments { scale *= 10; exponent -= 1; }
        let numerator = same_count * scale * 100_000_000;
        mantissa = numerator / experiments;
        let remainder = numerator % experiments;
        if 2 * remainder > experiments || (2 * remainder == experiments && mantissa & 1 != 0) {
            mantissa += 1;
        }
        if mantissa == 1_000_000_000 { mantissa = 100_000_000; exponent += 1; }
    }
    let whole = mantissa / 100_000_000;
    let mut fraction = mantissa % 100_000_000;
    buffer[*used] = b'0' + whole as u8; *used += 1;
    buffer[*used] = b'.'; *used += 1;
    let mut place = 10_000_000_u64;
    for _ in 0..8 {
        buffer[*used] = b'0' + (fraction / place) as u8; *used += 1;
        fraction %= place;
        place /= 10;
    }
    buffer[*used] = b'e'; *used += 1;
    let absolute_exponent = exponent.unsigned_abs();
    buffer[*used] = if exponent < 0 { b'-' } else { b'+' }; *used += 1;
    buffer[*used] = b'0' + (absolute_exponent / 10) as u8; *used += 1;
    buffer[*used] = b'0' + (absolute_exponent % 10) as u8; *used += 1;
}

#[no_mangle]
pub unsafe extern "C" fn mcgill_misr(
    experiments: i64,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if !(MIN_EXPERIMENTS..=MAX_EXPERIMENTS).contains(&experiments) { return -1; }
    if output.is_null() { return -2; }

    let mut random_state = 1_u64;
    let mut free_state = [0, 1, 1, 1, 1, 1, 1, 1, 1, 1];
    let mut different_count = 0_u64;
    for _ in 0..experiments {
        if different_experiment(&mut random_state, &mut free_state) { different_count += 1; }
    }

    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    let mut used = 0;
    append_text(&mut staged, &mut used,
        b"reg_len #_vect prob #_tms struct seed1 seed2 seed3 Prob same output\n ");
    append_text(&mut staged, &mut used, b"10 10 2.500e-01 ");
    append_unsigned(&mut staged, &mut used, experiments as u64);
    append_text(&mut staged, &mut used, b" 1000000000 1 0 0 ");
    append_probability(&mut staged, &mut used, experiments as u64 - different_count,
                       experiments as u64);
    staged[used] = b'\n'; used += 1;

    if output_capacity < used { return -2; }
    for index in 0..used { *output.add(index) = staged[index]; }
    used as i64
}
