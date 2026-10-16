module main

const max_length = 8
const invalid_result = i64(-1)

fn permutation_sort_is_sorted(values []i64) bool {
    for index in 1 .. values.len {
        if values[index - 1] > values[index] { return false }
    }
    return true
}

@[export: 'permutation_sort']
pub fn permutation_sort(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length == 0 || length > max_length { return invalid_result }

        mut working := []i64{len: int(length), init: 0}
        mut counters := []int{len: int(length), init: 0}
        for index in 0 .. int(length) { working[index] = input[index] }

        mut checked := i64(1)
        if permutation_sort_is_sorted(working) { return checked }

        mut index := 0
        for index < int(length) {
            if counters[index] < index {
                mut swap_index := 0
                if index % 2 != 0 { swap_index = counters[index] }
                temporary := working[swap_index]
                working[swap_index] = working[index]
                working[index] = temporary
                counters[index]++
                checked++
                if permutation_sort_is_sorted(working) { return checked }
                index = 0
            } else {
                counters[index] = 0
                index++
            }
        }
        return invalid_result
    }
}
