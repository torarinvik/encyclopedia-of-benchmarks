const MAX_VERTICES: usize = 8;
const MAX_EDGES: i64 = 64;
const MAX_OPERATION_COUNT: i64 = 24;
const MAX_OPERATIONS: usize = 24;

fn put_i64(output: &mut [u8], word: usize, value: i64) {
    output[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

fn vertex_index(vertices: &[i64; MAX_VERTICES], count: usize, value: i64) -> Option<usize> {
    (0..count).find(|&index| vertices[index] == value)
}

fn remove_vertex(vertices: &mut [i64; MAX_VERTICES], matrix: &mut [i64; MAX_VERTICES * MAX_VERTICES], count: &mut usize, index: usize) {
    let old_count = *count;
    for row in index..old_count - 1 {
        vertices[row] = vertices[row + 1];
        for column in 0..old_count {
            matrix[row * MAX_VERTICES + column] = matrix[(row + 1) * MAX_VERTICES + column];
        }
    }
    for row in 0..old_count - 1 {
        for column in index..old_count - 1 {
            matrix[row * MAX_VERTICES + column] = matrix[row * MAX_VERTICES + column + 1];
        }
    }
    for i in 0..old_count {
        matrix[(old_count - 1) * MAX_VERTICES + i] = 0;
        matrix[i * MAX_VERTICES + old_count - 1] = 0;
    }
    *count = old_count - 1;
}

#[no_mangle]
pub unsafe extern "C" fn graph_adjacency_matrix(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let directed = values[0];
    let count_value = values[1];
    if !(directed == 0 || directed == 1) || !(0..=8).contains(&count_value) { return -1; }
    let mut count = count_value as usize;
    if length < 3 + count { return -1; }
    let mut vertices = [0i64; MAX_VERTICES];
    let mut matrix = [0i64; MAX_VERTICES * MAX_VERTICES];
    let mut position = 2usize;
    for i in 0..count {
        let value = values[position];
        position += 1;
        if !(0..32).contains(&value) || vertex_index(&vertices, i, value).is_some() { return -1; }
        vertices[i] = value;
    }
    if position >= length { return -1; }
    let edge_count = values[position];
    position += 1;
    if !(0..=MAX_EDGES).contains(&edge_count) || length < position + 2 * edge_count as usize + 1 { return -1; }
    for _ in 0..edge_count as usize {
        let (source_value, destination_value) = (values[position], values[position + 1]);
        position += 2;
        if !(0..32).contains(&source_value) || !(0..32).contains(&destination_value) { return -1; }
        let (Some(source), Some(destination)) = (
            vertex_index(&vertices, count, source_value),
            vertex_index(&vertices, count, destination_value),
        ) else { return -1; };
        if matrix[source * MAX_VERTICES + destination] != 0 { return -1; }
        matrix[source * MAX_VERTICES + destination] = 1;
        if directed == 0 { matrix[destination * MAX_VERTICES + source] = 1; }
    }
    let operation_count_value = values[position];
    position += 1;
    if !(0..=MAX_OPERATION_COUNT).contains(&operation_count_value)
        || length != position + 3 * operation_count_value as usize { return -1; }
    let operation_count = operation_count_value as usize;
    let mut results = [0i64; MAX_OPERATIONS];
    for operation_index in 0..operation_count {
        let (operation, a, b) = (values[position], values[position + 1], values[position + 2]);
        position += 3;
        if operation == 0 {
            if !(0..32).contains(&a) || b != 0 || count >= MAX_VERTICES || vertex_index(&vertices, count, a).is_some() { return -1; }
            for i in 0..MAX_VERTICES {
                matrix[i * MAX_VERTICES + count] = 0;
                matrix[count * MAX_VERTICES + i] = 0;
            }
            vertices[count] = a;
            count += 1;
            results[operation_index] = 1;
        } else if operation == 1 {
            if !(0..32).contains(&a) || b != 0 { return -1; }
            let Some(removed) = vertex_index(&vertices, count, a) else { return -1; };
            remove_vertex(&mut vertices, &mut matrix, &mut count, removed);
            results[operation_index] = 1;
        } else if operation == 2 || operation == 3 || operation == 5 {
            if !(0..32).contains(&a) || !(0..32).contains(&b) { return -1; }
            let (Some(source), Some(destination)) = (
                vertex_index(&vertices, count, a), vertex_index(&vertices, count, b),
            ) else { return -1; };
            let cell = source * MAX_VERTICES + destination;
            let present = matrix[cell] != 0;
            if operation == 5 {
                results[operation_index] = if present { 1 } else { 0 };
            } else if operation == 2 {
                if present { return -1; }
                matrix[cell] = 1;
                if directed == 0 { matrix[destination * MAX_VERTICES + source] = 1; }
                results[operation_index] = 1;
            } else {
                if !present { return -1; }
                matrix[cell] = 0;
                if directed == 0 { matrix[destination * MAX_VERTICES + source] = 0; }
                results[operation_index] = 1;
            }
        } else if operation == 4 {
            if !(0..32).contains(&a) || b != 0 { return -1; }
            results[operation_index] = if vertex_index(&vertices, count, a).is_some() { 1 } else { 0 };
        } else if operation == 6 {
            if a != 0 || b != 0 { return -1; }
            count = 0;
            matrix.fill(0);
            results[operation_index] = 1;
        } else { return -1; }
    }

    let words = 2 + operation_count + count + count * count;
    if output.is_null() || capacity < words * 8 { return -2; }
    let destination = std::slice::from_raw_parts_mut(output, words * 8);
    let mut word = 0usize;
    put_i64(destination, word, operation_count as i64); word += 1;
    for &result in &results[..operation_count] { put_i64(destination, word, result); word += 1; }
    put_i64(destination, word, count as i64); word += 1;
    for &vertex in &vertices[..count] { put_i64(destination, word, vertex); word += 1; }
    for row in 0..count {
        for column in 0..count { put_i64(destination, word, matrix[row * MAX_VERTICES + column]); word += 1; }
    }
    (words * 8) as i64
}
