module balanced_parentheses

// Check (), [], and {} nesting; ignore other character codes.
@[export: 'balanced_parentheses']
pub fn balanced_parentheses(values &i64, length usize) i64 {
    if length > 4096 { return -1 }
    mut stack := [4096]i64{}
    mut top := usize(0)
    for index in 0 .. length {
        value := unsafe { values[index] }
        if value == 40 || value == 91 || value == 123 {
            stack[top] = value
            top++
        } else if value == 41 || value == 93 || value == 125 {
            if top == 0 { return 0 }
            top--
            opener := stack[top]
            if (value == 41 && opener != 40) || (value == 93 && opener != 91) || (value == 125 && opener != 123) {
                return 0
            }
        }
    }
    return if top == 0 { i64(1) } else { i64(0) }
}
