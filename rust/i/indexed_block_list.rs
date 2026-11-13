const B: usize = 4;
const MAX_INITIAL: usize = 16;
const MAX_OPS: usize = 64;
const MAX_INSERTS: usize = 32;
const MAX_ACCESSES: usize = 32;
const MAX_NODES: usize = 16;
const MAX_ITEMS: usize = 48;
const MAX_PARSEABLE: usize = 179;

unsafe fn valid_input(input: *const i64, length: usize) -> Option<usize> {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE { return None; }
    let initial_arg = *input;
    if initial_arg < 0 || initial_arg > MAX_INITIAL as i64 { return None; }
    let initial = initial_arg as usize;
    if length < initial + 2 { return None; }
    for i in 0..initial { let value = *input.add(1 + i); if !(-1_000_000..=1_000_000).contains(&value) { return None; } }
    let raw_ops = *input.add(1 + initial);
    if raw_ops < 0 || raw_ops > MAX_OPS as i64 { return None; }
    let mut cursor = initial + 2;
    let mut size = initial;
    let mut inserts = 0;
    let mut accesses = 0;
    for _ in 0..raw_ops as usize {
        if cursor >= length { return None; }
        match *input.add(cursor) {
            0 => {
                if cursor + 3 > length { return None; }
                let index = *input.add(cursor + 1); let value = *input.add(cursor + 2);
                if index < 0 || index as u64 > size as u64 || !(-1_000_000..=1_000_000).contains(&value) { return None; }
                inserts += 1; if inserts > MAX_INSERTS { return None; }
                size += 1; cursor += 3;
            }
            1 => {
                if cursor + 2 > length { return None; }
                let index = *input.add(cursor + 1);
                if index < 0 || index as u64 >= size as u64 { return None; }
                accesses += 1; if accesses > MAX_ACCESSES { return None; }
                cursor += 2;
            }
            _ => return None,
        }
    }
    if cursor != length || size > MAX_ITEMS { None } else { Some(accesses) }
}

unsafe fn insert(blocks: &mut [[i64; 2 * B + 1]; MAX_NODES], sizes: &mut [usize; MAX_NODES],
                 next: &mut [i32; MAX_NODES], node_count: &mut usize, index: usize, value: i64) {
    let mut node = 0usize;
    let mut offset = 0usize;
    while next[node] >= 0 && index > offset + sizes[node] { offset += sizes[node]; node = next[node] as usize; }
    let local = index - offset;
    for j in (local..sizes[node]).rev() { blocks[node][j + 1] = blocks[node][j]; }
    blocks[node][local] = value; sizes[node] += 1;
    if sizes[node] > 2 * B {
        let fresh = *node_count; *node_count += 1;
        let start = sizes[node] - B;
        for j in 0..B { blocks[fresh][j] = blocks[node][start + j]; }
        sizes[fresh] = B; sizes[node] -= B;
        next[fresh] = next[node]; next[node] = fresh as i32;
    }
}

unsafe fn get(blocks: &[[i64; 2 * B + 1]; MAX_NODES], sizes: &[usize; MAX_NODES],
              next: &[i32; MAX_NODES], index: usize) -> i64 {
    let mut node = 0usize; let mut offset = 0usize;
    while index >= offset + sizes[node] { offset += sizes[node]; node = next[node] as usize; }
    blocks[node][index - offset]
}

#[no_mangle]
pub unsafe extern "C" fn indexed_block_list(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    let access_count = match valid_input(input, length) { Some(value) => value, None => return -1 };
    if access_count == 0 { return 0; }
    let required = 8 * access_count;
    if output.is_null() || capacity < required { return -2; }
    let mut blocks = [[0i64; 2 * B + 1]; MAX_NODES];
    let mut sizes = [0usize; MAX_NODES];
    let mut next = [-1i32; MAX_NODES];
    let mut node_count = 1usize;
    let initial = *input as usize;
    for i in 0..initial { insert(&mut blocks, &mut sizes, &mut next, &mut node_count, i, *input.add(1 + i)); }
    let operation_count = *input.add(1 + initial) as usize;
    let mut cursor = initial + 2; let mut answer_count = 0usize;
    let mut answers = [0i64; MAX_ACCESSES];
    for _ in 0..operation_count {
        let opcode = *input.add(cursor); let index = *input.add(cursor + 1) as usize;
        if opcode == 0 { insert(&mut blocks, &mut sizes, &mut next, &mut node_count, index, *input.add(cursor + 2)); cursor += 3; }
        else { answers[answer_count] = get(&blocks, &sizes, &next, index); answer_count += 1; cursor += 2; }
    }
    for i in 0..answer_count {
        let bytes = answers[i].to_le_bytes();
        for b in 0..8 { *output.add(8 * i + b) = bytes[b]; }
    }
    required as i64
}
