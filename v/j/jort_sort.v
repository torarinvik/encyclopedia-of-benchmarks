module main

const max_length = 64

@[export: 'jort_sort']
pub fn jort_sort(values &i64, length usize) i64 {
    unsafe {
        if length == 0 { return 1 }
        if values == nil || length > max_length { return -1 }
        mut copy := [max_length]i64{}
        for i in 0 .. int(length) { copy[i] = values[i] }
        for i in 2 .. int(length) {
            key := copy[i]
            mut position := i
            for position > 1 && copy[position - 1] > key {
                copy[position] = copy[position - 1]
                position--
            }
            copy[position] = key
        }
        for i in 0 .. int(length) { if copy[i] != values[i] { return 0 } }
        return 1
    }
}
