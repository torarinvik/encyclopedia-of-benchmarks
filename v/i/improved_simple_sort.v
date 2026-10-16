module main

const max_length = 256
const min_value = i64(-1_000_000)
const max_value = i64(1_000_000)
const checksum_offset = i64(1_000_001)
const invalid_result = i64(-1)

@[export: 'improved_simple_sort']
pub fn improved_simple_sort(input &i64, length usize) i64 {
    unsafe {
        if length > max_length || (length != 0 && input == nil) { return invalid_result }
        mut working := []i64{len: int(length), init: 0}
        for index in 0 .. int(length) {
            if input[index] < min_value || input[index] > max_value { return invalid_result }
            working[index] = input[index]
        }

        mut i := 1
        for i < int(length) {
            mut j := 0
            for j + 1 < int(length) {
                if working[i] < working[j] {
                    temporary := working[i]
                    working[i] = working[j]
                    working[j] = temporary
                }
                j++
            }
            i++
        }
        mut checksum := i64(0)
        for index in 0 .. int(length) {
            checksum += i64(index + 1) * (working[index] + checksum_offset)
        }
        return checksum
    }
}
