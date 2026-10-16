#[no_mangle]
pub unsafe extern "C" fn crc_polynomial_division(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 3 + 79 + 16 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (operation, raw_message_length, raw_polynomial_length) = (values[0], values[1], values[2]);
    if !(0..=1).contains(&operation) || raw_message_length < 1
        || (operation == 0 && raw_message_length > 64) || (operation == 1 && raw_message_length > 79)
        || !(2..=16).contains(&raw_polynomial_length) { return -1; }
    let message_length = raw_message_length as usize;
    let polynomial_length = raw_polynomial_length as usize;
    if length != 3 + message_length + polynomial_length { return -1; }

    let mut message = [0u8; 79];
    let mut polynomial = [0u8; 16];
    let mut dividend = [0u8; 79];
    let mut remainder = [0u8; 16];
    for i in 0..message_length {
        if !(0..=1).contains(&values[3 + i]) { return -1; }
        message[i] = values[3 + i] as u8;
    }
    for i in 0..polynomial_length {
        let bit = values[3 + message_length + i];
        if !(0..=1).contains(&bit) { return -1; }
        polynomial[i] = bit as u8;
    }
    if polynomial[0] != 1 || polynomial[polynomial_length - 1] != 1 { return -1; }

    let mut dividend_length = message_length;
    dividend[..message_length].copy_from_slice(&message[..message_length]);
    if operation == 0 {
        for slot in 0..(polynomial_length - 1) { dividend[dividend_length + slot] = 0; }
        dividend_length += polynomial_length - 1;
    }
    let (mut remainder_length, mut cursor) = (0usize, 0usize);
    while cursor < dividend_length {
        while remainder_length < polynomial_length && cursor < dividend_length {
            remainder[remainder_length] = dividend[cursor];
            remainder_length += 1;
            cursor += 1;
        }
        if remainder_length == polynomial_length {
            if remainder[0] == 1 {
                for i in 0..polynomial_length { remainder[i] ^= polynomial[i]; }
            }
            let mut leading_zeroes = 0;
            while leading_zeroes < remainder_length && remainder[leading_zeroes] == 0 { leading_zeroes += 1; }
            for i in leading_zeroes..remainder_length { remainder[i - leading_zeroes] = remainder[i]; }
            remainder_length -= leading_zeroes;
        }
    }

    let degree = polynomial_length - 1;
    let output_length = if operation == 0 { message_length + degree } else { 1 };
    if output.is_null() || capacity < output_length { return -2; }
    let result = std::slice::from_raw_parts_mut(output, output_length);
    if operation == 0 {
        result[..message_length].copy_from_slice(&message[..message_length]);
        let leading_zeroes = degree - remainder_length;
        result[message_length..message_length + leading_zeroes].fill(0);
        result[message_length + leading_zeroes..].copy_from_slice(&remainder[..remainder_length]);
    } else {
        result[0] = remainder[..remainder_length].iter().any(|&bit| bit != 0) as u8;
    }
    output_length as i64
}
