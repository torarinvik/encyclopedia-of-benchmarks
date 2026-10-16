/// Preserve the six integer weight-conversion strings from the pinned Ruby source.
fn append_text(buffer: &mut [u8; 64], mut position: usize, text: &str) -> usize {
    for byte in text.bytes() {
        buffer[position] = byte;
        position += 1;
    }
    position
}

fn append_i64(buffer: &mut [u8; 64], mut position: usize, value: i64) -> usize {
    let mut digits = [0u8; 24];
    let mut count = 0;
    let mut magnitude = value;
    if magnitude < 0 {
        buffer[position] = b'-';
        position += 1;
        magnitude = -magnitude;
    }
    loop {
        digits[count] = b'0' + (magnitude % 10) as u8;
        count += 1;
        magnitude /= 10;
        if magnitude == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        buffer[position] = digits[count];
        position += 1;
    }
    position
}

fn append_fixed(buffer: &mut [u8; 64], mut position: usize, value: f64) -> usize {
    let scaled = value * 100.0;
    let mut cents = if value < 0.0 {
        -((-scaled + 0.5) as i64)
    } else {
        (scaled + 0.5) as i64
    };
    if value > 0.0 && (cents as f64 + 0.5) / 100.0 <= value { cents += 1; }
    else if value < 0.0 && (cents as f64 - 0.5) / 100.0 >= value { cents -= 1; }
    if cents < 0 {
        buffer[position] = b'-';
        position += 1;
        cents = -cents;
    }
    position = append_i64(buffer, position, cents / 100);
    let fraction = cents % 100;
    buffer[position] = b'.';
    position += 1;
    if fraction == 0 {
        buffer[position] = b'0';
        position += 1;
    } else if fraction % 10 == 0 {
        buffer[position] = b'0' + (fraction / 10) as u8;
        position += 1;
    } else {
        buffer[position] = b'0' + (fraction / 10) as u8;
        buffer[position + 1] = b'0' + (fraction % 10) as u8;
        position += 2;
    }
    position
}

#[no_mangle]
pub unsafe extern "C" fn weight_conversions(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let operation = *input;
    let amount = *input.add(1);
    if !(0..=5).contains(&operation) || !(-1_000_000..=1_000_000).contains(&amount) { return -1; }
    let mut buffer = [0u8; 64];
    let mut position = 0;
    let mut converted = 0i64;
    match operation {
        0 => {
            position = append_i64(&mut buffer, position, amount);
            position = append_text(&mut buffer, position, " kg = ");
            position = append_i64(&mut buffer, position, amount * 1000);
            position = append_text(&mut buffer, position, " g");
        }
        1 => {
            converted = if amount >= 0 { amount / 1000 } else { -((-amount + 999) / 1000) };
            position = append_i64(&mut buffer, position, amount);
            position = append_text(&mut buffer, position, " g = ");
            position = append_i64(&mut buffer, position, converted);
            position = append_text(&mut buffer, position, " kg");
        }
        2 => {
            position = append_i64(&mut buffer, position, amount);
            position = append_text(&mut buffer, position, " lb = ");
            position = append_i64(&mut buffer, position, amount * 16);
            position = append_text(&mut buffer, position, " oz");
        }
        3 => {
            converted = if amount >= 0 { amount / 16 } else { -((-amount + 15) / 16) };
            position = append_i64(&mut buffer, position, amount);
            position = append_text(&mut buffer, position, " oz = ");
            position = append_i64(&mut buffer, position, converted);
            position = append_text(&mut buffer, position, " lb");
        }
        4 => {
            position = append_i64(&mut buffer, position, amount);
            position = append_text(&mut buffer, position, " kg = ");
            position = append_fixed(&mut buffer, position, amount as f64 * 2.205);
            position = append_text(&mut buffer, position, " lb");
        }
        5 => {
            position = append_i64(&mut buffer, position, amount);
            position = append_text(&mut buffer, position, " lb = ");
            position = append_fixed(&mut buffer, position, amount as f64 / 2.205);
            position = append_text(&mut buffer, position, " kg");
        }
        _ => return -1,
    }
    buffer[position] = 0;
    if output_capacity < position + 1 || output.is_null() { return -2; }
    for index in 0..=position { *output.add(index) = buffer[index]; }
    position as i64
}
