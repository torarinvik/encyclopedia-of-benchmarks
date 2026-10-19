const SOURCE_CALLS: i64 = 1;
const OUTPUT_BYTES: usize = 13;
const SOURCE_OUTPUT: [u8; OUTPUT_BYTES] = *b"hello world\n\n";

#[no_mangle]
pub unsafe extern "C" fn shootout_hello(calls: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if calls != SOURCE_CALLS { return -1; }
    if output.is_null() || output_capacity < OUTPUT_BYTES { return -2; }
    let mut staged = [0_u8; OUTPUT_BYTES];
    staged.copy_from_slice(&SOURCE_OUTPUT);
    for index in 0..OUTPUT_BYTES { *output.add(index) = staged[index]; }
    OUTPUT_BYTES as i64
}
