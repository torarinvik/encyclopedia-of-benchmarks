const MIN_PASSES: i64 = 0;
const MAX_PASSES: i64 = 1_000;
const BUFFER_SIZE: usize = 2_048;
const OUTPUT_CAPACITY: usize = 14;

#[inline(never)]
fn execute(sum: &mut u32, opcode: i32) { *sum = sum.wrapping_add(opcode as u32); }

fn eval(commands: &[i32; BUFFER_SIZE], sum: &mut u32) {
    let mut pc = 0;
    let mut opcode = commands[pc];
    pc += 1;
    while opcode != 0 {
        match opcode {
            1..=31 => execute(sum, opcode),
            _ => return,
        }
        opcode = commands[pc];
        pc += 1;
    }
}

fn format_output(mut sum: u32, staged: &mut [u8; OUTPUT_CAPACITY]) -> usize {
    staged[..5].copy_from_slice(b"Sum: ");
    let mut used = 5;
    let mut reversed = [0_u8; 10];
    let mut digits = 0;
    loop {
        reversed[digits] = b'0' + (sum % 10) as u8;
        digits += 1;
        sum /= 10;
        if sum == 0 { break; }
    }
    while digits > 0 {
        digits -= 1;
        staged[used] = reversed[digits];
        used += 1;
    }
    staged[used] = b'\n';
    used + 1
}

#[no_mangle]
pub unsafe extern "C" fn evalloop(passes: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(MIN_PASSES..=MAX_PASSES).contains(&passes) { return -1; }
    if output.is_null() { return -2; }

    let mut commands = [0_i32; BUFFER_SIZE];
    for index in 0..BUFFER_SIZE - 1 { commands[index] = (index % 31 + 1) as i32; }
    let mut sum = 0_u32;
    for _ in 0..passes { eval(&commands, &mut sum); }

    let mut staged = [0_u8; OUTPUT_CAPACITY];
    let used = format_output(sum, &mut staged);
    if output_capacity < used { return -2; }
    for index in 0..used { *output.add(index) = staged[index]; }
    used as i64
}
