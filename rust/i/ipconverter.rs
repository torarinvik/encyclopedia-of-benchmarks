const MAX_PARSEABLE_INPUT_LENGTH: usize = 38;

#[no_mangle]
pub unsafe extern "C" fn ipconverter(input: *const i64, length: usize,
                                      output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let mode = values[0];
    let payload_length_value = values[1];
    if (mode != 0 && mode != 1) || !(0..=35).contains(&payload_length_value) { return -1; }
    let payload_length = payload_length_value as usize;
    if length != payload_length + 2 { return -1; }

    let mut octets = [0i64; 4];
    let mut position = 0usize;
    if mode == 0 {
        if !(7..=15).contains(&payload_length) { return -1; }
        for octet in 0..4 {
            let mut digits = 0usize;
            let mut value = 0i64;
            while position < payload_length && values[2 + position] != 46 {
                let byte = values[2 + position];
                if digits == 3 || !(48..=57).contains(&byte) { return -1; }
                value = value * 10 + byte - 48;
                if value > 255 { return -1; }
                digits += 1;
                position += 1;
            }
            if digits == 0 { return -1; }
            octets[octet] = value;
            if octet < 3 {
                if position >= payload_length || values[2 + position] != 46 { return -1; }
                position += 1;
            } else if position != payload_length { return -1; }
        }
    } else {
        if payload_length != 35 { return -1; }
        for octet in 0..4 {
            let mut value = 0i64;
            for _ in 0..8 {
                let byte = values[2 + position];
                position += 1;
                if byte != 48 && byte != 49 { return -1; }
                value = value * 2 + byte - 48;
            }
            octets[octet] = value;
            if octet < 3 {
                if values[2 + position] != 46 { return -1; }
                position += 1;
            }
        }
        if position != payload_length { return -1; }
    }

    let mut output_length = if mode == 0 { 35 } else { 3 };
    if mode == 1 {
        for value in octets {
            output_length += if value >= 100 { 2 } else if value >= 10 { 1 } else { 0 };
        }
    }
    if capacity < output_length || output.is_null() { return -2; }

    position = 0;
    for octet in 0..4 {
        if mode == 0 {
            for bit in (0..=7).rev() {
                *output.add(position) = (48 + ((octets[octet] >> bit) & 1)) as u8;
                position += 1;
            }
        } else {
            let mut value = octets[octet];
            if value >= 100 { *output.add(position) = (48 + value / 100) as u8; position += 1; value %= 100; }
            if value >= 10 { *output.add(position) = (48 + value / 10) as u8; position += 1; value %= 10; }
            *output.add(position) = (48 + value) as u8;
            position += 1;
        }
        if octet < 3 { *output.add(position) = 46; position += 1; }
    }
    position as i64
}
