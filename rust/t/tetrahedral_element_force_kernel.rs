const MAX_ELEMENTS: usize = 32;
const MAX_VALID_INPUT: usize = 3 + 12 * MAX_ELEMENTS;
const MAX_INPUT: usize = MAX_VALID_INPUT + 1;
const MAX_OUTPUT: usize = 3072;

fn store_i64_le(output: &mut [u8; MAX_OUTPUT], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        output[offset + byte] = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn tetrahedral_element_force_kernel(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT {
        return -1;
    }
    let m_value = *input;
    let lambda = *input.add(1);
    let mu = *input.add(2);
    if !(1..=MAX_ELEMENTS as i64).contains(&m_value)
        || !(0..=16).contains(&lambda)
        || !(0..=16).contains(&mu)
    {
        return -1;
    }
    let m = m_value as usize;
    if length != 3 + 12 * m {
        return -1;
    }
    for index in 3..length {
        let coordinate = *input.add(index);
        if !(-4..=4).contains(&coordinate) {
            return -1;
        }
    }

    let required = 96 * m;
    if output.is_null() || capacity < required {
        return -2;
    }
    let mut staged = [0u8; MAX_OUTPUT];
    for element in 0..m {
        let base = 3 + 12 * element;
        let mut deformation = [[0i64; 3]; 3];
        for row in 0..3 {
            for column in 0..3 {
                deformation[row][column] =
                    *input.add(base + 3 * (column + 1) + row) - *input.add(base + row);
            }
        }
        let trace_delta = deformation[0][0] + deformation[1][1] + deformation[2][2] - 3;
        let mut stress = [[0i64; 3]; 3];
        for row in 0..3 {
            for column in 0..3 {
                let diagonal = if row == column { 1 } else { 0 };
                stress[row][column] = lambda * trace_delta * diagonal
                    + mu * (deformation[row][column] + deformation[column][row] - 2 * diagonal);
            }
        }
        for axis in 0..3 {
            let vertex_zero = stress[axis][0] + stress[axis][1] + stress[axis][2];
            store_i64_le(&mut staged, 8 * (12 * element + axis), vertex_zero);
            for vertex in 1..4 {
                store_i64_le(
                    &mut staged,
                    8 * (12 * element + 3 * vertex + axis),
                    -stress[axis][vertex - 1],
                );
            }
        }
    }
    for byte in 0..required {
        *output.add(byte) = staged[byte];
    }
    required as i64
}
