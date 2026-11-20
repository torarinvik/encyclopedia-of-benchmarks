const MAX_N: usize = 64;
const MAX_INPUT: usize = 66;

#[no_mangle]
pub unsafe extern "C" fn asteroid_collision_stack(
    input_ptr: *const i64,
    length: usize,
    output_ptr: *mut u8,
    capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length == 0 || length > MAX_INPUT {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input_ptr, length) };
    let n_word = input[0];
    if n_word < 0 || n_word > MAX_N as i64 || length != n_word as usize + 1 {
        return -1;
    }

    let mut stack = [0i8; MAX_N];
    let mut top = 0usize;
    for &word in &input[1..] {
        if word == 0 || !(-127..=127).contains(&word) {
            return -1;
        }
        let incoming = word as i8;
        let mut alive = true;
        while alive && top > 0 && stack[top - 1] > 0 && incoming < 0 {
            let left_size = stack[top - 1] as i16;
            let right_size = -(incoming as i16);
            if left_size < right_size {
                top -= 1;
            } else if left_size == right_size {
                top -= 1;
                alive = false;
            } else {
                alive = false;
            }
        }
        if alive {
            stack[top] = incoming;
            top += 1;
        }
    }

    let required = top + 1;
    if output_ptr.is_null() || capacity < required {
        return -2;
    }
    let output = unsafe { std::slice::from_raw_parts_mut(output_ptr, required) };
    output[0] = top as u8;
    for i in 0..top {
        output[i + 1] = stack[i] as u8;
    }
    required as i64
}
