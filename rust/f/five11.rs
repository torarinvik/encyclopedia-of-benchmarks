const MAX_INPUT: usize = 13_523;
const MAX_PARSEABLE_INPUT: usize = 13_524;
const MAX_PACKETS: i64 = 451;

fn read_bits(values: &[i64], bit_offset: usize, width: usize) -> Option<i64> {
    let bit_length = values.len() * 8;
    if bit_offset > bit_length || width > bit_length - bit_offset { return None; }
    let byte_offset = bit_offset >> 3;
    let start = bit_offset & 7;
    let byte_count = (start + width + 7) >> 3;
    let mut window = 0u32;
    for index in 0..byte_count {
        window = (window << 8) | values[byte_offset + index] as u32;
    }
    let shift = byte_count * 8 - start - width;
    let mask = (1u32 << width) - 1;
    Some(((window >> shift) & mask) as i64)
}

fn decode_sum(values: &[i64]) -> Option<i64> {
    let packet_count = read_bits(values, 0, 16)?;
    if packet_count > MAX_PACKETS { return None; }
    let mut bit_offset = 16usize;
    let mut total = 0i64;
    for _ in 0..packet_count {
        let channels = read_bits(values, bit_offset, 5)?;
        bit_offset += 5;
        for _ in 0..channels {
            total += read_bits(values, bit_offset, 11)?;
            bit_offset += 11;
        }
        let packet_bits = 5 + 11 * channels as usize;
        bit_offset += (8 - (packet_bits & 7)) & 7;
        if bit_offset > values.len() * 8 { return None; }
    }
    Some(total)
}

#[no_mangle]
pub unsafe extern "C" fn five11(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT || length > MAX_INPUT {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input.iter().any(|value| !(0..=255).contains(value)) { return -1; }
    let mut result = 0i64;
    for _ in 0..10_000 {
        result = match decode_sum(input) {
            Some(value) => value,
            None => return -1,
        };
    }
    result
}
