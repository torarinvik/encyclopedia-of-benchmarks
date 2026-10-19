const MAX_N: i64 = 10;
const MAX_OUTPUT_BYTES: usize = 89;

fn ackermann_value(x: i64, y: i64) -> i64 {
    if x == 0 { return y + 1; }
    ackermann_value(x - 1, if y == 0 { 1 } else { ackermann_value(x, y - 1) })
}

fn fibonacci_integer(n: i64) -> i64 {
    if n < 2 { return 1; }
    fibonacci_integer(n - 2) + fibonacci_integer(n - 1)
}

fn fibonacci_float(n: f64) -> f64 {
    if n < 2.0 { return 1.0; }
    fibonacci_float(n - 2.0) + fibonacci_float(n - 1.0)
}

fn takeuchi_integer(x: i64, y: i64, z: i64) -> i64 {
    if y < x {
        return takeuchi_integer(
            takeuchi_integer(x - 1, y, z),
            takeuchi_integer(y - 1, z, x),
            takeuchi_integer(z - 1, x, y),
        );
    }
    z
}

fn takeuchi_float(x: f64, y: f64, z: f64) -> f64 {
    if y < x {
        return takeuchi_float(
            takeuchi_float(x - 1.0, y, z),
            takeuchi_float(y - 1.0, z, x),
            takeuchi_float(z - 1.0, x, y),
        );
    }
    z
}

fn append_text(buffer: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize, text: &str) {
    for byte in text.bytes() {
        buffer[*used] = byte;
        *used += 1;
    }
}

fn append_number(buffer: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize, value: i64) {
    let mut reversed = [0_u8; 20];
    let mut remaining = value;
    let mut count = 0;
    loop {
        reversed[count] = b'0' + (remaining % 10) as u8;
        count += 1;
        remaining /= 10;
        if remaining == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        buffer[*used] = reversed[count];
        *used += 1;
    }
}

#[no_mangle]
pub unsafe extern "C" fn benchmarkgame_recursive(n: i64, output: *mut u8,
    output_capacity: usize) -> i64 {
    if n < 0 || n > MAX_N { return -1; }
    if output.is_null() { return -2; }

    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    let mut used = 0;
    append_text(&mut staged, &mut used, "Ack(3,");
    append_number(&mut staged, &mut used, n + 1);
    append_text(&mut staged, &mut used, "): ");
    append_number(&mut staged, &mut used, ackermann_value(3, n + 1));
    append_text(&mut staged, &mut used, "\nFib(");
    append_number(&mut staged, &mut used, 28 + n);
    append_text(&mut staged, &mut used, ".0): ");
    append_number(&mut staged, &mut used, fibonacci_float((28 + n) as f64) as i64);
    append_text(&mut staged, &mut used, ".0\nTak(");
    append_number(&mut staged, &mut used, 3 * n);
    append_text(&mut staged, &mut used, ",");
    append_number(&mut staged, &mut used, 2 * n);
    append_text(&mut staged, &mut used, ",");
    append_number(&mut staged, &mut used, n);
    append_text(&mut staged, &mut used, "): ");
    append_number(&mut staged, &mut used, takeuchi_integer(3 * n, 2 * n, n));
    append_text(&mut staged, &mut used, "\nFib(3): ");
    append_number(&mut staged, &mut used, fibonacci_integer(3));
    append_text(&mut staged, &mut used, "\nTak(3.0,2.0,1.0): ");
    append_number(&mut staged, &mut used, takeuchi_float(3.0, 2.0, 1.0) as i64);
    append_text(&mut staged, &mut used, ".0\n");

    if output_capacity < used { return -2; }
    for index in 0..used { *output.add(index) = staged[index]; }
    used as i64
}
