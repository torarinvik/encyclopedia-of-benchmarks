/// Build a bounded term-to-document table and rank one query by BM25.
#[no_mangle]
pub extern "C" fn bm25_inverted_index(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > 2114 {
        return -2;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if !(0..=32).contains(&values[0]) {
        return -2;
    }
    let document_count = values[0] as usize;
    if !(1..=255).contains(&values[length - 1]) {
        return -2;
    }
    let query = values[length - 1];
    let mut frequency = [0_i64; 32];
    let mut document_length = [0_i64; 32];
    let mut document_id = [0_i64; 32];
    let mut seen_ids = [false; 256];
    let mut offset = 1;
    let mut total_terms = 0_i64;
    for document in 0..document_count {
        if offset + 2 > length - 1 {
            return -2;
        }
        let id = values[offset];
        let term_count_value = values[offset + 1];
        offset += 2;
        if !(0..=255).contains(&id) || !(0..=64).contains(&term_count_value) {
            return -2;
        }
        let id_index = id as usize;
        let term_count = term_count_value as usize;
        if seen_ids[id_index] || term_count > length - 1 - offset {
            return -2;
        }
        seen_ids[id_index] = true;
        document_id[document] = id;
        document_length[document] = term_count_value;
        total_terms += term_count_value;
        for _ in 0..term_count {
            let term_value = values[offset];
            offset += 1;
            if !(1..=255).contains(&term_value) {
                return -2;
            }
            if term_value == query {
                frequency[document] += 1;
            }
        }
    }
    if offset != length - 1 {
        return -2;
    }

    let mut result_id = [0_i64; 32];
    let mut result_tf = [0_i64; 32];
    let mut result_denominator = [0_i64; 32];
    let mut result_count = 0;
    for document in 0..document_count {
        let tf = frequency[document];
        if tf == 0 {
            continue;
        }
        let denominator = 8 * total_terms * tf
            + 3 * total_terms
            + 9 * document_count as i64 * document_length[document];
        let mut position = result_count;
        while position > 0 {
            let previous = position - 1;
            let left = tf * result_denominator[previous];
            let right = result_tf[previous] * denominator;
            if left < right || (left == right && document_id[document] > result_id[previous]) {
                break;
            }
            result_id[position] = result_id[previous];
            result_tf[position] = result_tf[previous];
            result_denominator[position] = result_denominator[previous];
            position -= 1;
        }
        result_id[position] = document_id[document];
        result_tf[position] = tf;
        result_denominator[position] = denominator;
        result_count += 1;
    }
    if result_count > output_capacity || (result_count != 0 && output.is_null()) {
        return -2;
    }
    for index in 0..result_count {
        unsafe { *output.add(index) = result_id[index] as u8; }
    }
    result_count as i64
}
