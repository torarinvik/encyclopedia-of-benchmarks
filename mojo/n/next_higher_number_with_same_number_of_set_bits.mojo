const MAX_INPUT_VALUE: Int64 = 1_073_741_823

@export("next_higher_number_with_same_number_of_set_bits")
fn next_higher_number_with_same_number_of_set_bits(input: Int64) abi("C") -> Int64:
    if input < 1 or input > MAX_INPUT_VALUE:
        return -1

    let value = UInt64(input)
    let lowest_set_bit = value & (~value + 1)
    let raised = value + lowest_set_bit
    let repacked = ((raised ^ value) >> 2) / lowest_set_bit
    return Int64(raised | repacked)
