const MAX_TASK_COUNT: usize = 32;
const MAX_INPUT_LENGTH: usize = 35;
const MAX_OUTPUT_BYTES: usize = 256;
const JAVA_MULTIPLIER: u64 = 0x5DEECE66D;
const JAVA_ADDEND: u64 = 0xB;
const JAVA_MASK: u64 = 0xFFFFFFFFFFFF;

struct JavaRandom { state: u64 }

impl JavaRandom {
    fn next_bits(&mut self, bits: u32) -> u32 {
        self.state = self.state.wrapping_mul(JAVA_MULTIPLIER).wrapping_add(JAVA_ADDEND) & JAVA_MASK;
        (self.state >> (48 - bits)) as u32
    }

    fn next_int(&mut self, bound: u32) -> u32 {
        if bound & (bound - 1) == 0 {
            return ((bound as u64 * self.next_bits(31) as u64) >> 31) as u32;
        }
        loop {
            let bits = self.next_bits(31);
            let value = bits % bound;
            if bits as u64 - value as u64 + (bound - 1) as u64 <= i32::MAX as u64 {
                return value;
            }
        }
    }
}

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn random_scheduling(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if values[1] < 0 || values[1] > MAX_TASK_COUNT as i64 { return -1; }
    let count = values[1] as usize;
    if input_length != count + 2 { return -1; }

    let mut tasks = [0_i64; MAX_TASK_COUNT];
    for index in 0..count {
        let task = values[index + 2];
        if task < i32::MIN as i64 || task > i32::MAX as i64 { return -1; }
        tasks[index] = task;
    }
    let mut random = JavaRandom { state: ((values[0] as u64) ^ JAVA_MULTIPLIER) & JAVA_MASK };
    for size in (2..=count).rev() {
        let selected = random.next_int(size as u32) as usize;
        tasks.swap(size - 1, selected);
    }

    let output_bytes = count * 8;
    if output_bytes > MAX_OUTPUT_BYTES { return -1; }
    if output.is_null() || capacity < output_bytes { return -2; }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    for index in 0..count { write_i64_le(output_slice, index * 8, tasks[index]); }
    output_bytes as i64
}
