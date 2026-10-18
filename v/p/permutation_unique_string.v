const max_length = 5
const max_input = 7
const max_output = 601

@[export: 'permutation_unique_string']
pub fn permutation_unique_string(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || input_length == 0 || input_length > max_input { return -1 }
        if input[0] < 0 || input[0] > max_length || input_length != usize(input[0] + 1) { return -1 }
        length := int(input[0])
        mut current := [max_length]u8{}
        for i in 0 .. length {
            if input[i + 1] < 32 || input[i + 1] > 126 { return -1 }
            current[i] = u8(input[i + 1])
        }
        for i in 1 .. length {
            value := current[i]
            mut j := i
            for j > 0 && current[j - 1] > value {
                current[j] = current[j - 1]
                j--
            }
            current[j] = value
        }
        mut staged := [max_output]u8{}
        mut count := 0
        for {
            for i in 0 .. length { staged[1 + count * length + i] = current[i] }
            count++
            if length < 2 { break }
            mut pivot := length - 1
            for pivot > 0 && current[pivot - 1] >= current[pivot] { pivot-- }
            if pivot == 0 { break }
            mut successor := length - 1
            for current[successor] <= current[pivot - 1] { successor-- }
            temp := current[pivot - 1]
            current[pivot - 1] = current[successor]
            current[successor] = temp
            mut left := pivot
            mut right := length - 1
            for left < right {
                temp = current[left]
                current[left] = current[right]
                current[right] = temp
                left++
                right--
            }
        }
        staged[0] = u8(count)
        output_size := 1 + count * length
        if output == nil || capacity < output_size { return -2 }
        for i in 0 .. output_size { output[i] = staged[i] }
        return i64(output_size)
    }
}
