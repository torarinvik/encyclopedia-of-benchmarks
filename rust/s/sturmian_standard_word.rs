const MAX_STEPS: usize = 4;
const MAX_WORD: usize = 41;

fn read_directives(input: *const i64, length: usize) -> Option<([i64; MAX_STEPS], usize)> {
    if input.is_null() || !(1..=6).contains(&length) { return None; }
    let steps_word = unsafe { *input };
    if !(0..=MAX_STEPS as i64).contains(&steps_word) { return None; }
    let steps = steps_word as usize;
    if length != steps + 1 { return None; }
    let mut directives = [0i64; MAX_STEPS];
    for i in 0..steps {
        let repeat = unsafe { *input.add(i + 1) };
        if (i == 0 && !(0..=2).contains(&repeat)) || (i != 0 && !(1..=2).contains(&repeat)) {
            return None;
        }
        directives[i] = repeat;
    }
    Some((directives, steps))
}

#[no_mangle]
pub unsafe extern "C" fn sturmian_standard_word(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    let Some((directives, steps)) = read_directives(input, length) else { return -1; };

    let mut first = [0u8; MAX_WORD];
    let mut second = [0u8; MAX_WORD];
    let mut third = [0u8; MAX_WORD];
    let (mut previous, mut current, mut following) = (&mut first, &mut second, &mut third);
    let (mut previous_length, mut current_length) = (1usize, 1usize);
    previous[0] = b'b';
    current[0] = b'a';
    for step in 0..steps {
        let repeat = directives[step] as usize;
        let following_length = current_length * repeat + previous_length;
        let mut position = 0;
        for _ in 0..repeat {
            for i in 0..current_length {
                following[position] = current[i];
                position += 1;
            }
        }
        for i in 0..previous_length {
            following[position] = previous[i];
            position += 1;
        }
        previous[..current_length].copy_from_slice(&current[..current_length]);
        current[..following_length].copy_from_slice(&following[..following_length]);
        previous_length = current_length;
        current_length = following_length;
    }

    if output.is_null() || capacity < current_length { return -2; }
    std::ptr::copy_nonoverlapping(current.as_ptr(), output, current_length);
    current_length as i64
}
