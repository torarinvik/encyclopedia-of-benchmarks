/* Modified bounded-profile derivative; carry benchmarks/b/bmm/LICENSE with this source. */

const MAX_SIZE: usize = 128;
const SOURCE_SIZE: usize = 1024;
const MAX_CELLS: usize = MAX_SIZE * MAX_SIZE;
const MAX_OUTPUT_BYTES: usize = 29;

fn next_random(state: &mut u32) -> u32 {
    *state = state.wrapping_mul(1_664_525).wrapping_add(1_013_904_223);
    (*state >> 16) & 0x7fff
}

fn append_unsigned(mut value: u32, staged: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize) {
    let mut reverse = [0u8; 10];
    let mut count = 0;
    loop {
        reverse[count] = b'0' + (value % 10) as u8;
        count += 1;
        value /= 10;
        if value == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        staged[*used] = reverse[count];
        *used += 1;
    }
}

#[no_mangle]
pub unsafe extern "C" fn versabench_bmm(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let (size_value, block_value) = (*input, *input.add(1));
    if size_value < 1 || size_value > MAX_SIZE as i64 || block_value < 1 ||
        block_value > size_value || size_value % block_value != 0 { return -1; }
    let size = size_value as usize;
    let block = block_value as usize;

    let mut a = [0.0f32; MAX_CELLS];
    let mut b = [0.0f32; MAX_CELLS];
    let mut c = [0.0f32; MAX_CELLS];
    let mut seed = 1u32;
    for i in 0..size {
        for j in 0..SOURCE_SIZE {
            let random_a = next_random(&mut seed);
            let random_b = next_random(&mut seed);
            if j < size {
                let shift_a = ((j & 31) + 32 - (i & 31)) & 31;
                let shift_b = (i + j) & 31;
                a[i * size + j] = ((random_a >> shift_a) & 15) as f32;
                b[i * size + j] = (random_b.wrapping_shl(shift_b as u32) & 15) as f32;
            }
        }
    }

    for outer_i in (0..size).step_by(block) {
        for outer_j in (0..size).step_by(block) {
            for outer_k in (0..size).step_by(block) {
                for i in outer_i..outer_i + block {
                    for j in outer_j..outer_j + block {
                        let cell = i * size + j;
                        for k in outer_k..outer_k + block {
                            c[cell] += a[i * size + k] * b[k * size + j];
                        }
                    }
                }
            }
        }
    }

    let mut total = 0.0f32;
    for outer_i in (0..size).step_by(block) {
        for outer_j in (0..size).step_by(block) {
            let mut subtotal = 0.0f32;
            for i in outer_i..outer_i + block {
                for j in outer_j..outer_j + block {
                    subtotal += c[i * size + j];
                }
            }
            total += subtotal;
        }
    }

    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    let mut used = 0;
    staged[..12].copy_from_slice(b"final sum = ");
    used = 12;
    append_unsigned(total as u32, &mut staged, &mut used);
    staged[used..used + 8].copy_from_slice(b".000000\n");
    used += 8;
    if output.is_null() || output_capacity < used { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, used);
    used as i64
}
