const MAX_DOMAIN: usize = 1024;
const MAX_LISTS: usize = 16;
const MAX_WORDS: usize = 16;

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn inverted_list_bitvector_intersection(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 258 {
        return -1;
    }
    let domain_value = *input;
    let list_count_value = *input.add(1);
    if !(1..=MAX_DOMAIN as i64).contains(&domain_value)
        || !(1..=MAX_LISTS as i64).contains(&list_count_value)
    {
        return -1;
    }

    let domain = domain_value as usize;
    let list_count = list_count_value as usize;
    let words_per_list = (domain + 63) / 64;
    if length != 2 + list_count * words_per_list {
        return -1;
    }

    let remainder = domain % 64;
    if remainder != 0 {
        let valid_mask = (1u64 << remainder) - 1;
        for list in 0..list_count {
            let final_index = 2 + list * words_per_list + words_per_list - 1;
            let final_word = *input.add(final_index) as u64;
            if final_word & !valid_mask != 0 {
                return -1;
            }
        }
    }

    let mut intersection = [0u64; MAX_WORDS];
    for word in 0..words_per_list {
        let mut combined = u64::MAX;
        for list in 0..list_count {
            let input_index = 2 + list * words_per_list + word;
            combined &= *input.add(input_index) as u64;
        }
        intersection[word] = combined;
    }

    let mut results = [0i64; MAX_DOMAIN];
    let mut result_count = 0usize;
    for document_id in 0..domain {
        let bit = 1u64 << (document_id % 64);
        if intersection[document_id / 64] & bit != 0 {
            results[result_count] = document_id as i64;
            result_count += 1;
        }
    }

    let output_bytes = (result_count + 1) * 8;
    if output.is_null() || output_capacity < output_bytes {
        return -2;
    }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    write_i64_le(output_slice, 0, result_count as i64);
    for index in 0..result_count {
        write_i64_le(output_slice, (index + 1) * 8, results[index]);
    }
    output_bytes as i64
}
