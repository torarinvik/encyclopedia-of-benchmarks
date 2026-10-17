const max_text_length = 64
const max_input_length = 65

fn pair_less(left int, right int, rank [64]i64, length int, step int) bool {
    if rank[left] != rank[right] { return rank[left] < rank[right] }
    left_second := if left + step < length { rank[left + step] } else { i64(-1) }
    right_second := if right + step < length { rank[right + step] } else { i64(-1) }
    return left_second < right_second
}

@[export: 'suffix_array']
pub fn suffix_array(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
    unsafe {
        if values == nil || length < 1 || length > max_input_length { return -1 }
        count_value := values[0]
        if count_value < 0 || count_value > max_text_length { return -1 }
        count := int(count_value)
        if length != usize(1 + count) { return -1 }
        for i := 0; i < count; i++ {
            if values[1 + i] < 0 || values[1 + i] > 127 { return -1 }
        }

        output_bytes := count * 8
        if output == nil || output_capacity < usize(output_bytes) { return -2 }
        if count == 0 { return 0 }

        mut suffixes := [64]int{}
        mut rank := [64]i64{}
        mut next_rank := [64]i64{}
        for i := 0; i < count; i++ {
            suffixes[i] = i
            rank[i] = values[1 + i]
        }

        mut step := 1
        for step < count {
            for i := 1; i < count; i++ {
                key := suffixes[i]
                mut position := i
                for position > 0 && pair_less(key, suffixes[position - 1], rank, count, step) {
                    suffixes[position] = suffixes[position - 1]
                    position--
                }
                suffixes[position] = key
            }
            next_rank[suffixes[0]] = 0
            for i := 1; i < count; i++ {
                previous := suffixes[i - 1]
                current := suffixes[i]
                previous_second := if previous + step < count { rank[previous + step] } else { i64(-1) }
                current_second := if current + step < count { rank[current + step] } else { i64(-1) }
                next_rank[current] = next_rank[previous]
                if rank[previous] != rank[current] || previous_second != current_second {
                    next_rank[current]++
                }
            }
            for i := 0; i < count; i++ { rank[i] = next_rank[i] }
            if rank[suffixes[count - 1]] == i64(count - 1) { break }
            step *= 2
        }

        for i := 0; i < count; i++ {
            bits := u64(suffixes[i])
            for byte := 0; byte < 8; byte++ {
                output[i * 8 + byte] = u8((bits >> u64(byte * 8)) & 255)
            }
        }
        return i64(output_bytes)
    }
}
