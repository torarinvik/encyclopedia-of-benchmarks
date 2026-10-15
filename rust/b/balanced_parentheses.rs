/// Check (), [], and {} nesting; ignore other character codes.
#[no_mangle]
pub extern "C" fn balanced_parentheses(values: *const i64, length: usize) -> i64 {
    if length > 4096 { return -1; }
    let mut stack = [0_i64; 4096];
    let mut top = 0usize;
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if value == 40 || value == 91 || value == 123 {
            stack[top] = value;
            top += 1;
        } else if value == 41 || value == 93 || value == 125 {
            if top == 0 { return 0; }
            top -= 1;
            let opener = stack[top];
            if (value == 41 && opener != 40) || (value == 93 && opener != 91) || (value == 125 && opener != 123) {
                return 0;
            }
        }
    }
    if top == 0 { 1 } else { 0 }
}
