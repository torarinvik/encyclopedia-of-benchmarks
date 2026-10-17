module skytale_cipher

const max_input_length = 260
const max_text_length = 256
const max_key = 256

@[export: 'skytale_cipher']
pub fn skytale_cipher(input &i64, length usize, output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 3 || length > max_input_length { return -1 }
    unsafe {
        if input[0] < 0 || input[0] > 1 || input[1] < 1 || input[1] > max_key || input[2] < 0 || input[2] > max_text_length { return -1 }
        mode := int(input[0])
        key := int(input[1])
        n := int(input[2])
        if length != usize(3 + n) { return -1 }
        for i in 0 .. n { if input[3 + i] < 0 || input[3 + i] > 127 { return -1 } }
        if output == nil || capacity < usize(n) { return -2 }

        if mode == 0 {
            mut out := 0
            for row in 0 .. key {
                mut position := row
                for position < n {
                    output[out] = u8(input[3 + position])
                    out++
                    position += key
                }
            }
        } else {
            mut starts := [256]int{}
            mut used := [256]int{}
            base := n / key
            extra := n % key
            for row in 1 .. key {
                increment := if row - 1 < extra { 1 } else { 0 }
                starts[row] = starts[row - 1] + base + increment
            }
            for position in 0 .. n {
                row := position % key
                output[position] = u8(input[3 + starts[row] + used[row]])
                used[row]++
            }
        }
        return i64(n)
    }
}
