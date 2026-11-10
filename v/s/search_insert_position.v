module search_insert_position

// Return the lower-bound position in a strictly increasing signed 32-bit array.
@[export: 'search_insert_position']
pub fn search_insert_position(input &i64, length usize) i64 {
    if length < 1 || length > 257 { return -1 }
    unsafe {
        target := input[0]
        if target < -2_147_483_648 || target > 2_147_483_647 { return -1 }
        mut previous := i64(-2_147_483_649)
        for index in 1 .. length {
            value := input[index]
            if value > 2_147_483_647 || value <= previous { return -1 }
            previous = value
        }
        mut low := 0
        mut high := int(length - 1)
        for low < high {
            middle := low + (high - low) / 2
            if input[middle + 1] < target { low = middle + 1 }
            else { high = middle }
        }
        return i64(low)
    }
}
