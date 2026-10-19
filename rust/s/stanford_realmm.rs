/// Source-ordered double-precision matrix multiplication from Stanford RealMM.
const ROWSIZE: usize = 40;
const CELL_COUNT: usize = ROWSIZE * ROWSIZE;
const MAX_PASSES: i64 = 10;
const MAX_OUTPUT_BYTES: usize = 140;

fn rounded_micro_units(bits: u64) -> u64 {
    let exponent = (bits >> 52) & 0x7ff;
    let mut significand = bits & ((1_u64 << 52) - 1);
    if exponent == 0 { return 0; }
    significand |= 1_u64 << 52;
    let shift = 1075 - exponent;
    if shift >= 74 { return 0; }
    let low_product = (significand & 0xffff_ffff) * 1_000_000;
    let high_product = (significand >> 32) * 1_000_000;
    let middle = (low_product >> 32) + (high_product & 0xffff_ffff);
    let limb0 = low_product & 0xffff_ffff;
    let limb1 = middle & 0xffff_ffff;
    let limb2 = (high_product >> 32) + (middle >> 32);
    let (quotient, half_bit, lower_nonzero) = if shift < 64 {
        let part = shift - 32;
        ((limb1 >> part) | (limb2 << (32 - part)), (limb1 >> (part - 1)) & 1,
         limb0 != 0 || (limb1 & ((1_u64 << (part - 1)) - 1)) != 0)
    } else if shift == 64 {
        (limb2, limb1 >> 31, limb0 != 0 || (limb1 & 0x7fff_ffff) != 0)
    } else {
        let part = shift - 64;
        (limb2 >> part, (limb2 >> (part - 1)) & 1,
         limb0 != 0 || limb1 != 0 || (limb2 & ((1_u64 << (part - 1)) - 1)) != 0)
    };
    quotient + if half_bit != 0 && (lower_nonzero || quotient & 1 != 0) { 1 } else { 0 }
}

fn append_integer(mut value: u64, buffer: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize) {
    let mut reversed = [0_u8; 20];
    let mut count = 0;
    loop {
        reversed[count] = b'0' + (value % 10) as u8;
        count += 1;
        value /= 10;
        if value == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        buffer[*used] = reversed[count];
        *used += 1;
    }
}

fn append_fixed(value: f64, buffer: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize) {
    let bits = value.to_bits();
    if bits >> 63 != 0 {
        buffer[*used] = b'-';
        *used += 1;
    }
    let scaled = rounded_micro_units(bits & 0x7fff_ffff_ffff_ffff);
    append_integer(scaled / 1_000_000, buffer, used);
    buffer[*used] = b'.';
    *used += 1;
    let mut fraction = scaled % 1_000_000;
    let mut place = 100_000;
    while place > 0 {
        buffer[*used] = b'0' + (fraction / place) as u8;
        *used += 1;
        fraction %= place;
        place /= 10;
    }
}

#[no_mangle]
pub unsafe extern "C" fn stanford_realmm(pass_count: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(1..=MAX_PASSES).contains(&pass_count) { return -1; }
    if output.is_null() { return -2; }

    let mut a = [0.0_f64; CELL_COUNT];
    let mut b = [0.0_f64; CELL_COUNT];
    let mut product = [0.0_f64; CELL_COUNT];
    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    let mut used = 0;
    for pass in 0..pass_count as usize {
        let mut seed = 74755_i64;
        for index in 0..CELL_COUNT {
            seed = (seed * 1309 + 13849) & 65535;
            let temp = seed;
            let residue = temp - (temp / 120) * 120 - 60;
            a[index] = residue as f64 / 3.0;
        }
        for index in 0..CELL_COUNT {
            seed = (seed * 1309 + 13849) & 65535;
            let temp = seed;
            let residue = temp - (temp / 120) * 120 - 60;
            b[index] = residue as f64 / 3.0;
        }

        for row in 0..ROWSIZE {
            for column in 0..ROWSIZE {
                let mut sum = 0.0_f64;
                for inner in 0..ROWSIZE {
                    sum = sum + a[row * ROWSIZE + inner] * b[inner * ROWSIZE + column];
                }
                product[row * ROWSIZE + column] = sum;
            }
        }
        append_fixed(product[pass * ROWSIZE + pass], &mut staged, &mut used);
        staged[used] = b'\n';
        used += 1;
    }

    if output_capacity < used { return -2; }
    for index in 0..used { unsafe { *output.add(index) = staged[index]; } }
    used as i64
}
