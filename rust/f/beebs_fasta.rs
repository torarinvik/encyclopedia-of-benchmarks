/// Clean-room, bounded BEEBS FASTA generation profile.
const MAX_COUNT: i64 = 1_000;
const MAX_STATE: i64 = 139_967;
const WIDTH: usize = 60;
const ALU: &[u8] = concat!(
    "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG",
    "GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA",
    "CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT",
    "ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA",
    "GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG",
    "AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC",
    "AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA"
).as_bytes();
const IUB_WEIGHTS: [f32; 15] = [
    0.27, 0.12, 0.12, 0.27, 0.02, 0.02, 0.02, 0.02,
    0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02,
];
const IUB_SYMBOLS: [u8; 15] = *b"acgtBDHKMNRSVWY";
const HUMAN_WEIGHTS: [f32; 4] = [0.3029549426680, 0.1979883004921, 0.1975473066391, 0.3015094502008];
const HUMAN_SYMBOLS: [u8; 4] = *b"acgt";

fn wrapped_lines(count: usize) -> usize { (count + WIDTH - 1) / WIDTH }

fn fasta_output_length(count: usize) -> usize {
    77 + 10 * count + wrapped_lines(2 * count) + wrapped_lines(3 * count) + wrapped_lines(5 * count)
}

fn accumulate_probabilities(weights: &mut [f32]) {
    let mut cumulative = 0.0_f32;
    for weight in weights {
        cumulative += *weight;
        *weight = cumulative;
    }
}

fn next_weighted_base(state: &mut u32, weights: &[f32], symbols: &[u8]) -> u8 {
    *state = (*state * 3_877 + 29_573) % 139_968;
    let random_value = 1.0_f32 * (*state as f32) / 139_968.0_f32;
    for (index, weight) in weights.iter().enumerate() {
        if *weight >= random_value { return symbols[index]; }
    }
    symbols[symbols.len() - 1]
}

fn write_repeat(output: &mut [u8], mut offset: usize, count: usize) -> usize {
    for index in 0..count {
        output[offset] = ALU[index % ALU.len()]; offset += 1;
        if (index + 1) % WIDTH == 0 || index + 1 == count {
            output[offset] = b'\n'; offset += 1;
        }
    }
    offset
}

fn write_weighted(output: &mut [u8], mut offset: usize, count: usize,
                  state: &mut u32, weights: &[f32], symbols: &[u8]) -> usize {
    for index in 0..count {
        output[offset] = next_weighted_base(state, weights, symbols); offset += 1;
        if (index + 1) % WIDTH == 0 || index + 1 == count {
            output[offset] = b'\n'; offset += 1;
        }
    }
    offset
}

#[no_mangle]
pub unsafe extern "C" fn beebs_fasta(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let count_value = *values;
    let seed_value = *values.add(1);
    if !(1..=MAX_COUNT).contains(&count_value) || !(0..=MAX_STATE).contains(&seed_value) { return -1; }
    let count = count_value as usize;
    let needed = fasta_output_length(count);
    if output.is_null() || capacity < needed { return -2; }
    let mut iub_weights = IUB_WEIGHTS;
    let mut human_weights = HUMAN_WEIGHTS;
    accumulate_probabilities(&mut iub_weights);
    accumulate_probabilities(&mut human_weights);
    let result = std::slice::from_raw_parts_mut(output, needed);
    let mut offset = 0;
    let header_one = b">ONE Homo sapiens alu\n";
    let header_two = b">TWO IUB ambiguity codes\n";
    let header_three = b">THREE Homo sapiens frequency\n";
    result[offset..offset + header_one.len()].copy_from_slice(header_one); offset += header_one.len();
    offset = write_repeat(result, offset, 2 * count);
    result[offset..offset + header_two.len()].copy_from_slice(header_two); offset += header_two.len();
    let mut state = seed_value as u32;
    offset = write_weighted(result, offset, 3 * count, &mut state, &iub_weights, &IUB_SYMBOLS);
    result[offset..offset + header_three.len()].copy_from_slice(header_three); offset += header_three.len();
    offset = write_weighted(result, offset, 5 * count, &mut state, &human_weights, &HUMAN_SYMBOLS);
    offset as i64
}
