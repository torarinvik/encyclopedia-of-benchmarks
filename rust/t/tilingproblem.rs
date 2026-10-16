#[no_mangle]
pub unsafe extern "C" fn tilingproblem(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let n=*input; if !(0..=91).contains(&n) { return -1; }
    let (mut previous,mut current)=(1i64,1i64);for _ in 2..=n {let next=previous+current;previous=current;current=next;}current
}
