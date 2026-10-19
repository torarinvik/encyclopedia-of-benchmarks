const MIN_PASSES: i64 = 1;
const MAX_PASSES: i64 = 30;
const DATA_BYTES: usize = 4096;
const OUTPUT_CAPACITY: usize = 52;

fn heap_adjust(frequency: &[usize; 512], heap: &mut [usize; 256], active: usize, mut index: usize) {
    let value = heap[index - 1];
    while index <= active / 2 {
        let mut child = index * 2;
        if child < active && frequency[heap[child - 1]] > frequency[heap[child]] { child += 1; }
        if frequency[value] < frequency[heap[child - 1]] { break; }
        heap[index - 1] = heap[child - 1];
        index = child;
    }
    heap[index - 1] = value;
}

fn random4(seed: &mut i64) -> usize {
    *seed ^= 123_459_876;
    let quotient = *seed / 127_773;
    *seed = 16_807 * (*seed - quotient * 127_773) - 2_836 * quotient;
    if *seed < 0 { *seed += 2_147_483_647; }
    let result = (*seed % 32) as usize;
    *seed ^= 123_459_876;
    result
}

fn compdecomp(data: &mut [u8; DATA_BYTES]) -> Option<(usize, u32)> {
    let mut frequency = [0_usize; 512];
    let mut heap = [0_usize; 256];
    let mut link = [0_i32; 512];
    let mut code = [0_u32; 256];
    let mut code_length = [0_u8; 256];
    for &byte in data.iter() { frequency[byte as usize] += 1; }
    let mut active = 0;
    for symbol in 0..256 {
        if frequency[symbol] != 0 { heap[active] = symbol; active += 1; }
    }
    for index in (1..=active).rev() { heap_adjust(&frequency, &mut heap, active, index); }
    while active > 1 {
        active -= 1;
        let first = heap[0];
        heap[0] = heap[active];
        heap_adjust(&frequency, &mut heap, active, 1);
        let parent = 256 + active;
        frequency[parent] = frequency[heap[0]] + frequency[first];
        link[first] = parent as i32;
        link[heap[0]] = -(parent as i32);
        heap[0] = parent;
        heap_adjust(&frequency, &mut heap, active, 1);
    }
    link[256 + active] = 0;
    for symbol in 0..256 {
        if frequency[symbol] == 0 { continue; }
        let mut depth = 0;
        let mut bit = 1_u32;
        let mut value = 0_u32;
        let mut parent = link[symbol];
        while parent != 0 {
            if parent < 0 { value += bit; parent = -parent; }
            parent = link[parent as usize];
            bit <<= 1;
            depth += 1;
        }
        code[symbol] = value;
        code_length[symbol] = depth as u8;
    }

    let mut compressed = [0_u8; DATA_BYTES + 1];
    let mut compressed_used = 0;
    let mut bout = 0_u8;
    let mut bit_index = -1_i32;
    for &symbol in data.iter() {
        let index = symbol as usize;
        let mut mask = 1_u32 << (code_length[index] - 1);
        for _ in 0..code_length[index] {
            if bit_index == 7 {
                compressed[compressed_used] = bout;
                compressed_used += 1;
                bit_index = 0;
                bout = 0;
            } else {
                bit_index += 1;
                bout <<= 1;
            }
            if code[index] & mask != 0 { bout |= 1; }
            mask >>= 1;
        }
    }
    bout <<= (7 - bit_index) as u32;
    compressed[compressed_used] = bout;
    compressed_used += 1;

    let mut children = [[-1_i32; 2]; 512];
    let mut decoded_symbol = [-1_i32; 512];
    let mut node_count = 1_i32;
    for symbol in 0..256 {
        if frequency[symbol] == 0 { continue; }
        let mut node = 0_i32;
        for bit in (0..code_length[symbol]).rev() {
            let direction = ((code[symbol] >> bit) & 1) as usize;
            if children[node as usize][direction] < 0 {
                children[node as usize][direction] = node_count;
                node_count += 1;
            }
            node = children[node as usize][direction];
        }
        decoded_symbol[node as usize] = symbol as i32;
    }
    let mut decoded = 0;
    let mut sum = 0_u64;
    let mut node = 0_i32;
    for &byte in compressed[..compressed_used].iter() {
        for bit in (0..8).rev() {
            if decoded >= DATA_BYTES { break; }
            let direction = ((byte >> bit) & 1) as usize;
            node = children[node as usize][direction];
            if node < 0 { return None; }
            let symbol = decoded_symbol[node as usize];
            if symbol >= 0 {
                data[decoded] = symbol as u8;
                sum += data[decoded] as u64;
                decoded += 1;
                node = 0;
            }
        }
        if decoded >= DATA_BYTES { break; }
    }
    if decoded != DATA_BYTES { return None; }
    Some((compressed_used, sum as u32))
}

fn append_decimal(staged: &mut [u8; OUTPUT_CAPACITY], mut used: usize, mut value: u32) -> usize {
    let mut reversed = [0_u8; 10];
    let mut digits = 0;
    loop {
        reversed[digits] = b'0' + (value % 10) as u8;
        digits += 1;
        value /= 10;
        if value == 0 { break; }
    }
    while digits > 0 { digits -= 1; staged[used] = reversed[digits]; used += 1; }
    used
}

fn format_output(passes: i64, compressed_length: usize, checksum: u32, staged: &mut [u8; OUTPUT_CAPACITY]) -> usize {
    let mut used = 0;
    for byte in b"Huffbench passes=" { staged[used] = *byte; used += 1; }
    used = append_decimal(staged, used, passes as u32);
    for byte in b" compressed=" { staged[used] = *byte; used += 1; }
    used = append_decimal(staged, used, compressed_length as u32);
    for byte in b" checksum=" { staged[used] = *byte; used += 1; }
    used = append_decimal(staged, used, checksum);
    staged[used] = b'\n';
    used + 1
}

#[no_mangle]
pub unsafe extern "C" fn coyote_huffbench(passes: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(MIN_PASSES..=MAX_PASSES).contains(&passes) { return -1; }
    if output.is_null() { return -2; }
    let alphabet = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ012345";
    let mut data = [0_u8; DATA_BYTES];
    let mut seed = 1325_i64;
    for index in 0..DATA_BYTES { data[index] = alphabet[random4(&mut seed)]; }
    let mut compressed_length = 0;
    let mut checksum = 0_u32;
    for _ in 0..passes {
        match compdecomp(&mut data) { Some((length, sum)) => { compressed_length = length; checksum = sum; }, None => return -1 }
    }
    let mut staged = [0_u8; OUTPUT_CAPACITY];
    let used = format_output(passes, compressed_length, checksum, &mut staged);
    if output_capacity < used { return -2; }
    for index in 0..used { *output.add(index) = staged[index]; }
    used as i64
}
