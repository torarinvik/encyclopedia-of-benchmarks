package beebs_fasta

import "core:c"

MAX_COUNT :: 1000
MAX_STATE :: 139967
WIDTH :: 60
ALU :: "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGGGAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGACCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAATACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCAGCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGGAGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCCAGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA"
IUB_WEIGHTS: [15]f32 = {0.27,0.12,0.12,0.27,0.02,0.02,0.02,0.02,0.02,0.02,0.02,0.02,0.02,0.02,0.02}
IUB_SYMBOLS: [15]u8 = {'a','c','g','t','B','D','H','K','M','N','R','S','V','W','Y'}
HUMAN_WEIGHTS: [4]f32 = {0.3029549426680,0.1979883004921,0.1975473066391,0.3015094502008}
HUMAN_SYMBOLS: [4]u8 = {'a','c','g','t'}

wrapped_lines :: proc(count: int) -> int { return (count + WIDTH - 1) / WIDTH }
fasta_output_length :: proc(count: int) -> int {
    return 77 + 10*count + wrapped_lines(2*count) + wrapped_lines(3*count) + wrapped_lines(5*count)
}

accumulate_probabilities :: proc(weights: []f32) {
    cumulative := f32(0)
    for i in 0..<len(weights) { cumulative += weights[i]; weights[i] = cumulative }
}

next_weighted_base :: proc(state: ^u32, weights: []f32, symbols: []u8) -> u8 {
    state^ = (state^ * 3877 + 29573) % 139968
    random_value := 1.0 * f32(state^) / 139968.0
    for i in 0..<len(weights) {
        if weights[i] >= random_value do return symbols[i]
    }
    return symbols[len(symbols)-1]
}

write_repeat :: proc(output: [^]u8, offset: int, count: int) -> int {
    position := offset
    for i in 0..<count {
        output[position] = ALU[i % len(ALU)]; position += 1
        if (i+1)%WIDTH == 0 || i+1 == count { output[position] = 10; position += 1 }
    }
    return position
}

write_weighted :: proc(output: [^]u8, offset: int, count: int, state: ^u32,
                       weights: []f32, symbols: []u8) -> int {
    position := offset
    for i in 0..<count {
        output[position] = next_weighted_base(state, weights, symbols); position += 1
        if (i+1)%WIDTH == 0 || i+1 == count { output[position] = 10; position += 1 }
    }
    return position
}

@(export)
beebs_fasta :: proc "c" (values: [^]i64, length: c.size_t,
                          output: [^]u8, capacity: c.size_t) -> i64 {
    if values == nil || length != 2 do return -1
    count_value := values[0]
    seed_value := values[1]
    if count_value < 1 || count_value > MAX_COUNT || seed_value < 0 || seed_value > MAX_STATE do return -1
    count := int(count_value)
    needed := fasta_output_length(count)
    if output == nil || capacity < c.size_t(needed) do return -2
    iub_weights := IUB_WEIGHTS
    human_weights := HUMAN_WEIGHTS
    accumulate_probabilities(iub_weights[:])
    accumulate_probabilities(human_weights[:])
    header_one := ">ONE Homo sapiens alu\n"
    header_two := ">TWO IUB ambiguity codes\n"
    header_three := ">THREE Homo sapiens frequency\n"
    position := 0
    for i in 0..<len(header_one) { output[position] = header_one[i]; position += 1 }
    position = write_repeat(output, position, 2*count)
    for i in 0..<len(header_two) { output[position] = header_two[i]; position += 1 }
    state := u32(seed_value)
    position = write_weighted(output, position, 3*count, &state, iub_weights[:], IUB_SYMBOLS[:])
    for i in 0..<len(header_three) { output[position] = header_three[i]; position += 1 }
    position = write_weighted(output, position, 5*count, &state, human_weights[:], HUMAN_SYMBOLS[:])
    return i64(position)
}
