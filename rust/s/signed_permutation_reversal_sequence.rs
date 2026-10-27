const MAX_N: usize = 5;
const MAX_STATES: usize = 3840;
const MAX_MOVES: usize = 10;
const MAX_OUTPUT_BYTES: usize = 168;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

fn encode(permutation: &[i64; MAX_N], n: usize) -> usize {
    let mut rank = 0usize;
    let mut signs = 0usize;
    for i in 0..n {
        let value = permutation[i].abs() as usize;
        let mut smaller = 0usize;
        for j in (i + 1)..n {
            if permutation[j].abs() < value as i64 { smaller += 1; }
        }
        rank = rank * (n - i) + smaller;
        if permutation[i] < 0 { signs |= 1usize << (value - 1); }
    }
    rank * (1usize << n) + signs
}

fn decode_state(state: usize, n: usize, factorials: &[usize; MAX_N + 1],
                permutation: &mut [i64; MAX_N]) {
    let sign_count = 1usize << n;
    let mut rank = state / sign_count;
    let signs = state % sign_count;
    let mut available = [0usize; MAX_N];
    for i in 0..n { available[i] = i + 1; }
    let mut remaining = n;
    for i in 0..n {
        let factor = factorials[n - i - 1];
        let digit = rank / factor;
        rank %= factor;
        let value = available[digit];
        for j in digit..(remaining - 1) { available[j] = available[j + 1]; }
        remaining -= 1;
        permutation[i] = if signs & (1usize << (value - 1)) != 0 { -(value as i64) } else { value as i64 };
    }
}

fn reverse_signed(permutation: &mut [i64; MAX_N], mut left: usize, mut right: usize) {
    while left < right {
        let a = permutation[left];
        let b = permutation[right];
        permutation[left] = -b;
        permutation[right] = -a;
        left += 1;
        right -= 1;
    }
    if left == right { permutation[left] = -permutation[left]; }
}

#[no_mangle]
pub unsafe extern "C" fn signed_permutation_reversal_sequence(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_N + 1 { return -1; }
    let raw_n = *input;
    if raw_n < 2 || raw_n > MAX_N as i64 || length != raw_n as usize + 1 { return -1; }
    let n = raw_n as usize;
    let mut seen = 0usize;
    let mut permutation = [0i64; MAX_N];
    for i in 0..n {
        let value = *input.add(i + 1);
        if value == 0 || value == i64::MIN { return -1; }
        let absolute = value.abs() as usize;
        if absolute > n { return -1; }
        let bit = 1usize << (absolute - 1);
        if seen & bit != 0 { return -1; }
        seen |= bit;
        permutation[i] = value;
    }
    if seen != (1usize << n) - 1 { return -1; }
    if output.is_null() { return -2; }

    let factorials = [1usize, 1, 2, 6, 24, 120];
    let state_count = factorials[n] * (1usize << n);
    let mut parent = [0i32; MAX_STATES];
    let mut queue = [0i32; MAX_STATES];
    let mut move_left = [0i8; MAX_STATES];
    let mut move_right = [0i8; MAX_STATES];
    for state in 0..state_count { parent[state] = -2; }
    let start = encode(&permutation, n);
    let mut head = 0usize;
    let mut tail = 0usize;
    parent[start] = -1;
    queue[tail] = start as i32;
    tail += 1;
    while head < tail && parent[0] == -2 {
        let current = queue[head] as usize;
        head += 1;
        let mut current_permutation = [0i64; MAX_N];
        decode_state(current, n, &factorials, &mut current_permutation);
        for left in 0..n {
            if parent[0] != -2 { break; }
            for right in left..n {
                let mut neighbor = current_permutation;
                reverse_signed(&mut neighbor, left, right);
                let next = encode(&neighbor, n);
                if parent[next] != -2 { continue; }
                parent[next] = current as i32;
                move_left[next] = (left + 1) as i8;
                move_right[next] = (right + 1) as i8;
                queue[tail] = next as i32;
                tail += 1;
                if next == 0 { break; }
            }
        }
    }
    if parent[0] == -2 { return -1; }
    let mut reverse_moves = [[0i64; 2]; MAX_MOVES];
    let mut move_count = 0usize;
    let mut current = 0usize;
    while parent[current] >= 0 {
        if move_count == MAX_MOVES { return -1; }
        reverse_moves[move_count] = [move_left[current] as i64, move_right[current] as i64];
        move_count += 1;
        current = parent[current] as usize;
    }
    let output_bytes = 8 * (1 + 2 * move_count);
    if capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    store_i64_le(staged.as_mut_ptr(), 0, move_count as i64);
    for i in 0..move_count {
        let reverse_index = move_count - 1 - i;
        store_i64_le(staged.as_mut_ptr(), 8 * (1 + 2 * i), reverse_moves[reverse_index][0]);
        store_i64_le(staged.as_mut_ptr(), 8 * (2 + 2 * i), reverse_moves[reverse_index][1]);
    }
    for byte in 0..output_bytes { *output.add(byte) = staged[byte]; }
    output_bytes as i64
}
