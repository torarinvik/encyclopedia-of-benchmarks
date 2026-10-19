const MAX_WORDS: usize = 160;
const MAX_OUTPUT_BYTES: usize = 18;
const RAW5: [u16; 32] = [
    0x0d80, 0x05a2, 0x0c60, 0x0cc0, 0x0ca0, 0x10a2, 0x10c2, 0x10e0,
    0x0d20, 0x1122, 0x1142, 0x1160, 0x1182, 0x11a0, 0x11c0, 0x05e0,
    0x0e20, 0x1222, 0x1242, 0x1260, 0x1282, 0x12a0, 0x12c0, 0x06e0,
    0x1302, 0x1320, 0x1340, 0x0760, 0x0380, 0x07a0, 0x0e80, 0x06a2,
];
const RAW3: [u16; 8] = [0x0c08, 0x0c04, 0x1009, 0x100c, 0x1011, 0x1014, 0x0018, 0x041c];

fn encode_one(packed_word: u32, disparity: &mut u32) -> u32 {
    let data = packed_word & 0xff;
    let k = packed_word >> 8;
    let index5 = (data >> 3) as usize;
    let index3 = (data & 7) as usize;
    let mut lookup5 = RAW5[index5] as u32;
    let mut lookup3 = RAW3[index3] as u32;
    if k == 1 && index5 == 7 { lookup5 = 0x04e2; }
    if k == 1 {
        if (2..=5).contains(&index3) {
            lookup3 = (lookup3 & !0x1000) | 0x0800;
        } else if index3 == 7 {
            lookup3 = 0x040d;
        }
    }

    let (mut result, disparity1) = if lookup5 & 0x1000 != 0 {
        (lookup5 & 0x03e2, *disparity)
    } else {
        let code5 = lookup5 & 0x03e2;
        let plus5: u32 = if lookup5 & 0x0800 != 0 { 1 } else { 0 };
        let result = if *disparity == plus5 { code5 } else { code5 ^ 0x03e2 };
        let flip5: u32 = if lookup5 & 0x0400 != 0 { 1 } else { 0 };
        (result, *disparity ^ flip5)
    };

    if lookup3 & 0x1000 != 0 {
        result |= lookup3 & 0x001d;
        *disparity = disparity1;
    } else {
        let code3 = lookup3 & 0x001d;
        let plus3: u32 = if lookup3 & 0x0800 != 0 { 1 } else { 0 };
        result |= if disparity1 == plus3 { code3 } else { code3 ^ 0x001d };
        let flip3: u32 = if lookup3 & 0x0400 != 0 { 1 } else { 0 };
        *disparity = disparity1 ^ flip3;
    }
    result
}

fn append_line(value: u32, staged: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize) {
    const HEX: &[u8; 16] = b"0123456789ABCDEF";
    for digit in 0..8 {
        let shift = (7 - digit) * 4;
        staged[*used] = HEX[((value >> shift) & 15) as usize];
        *used += 1;
    }
    staged[*used] = b'\n';
    *used += 1;
}

#[no_mangle]
pub unsafe extern "C" fn versabench_8b10b(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if length > MAX_WORDS || (length != 0 && values.is_null()) { return -1; }
    for index in 0..length {
        let value = *values.add(index);
        if !(0..=511).contains(&value) { return -1; }
    }

    let sample_count = if length == 0 { 0 } else { 1 + (length - 1) / 128 };
    let required = sample_count * 9;
    if required != 0 && (output.is_null() || output_capacity < required) { return -2; }

    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    let mut used = 0;
    let mut disparity = 0u32;
    for pass in 0..length {
        for index in 0..length {
            let encoded = encode_one(*values.add(index) as u32, &mut disparity);
            if pass + 1 == length && index % 128 == 0 {
                append_line(encoded, &mut staged, &mut used);
            }
        }
    }
    if required != 0 { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, required); }
    used as i64
}
