const MAX_N: usize = 64;
const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 258;

fn block_size_for(n: usize) -> usize {
    let mut block_size = 1;
    while (block_size + 1) * (block_size + 1) <= n {
        block_size += 1;
    }
    block_size
}

fn query_sum(elements: &[i64; 64], blocks: &[i64; 64], block_size: usize,
             start: usize, end: usize) -> i64 {
    let first_index_next_block = ((start / block_size) + 1) * block_size;
    let mut sum = elements[start];
    if first_index_next_block > end {
        for index in start + 1..end {
            sum += elements[index];
        }
    } else {
        for index in start + 1..first_index_next_block {
            sum += elements[index];
        }
        let end_block = end / block_size;
        for block in first_index_next_block / block_size..end_block {
            sum += blocks[block];
        }
        for index in end_block * block_size..end {
            sum += elements[index];
        }
    }
    sum
}

#[no_mangle]
pub unsafe extern "C" fn sqrt_decomposition_range_sum(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let n_value = *input;
    if n_value < 1 || n_value > MAX_N as i64 {
        return -1;
    }
    let n = n_value as usize;
    if length < n + 2 {
        return -1;
    }
    let operation_count_value = *input.add(n + 1);
    if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS as i64 {
        return -1;
    }
    let operation_count = operation_count_value as usize;
    if length != 2 + n + 3 * operation_count {
        return -1;
    }

    let mut elements = [0i64; 64];
    for index in 0..n {
        let value = *input.add(index + 1);
        if !(-1000..=1000).contains(&value) {
            return -1;
        }
        elements[index] = value;
    }
    let operations_start = n + 2;
    let mut query_count = 0usize;
    for operation in 0..operation_count {
        let offset = operations_start + 3 * operation;
        let kind = *input.add(offset);
        let first = *input.add(offset + 1);
        let second = *input.add(offset + 2);
        if kind == 0 {
            if first < 0 || first >= second || second > n as i64 {
                return -1;
            }
            query_count += 1;
        } else if kind == 1 {
            if first < 0 || first >= n as i64 || !(-1000..=1000).contains(&second) {
                return -1;
            }
        } else {
            return -1;
        }
    }

    let output_bytes = query_count * 8;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    let block_size = block_size_for(n);
    let mut blocks = [0i64; 64];
    for index in 0..n {
        let block = index / block_size;
        if index % block_size == 0 {
            blocks[block] = elements[index];
        } else {
            blocks[block] += elements[index];
        }
    }

    let mut output_offset = 0usize;
    for operation in 0..operation_count {
        let offset = operations_start + 3 * operation;
        let kind = *input.add(offset);
        let first = *input.add(offset + 1) as usize;
        let second = *input.add(offset + 2);
        if kind == 0 {
            let sum = query_sum(&elements, &blocks, block_size, first, second as usize);
            std::ptr::copy_nonoverlapping(sum.to_le_bytes().as_ptr(), output.add(output_offset), 8);
            output_offset += 8;
        } else {
            let block = first / block_size;
            blocks[block] = blocks[block] - elements[first] + second;
            elements[first] = second;
        }
    }
    output_bytes as i64
}
