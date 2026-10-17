/// Multiply two canonical nonnegative ASCII decimal integers by long multiplication.
#[no_mangle]
pub unsafe extern "C" fn big_integer_multiply(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > 66 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let left_length = values[0];
    let right_length = values[1];
    if !(1..=32).contains(&left_length) || !(1..=32).contains(&right_length) {
        return -1;
    }
    let left_length = left_length as usize;
    let right_length = right_length as usize;
    if length != 2 + left_length + right_length {
        return -1;
    }

    let left = &values[2..2 + left_length];
    let right = &values[2 + left_length..];
    let valid_operand = |digits: &[i64]| {
        digits.iter().all(|&digit| (48..=57).contains(&digit))
            && (digits.len() == 1 || digits[0] != 48)
    };
    if !valid_operand(left) || !valid_operand(right) {
        return -1;
    }

    let mut product = [0u16; 64];
    let product_size = left_length + right_length;
    let is_zero = (left.len() == 1 && left[0] == 48) || (right.len() == 1 && right[0] == 48);
    if !is_zero {
        for i in 0..left_length {
            for j in 0..right_length {
                let position = i + j;
                let left_digit = left[left_length - i - 1];
                let right_digit = right[right_length - j - 1];
                let multiplication = ((left_digit - 48) * (right_digit - 48)) as u16;
                product[position + 1] += (product[position] + multiplication) / 10;
                product[position] = (product[position] + multiplication) % 10;
            }
        }
    }

    let effective_size = if is_zero {
        1
    } else if product[product_size - 1] == 0 {
        product_size - 1
    } else {
        product_size
    };
    let output_length = effective_size;
    if output.is_null() || output_capacity < output_length {
        return -2;
    }
    for index in 0..output_length {
        *output.add(index) = if is_zero {
            b'0'
        } else {
            b'0' + product[effective_size - index - 1] as u8
        };
    }
    output_length as i64
}
