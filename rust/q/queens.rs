const MAX_N: usize = 14;
const MAX_DIAGS: usize = 2 * MAX_N - 1;
const EMPTY_OWNER: i32 = 101;
const MAX_OUTPUT_BYTES: usize = 80;

struct QueensState {
    n: usize,
    queen: [usize; MAX_N],
    file: [i32; MAX_N],
    forward_diag: [i32; MAX_DIAGS],
    backward_diag: [i32; MAX_DIAGS],
    solutions: u64,
}

fn find_solutions(state: &mut QueensState, level: usize) {
    if level == state.n {
        state.solutions += 1;
        return;
    }
    for file_index in 0..state.n {
        let forward = file_index + level;
        let backward = level - file_index + state.n - 1;
        if state.file[file_index] >= level as i32
            && state.forward_diag[forward] >= level as i32
            && state.backward_diag[backward] >= level as i32
        {
            state.queen[level] = file_index;
            state.file[file_index] = level as i32;
            state.forward_diag[forward] = level as i32;
            state.backward_diag[backward] = level as i32;
            find_solutions(state, level + 1);
            state.file[file_index] = EMPTY_OWNER;
            state.forward_diag[forward] = EMPTY_OWNER;
            state.backward_diag[backward] = EMPTY_OWNER;
        }
    }
}

fn append_text(output: &mut [u8; MAX_OUTPUT_BYTES], position: &mut usize, text: &str) {
    for byte in text.bytes() {
        output[*position] = byte;
        *position += 1;
    }
}

fn append_unsigned(output: &mut [u8; MAX_OUTPUT_BYTES], position: &mut usize, value_input: u64) {
    let mut reversed = [0_u8; 24];
    let mut count = 0;
    let mut value = value_input;
    loop {
        reversed[count] = b'0' + (value % 10) as u8;
        count += 1;
        value /= 10;
        if value == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        output[*position] = reversed[count];
        *position += 1;
    }
}

fn render_output(n: usize, solutions: u64,
                 output: &mut [u8; MAX_OUTPUT_BYTES]) -> usize {
    let mut position = 0;
    append_unsigned(output, &mut position, n as u64);
    if n == 1 {
        append_text(output, &mut position, " queen on a ");
    } else {
        append_text(output, &mut position, " queens on a ");
    }
    append_unsigned(output, &mut position, n as u64);
    output[position] = b'x';
    position += 1;
    append_unsigned(output, &mut position, n as u64);
    append_text(output, &mut position, " board...\n");
    if solutions == 1 {
        append_text(output, &mut position, "...there is 1 solution\n");
    } else {
        append_text(output, &mut position, "...there are ");
        append_unsigned(output, &mut position, solutions);
        append_text(output, &mut position, " solutions\n");
    }
    position
}

#[no_mangle]
pub unsafe extern "C" fn queens(n: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(1..=MAX_N as i64).contains(&n) { return -1; }
    let n = n as usize;
    let mut state = QueensState {
        n,
        queen: [0; MAX_N],
        file: [EMPTY_OWNER; MAX_N],
        forward_diag: [EMPTY_OWNER; MAX_DIAGS],
        backward_diag: [EMPTY_OWNER; MAX_DIAGS],
        solutions: 0,
    };
    find_solutions(&mut state, 0);

    let mut formatted = [0_u8; MAX_OUTPUT_BYTES];
    let required = render_output(n, state.solutions, &mut formatted);
    if output.is_null() || output_capacity < required as usize { return -2; }
    unsafe { std::ptr::copy_nonoverlapping(formatted.as_ptr(), output, required); }
    required as i64
}
