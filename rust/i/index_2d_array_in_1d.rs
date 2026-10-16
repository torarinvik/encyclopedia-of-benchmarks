/// Retrieve one row-major flattened index from a rectangular matrix.
#[no_mangle]
pub unsafe extern "C" fn index_2d_array_in_1d(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 { return -1; }
    let header=std::slice::from_raw_parts(input,3);
    let rows=header[0]; let cols=header[1]; let index=header[2];
    if !(1..=32).contains(&rows) || !(1..=32).contains(&cols) { return -1; }
    let cells=(rows*cols) as usize;
    if length != cells+3 || index < 0 || index >= rows*cols { return -1; }
    let packed=std::slice::from_raw_parts(input,length);
    if packed[3..].iter().any(|v| *v < 0 || *v > 1_000_000) { return -1; }
    let row=(index/cols) as usize; let col=(index%cols) as usize;
    packed[3+row*(cols as usize)+col]
}
