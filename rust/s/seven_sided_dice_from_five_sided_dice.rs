const MAX_DRAWS: usize = 256;
const MAX_INPUT_LENGTH: usize = MAX_DRAWS + 2;

fn draw_faces(tape: &[i64], staged: &mut [u8; MAX_DRAWS]) -> Result<usize, ()> {
    if tape.is_empty() || tape.len() > MAX_INPUT_LENGTH {
        return Err(());
    }
    let draw_count = tape[0];
    if draw_count < 0 || draw_count > MAX_DRAWS as i64
        || tape.len() != draw_count as usize + 1
        || tape[1..].iter().any(|&draw| !(0..=4).contains(&draw))
    {
        return Err(());
    }

    let mut written = 0usize;
    let mut value = 0i64;
    let mut range = 1i64;
    for &draw in &tape[1..] {
        value = 5 * value + draw;
        range *= 5;
        while range >= 7 {
            let accepted = range - range % 7;
            if value < accepted {
                staged[written] = (value % 7 + 1) as u8;
                written += 1;
                value /= 7;
                range = accepted / 7;
            } else {
                value -= accepted;
                range -= accepted;
            }
        }
    }
    Ok(written)
}

#[no_mangle]
pub unsafe extern "C" fn seven_sided_dice_from_five_sided_dice(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let tape = unsafe { std::slice::from_raw_parts(input, length) };
    let mut staged = [0u8; MAX_DRAWS];
    let written = match draw_faces(tape, &mut staged) {
        Ok(count) => count,
        Err(()) => return -1,
    };
    if output.is_null() || capacity < written {
        return -2;
    }
    if written != 0 {
        unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, written) };
    }
    written as i64
}
