module main

const max_number = i64(4096)
const stack_capacity = 4112

@[export: 'lexicographical_numbers']
pub fn lexicographical_numbers(values &i64, length usize) i64 {
    unsafe {
        if values == nil || length != 1 || values[0] < 0 || values[0] > max_number { return -1 }
        mut stack := [stack_capacity]i64{}
        mut top := 1
        stack[0] = 1
        mut index := i64(0)
        mut checksum := i64(0)
        for top > 0 {
            top--
            number := stack[top]
            if number <= values[0] {
                index++
                checksum += index * number
                if number % 10 != 9 { stack[top] = number + 1; top++ }
                stack[top] = number * 10
                top++
            }
        }
        return checksum
    }
}
