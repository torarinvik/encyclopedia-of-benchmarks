module negative_binary_base_to_int

// Interpret most-significant-first bits in radix -2 with checked i64 folding.
@[export: 'negative_binary_base_to_int']
pub fn negative_binary_base_to_int(input &i64, length usize) i64 {
    if length < 1 || length > 63 { return -1 }
    mut value := i64(0)
    for index := usize(0); index < length; index++ {
        bit := unsafe { input[index] }
        if bit != 0 && bit != 1 { return -1 }
        if value > 4611686018427387904 || value < -4611686018427387903 { return -1 }
        value = value * -2 + bit
    }
    return value
}
