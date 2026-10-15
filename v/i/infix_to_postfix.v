module infix_to_postfix

const max_expression = 24
const max_stack = 10

fn is_operand(ch i64) bool {
    return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122)
}
fn is_operator(ch i64) bool { return ch == 43 || ch == 45 || ch == 42 || ch == 47 || ch == 94 }
fn precedence(ch i64) i64 { if ch == 43 || ch == 45 { return 1 }; if ch == 42 || ch == 47 { return 2 }; return 3 }

@[export: 'infix_to_postfix']
pub fn infix_to_postfix(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length == 0 || length > max_expression { return -1 }
    unsafe {
        mut stack := [max_stack]u8{}
        mut result := [max_expression + 1]u8{}
        mut top := 0
        mut count := 0
        mut expect_operand := true
        for index in 0 .. int(length) {
            ch := input[index]
            if is_operand(ch) {
                if !expect_operand { return -1 }
                result[count] = u8(ch); count++; expect_operand = false
            } else if ch == 40 {
                if !expect_operand || top == max_stack { return -1 }
                stack[top] = 40; top++
            } else if ch == 41 {
                for top > 0 && stack[top-1] != 40 {
                    top--; result[count] = stack[top]; count++
                }
                if top > 0 { top-- }
                expect_operand = false
            } else if is_operator(ch) {
                if expect_operand { return -1 }
                for top > 0 && stack[top-1] != 40 && precedence(ch) <= precedence(i64(stack[top-1])) {
                    top--; result[count] = stack[top]; count++
                }
                if top == max_stack { return -1 }
                stack[top] = u8(ch); top++; expect_operand = true
            } else { return -1 }
        }
        if expect_operand { return -1 }
        for top > 0 {
            top--
            if stack[top] == 40 { return -1 }
            result[count] = stack[top]; count++
        }
        result[count] = 0; count++
        if output_capacity < count { return -2 }
        for index in 0 .. count { output[index] = result[index] }
        return i64(count)
    }
}
