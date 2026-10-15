module valid_parentheses

// Check bracket nesting with a bounded stack.
@[export: 'valid_parentheses']
pub fn valid_parentheses(input &i64, length usize) i64 {
    if length > 256 { return -1 }
    unsafe {
        for index in 0 .. length {
            value := input[index]
            if value != 40 && value != 41 && value != 91 && value != 93 && value != 123 && value != 125 { return -1 }
        }
        mut stack := [256]u8{}
        mut top := 0
        for index in 0 .. length {
            value := u8(input[index])
            if value == u8(`(`) || value == u8(`[`) || value == u8(`{`) {
                stack[top] = value
                top++
            } else {
                if top == 0 { return 0 }
                top--
                mut expected := u8(`{`)
                if value == u8(`)`) { expected = u8(`(`) }
                if value == u8(`]`) { expected = u8(`[`) }
                if stack[top] != expected { return 0 }
            }
        }
        return if top == 0 { 1 } else { 0 }
    }
}
