const INPUT_COUNT: usize = 9;
const OUTPUT_COUNT: usize = 17;
const OUTPUT_BYTES: usize = OUTPUT_COUNT * 8;
const MAX_RUNS: i64 = 64;

#[no_mangle]
pub extern "C" fn nsichneu(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != INPUT_COUNT {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=MAX_RUNS).contains(&input[0]) || input[1..].iter().any(|value| !(-1000..=1000).contains(value)) {
        return -1;
    }
    if output.is_null() || capacity < OUTPUT_BYTES {
        return -2;
    }

    let p1 = [input[1], input[2], input[3]];
    let p2 = [input[4], input[5], input[6], input[7], input[8]];
    let mut p3 = [0i64; 6];
    let mut p1_count = 3i64;
    let mut p2_count = 5i64;
    let mut p3_count = 0i64;

    for _run in 0..input[0] {
        p1_count = 3;
        p2_count = 5;
        p3_count = 0;
        for first in 0..3 {
            for second in 0..3 {
                if second == first {
                    continue;
                }
                for third in 0..3 {
                    if third == first || third == second {
                        continue;
                    }
                    if p1_count >= 3 && p3_count + 3 <= 6 && p1[second] == p1[third] {
                        let x = p1[first];
                        let y = p1[second];
                        if x < y {
                            p1_count -= 3;
                            let at = p3_count as usize;
                            p3[at] = x;
                            p3[at + 1] = y;
                            p3[at + 2] = x - y;
                            p3_count += 3;
                        }
                    }
                }
            }
        }

        for subset_number in 0..5 {
            let omitted = 4 - subset_number;
            let mut subset = [0usize; 4];
            let mut count = 0usize;
            for index in 0..5 {
                if index != omitted {
                    subset[count] = index;
                    count += 1;
                }
            }
            for a in 0..4 {
                for b in 0..4 {
                    if b == a {
                        continue;
                    }
                    for c in 0..4 {
                        if c == a || c == b {
                            continue;
                        }
                        for d in 0..4 {
                            if d == a || d == b || d == c {
                                continue;
                            }
                            let i0 = subset[a];
                            let i1 = subset[b];
                            let i2 = subset[c];
                            let i3 = subset[d];
                            if p2_count >= 4
                                && p3_count + 3 <= 6
                                && p2[i1] == p2[i2]
                                && p2[i1] == p2[i3]
                            {
                                let x = p2[i0];
                                let y = p2[i1];
                                if y > x {
                                    p2_count -= 4;
                                    let at = p3_count as usize;
                                    p3[at] = x;
                                    p3[at + 1] = y;
                                    p3[at + 2] = x + y;
                                    p3_count += 3;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    let mut snapshot = [0i64; OUTPUT_COUNT];
    let mut position = 0usize;
    snapshot[position] = p1_count;
    position += 1;
    for value in p1 {
        snapshot[position] = value;
        position += 1;
    }
    snapshot[position] = p2_count;
    position += 1;
    for value in p2 {
        snapshot[position] = value;
        position += 1;
    }
    snapshot[position] = p3_count;
    position += 1;
    for value in p3 {
        snapshot[position] = value;
        position += 1;
    }
    let output = unsafe { std::slice::from_raw_parts_mut(output, OUTPUT_BYTES) };
    for (index, value) in snapshot.iter().enumerate() {
        output[index * 8..index * 8 + 8].copy_from_slice(&value.to_le_bytes());
    }
    OUTPUT_BYTES as i64
}
