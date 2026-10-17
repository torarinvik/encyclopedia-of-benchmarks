const MD2_S: [u8; 256] = [
    41,46,67,201,162,216,124,1,61,54,84,161,236,240,6,19,98,167,5,243,192,199,115,140,152,147,43,217,188,76,130,202,
    30,155,87,60,253,212,224,22,103,66,111,24,138,23,229,18,190,78,196,214,218,158,222,73,160,251,245,142,187,47,238,122,
    169,104,121,145,21,178,7,63,148,194,16,137,11,34,95,33,128,127,93,154,90,144,50,39,53,62,204,231,191,247,151,3,
    255,25,48,179,72,165,181,209,215,94,146,42,172,86,170,198,79,184,56,210,150,164,125,182,118,252,107,226,156,116,4,241,
    69,157,112,89,100,113,135,32,134,91,207,101,230,45,168,2,27,96,37,173,174,176,185,246,28,70,97,105,52,64,126,15,
    85,71,163,35,221,81,175,58,195,92,249,206,186,197,234,38,44,83,13,110,133,40,132,9,211,223,205,244,65,129,77,82,
    106,220,55,200,108,193,171,250,36,225,123,8,12,189,177,74,120,136,149,139,227,99,232,109,233,203,213,254,59,0,29,57,
    242,239,183,14,102,88,208,228,166,119,114,248,235,117,75,10,49,68,80,180,143,237,31,26,219,153,141,51,159,17,131,20,
];

#[no_mangle]
pub unsafe extern "C" fn md2_digest(input: *const f64, length: usize,
                                      output: *mut f64, output_capacity: usize) -> i64 {
    if length > 63 || (length != 0 && input.is_null()) { return -1; }
    let mut bytes = [0u8; 64];
    for index in 0..length {
        let value = *input.add(index);
        if !value.is_finite() || value < 0.0 || value > 255.0 || value.fract() != 0.0 { return -1; }
        bytes[index] = value as u8;
    }
    if output.is_null() || output_capacity < 16 { return -2; }

    let padding_length = 16 - length % 16;
    let padded_length = length + padding_length;
    for index in length..padded_length { bytes[index] = padding_length as u8; }
    let mut checksum = [0u8; 16];
    let mut last = 0u8;
    for offset in (0..padded_length).step_by(16) {
        for index in 0..16 {
            checksum[index] ^= MD2_S[(bytes[offset + index] ^ last) as usize];
            last = checksum[index];
        }
    }

    let mut state = [0u8; 48];
    for offset in (0..=padded_length).step_by(16) {
        for index in 0..16 {
            let byte = if offset < padded_length { bytes[offset + index] } else { checksum[index] };
            state[index + 16] = byte;
            state[index + 32] = state[index] ^ byte;
        }
        let mut temporary = 0u8;
        for round in 0..18u8 {
            for index in 0..48 {
                state[index] ^= MD2_S[temporary as usize];
                temporary = state[index];
            }
            temporary = temporary.wrapping_add(round);
        }
    }
    for index in 0..16 { *output.add(index) = state[index] as f64; }
    16
}
