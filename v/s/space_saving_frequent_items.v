module space_saving_frequent_items

@[export: 'space_saving_frequent_items']
pub fn space_saving_frequent_items(input &i64, length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || length < 2 || length > 67 { return -1 }
        if input[0] < 1 || input[0] > 8 || input[1] < 0 || input[1] > 64 { return -1 }
        k := int(input[0])
        n := int(input[1])
        if length != usize(2+n) { return -1 }
        for i in 0 .. n {
            if input[2+i] < -1000 || input[2+i] > 1000 { return -1 }
        }
        mut items := [8]i64{}
        mut estimates := [8]i64{}
        mut errors := [8]i64{}
        mut used := 0
        for i in 0 .. n {
            item := input[2+i]
            mut found := used
            for j in 0 .. used {
                if items[j] == item { found = j; break }
            }
            if found < used {
                estimates[found]++
            } else if used < k {
                items[used] = item
                estimates[used] = 1
                errors[used] = 0
                used++
            } else {
                mut victim := 0
                for j in 1 .. used {
                    if estimates[j] < estimates[victim] || (estimates[j] == estimates[victim] && items[j] < items[victim]) { victim = j }
                }
                minimum := estimates[victim]
                items[victim] = item
                estimates[victim] = minimum+1
                errors[victim] = minimum
            }
        }
        mut sort_index := 1
        for sort_index < used {
            mut j := sort_index
            for j > 0 && items[j] < items[j-1] {
                item := items[j]
                estimate := estimates[j]
                error := errors[j]
                items[j] = items[j-1]
                estimates[j] = estimates[j-1]
                errors[j] = errors[j-1]
                items[j-1] = item
                estimates[j-1] = estimate
                errors[j-1] = error
                j--
            }
            sort_index++
        }
        bytes := 8*(1+3*used)
        if output == nil || capacity < usize(bytes) { return -2 }
        mut fields := [25]i64{}
        fields[0] = i64(used)
        for i in 0 .. used {
            fields[1+3*i] = items[i]
            fields[2+3*i] = estimates[i]
            fields[3+3*i] = errors[i]
        }
        mut staged := [200]u8{}
        for i in 0 .. 1+3*used {
            bits := u64(fields[i])
            for b in 0 .. 8 { staged[8*i+b] = u8((bits >> (8*b)) & 255) }
        }
        for i in 0 .. bytes { output[i] = staged[i] }
        return i64(bytes)
    }
}
