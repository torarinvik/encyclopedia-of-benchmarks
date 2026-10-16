const MAX_DOCS: usize = 256;
const MAX_WORDS_PER_DOC: usize = 256;
const MAX_TOTAL_WORDS: usize = 4096;
const MAX_QUERY_TERMS: usize = 16;
const MAX_INPUT: usize = 4627;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

fn hash_i64(mut hash: u64, value: i64) -> u64 {
    for byte in value.to_le_bytes() { hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME); }
    hash
}

#[no_mangle]
pub extern "C" fn inverted_index(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let a = unsafe { std::slice::from_raw_parts(input, length) };
    let doc_count64 = a[0];
    if doc_count64 < 0 || doc_count64 > MAX_DOCS as i64 { return -1; }
    let doc_count = doc_count64 as usize;
    let mut seen_docs = [false; MAX_DOCS];
    let mut posting_heads = [-1i32; 65536];
    let mut posting_next = [-1i32; MAX_TOTAL_WORDS];
    let mut posting_doc = [0u8; MAX_TOTAL_WORDS];
    let mut posting_count = 0usize;
    let mut total_words = 0usize;
    let mut cursor = 1usize;

    for _ in 0..doc_count {
        if cursor > length || length - cursor < 2 { return -1; }
        let doc_id64 = a[cursor];
        let word_count64 = a[cursor + 1];
        cursor += 2;
        if doc_id64 < 0 || doc_id64 >= MAX_DOCS as i64 || word_count64 < 1 || word_count64 > MAX_WORDS_PER_DOC as i64 { return -1; }
        let doc_id = doc_id64 as usize;
        let word_count = word_count64 as usize;
        if seen_docs[doc_id] || word_count > length - cursor || total_words > MAX_TOTAL_WORDS - word_count { return -1; }
        seen_docs[doc_id] = true;
        total_words += word_count;
        for _ in 0..word_count {
            let raw_word = a[cursor];
            cursor += 1;
            if !(0..=65535).contains(&raw_word) { return -1; }
            let word_id = raw_word as usize;
            let mut duplicate = false;
            let mut edge = posting_heads[word_id];
            while edge >= 0 {
                let edge_index = edge as usize;
                if posting_doc[edge_index] as usize == doc_id { duplicate = true; break; }
                edge = posting_next[edge_index];
            }
            if !duplicate {
                if posting_count >= MAX_TOTAL_WORDS { return -1; }
                posting_doc[posting_count] = doc_id as u8;
                posting_next[posting_count] = posting_heads[word_id];
                posting_heads[word_id] = posting_count as i32;
                posting_count += 1;
            }
        }
    }
    if cursor > length || length - cursor < 2 { return -1; }
    let operation = a[cursor];
    let term_count64 = a[cursor + 1];
    cursor += 2;
    if (operation != 0 && operation != 1) || term_count64 < 1 || term_count64 > MAX_QUERY_TERMS as i64 || term_count64 as usize != length - cursor { return -1; }
    let term_count = term_count64 as usize;
    let mut terms = [0usize; MAX_QUERY_TERMS];
    for i in 0..term_count {
        let raw_term = a[cursor + i];
        if !(0..=65535).contains(&raw_term) { return -1; }
        terms[i] = raw_term as usize;
    }

    let mut result_flags = [false; MAX_DOCS];
    let mut term_flags = [false; MAX_DOCS];
    for doc_id in 0..MAX_DOCS { result_flags[doc_id] = operation == 0 && seen_docs[doc_id]; }
    for &term in &terms[..term_count] {
        term_flags.fill(false);
        let mut edge = posting_heads[term];
        while edge >= 0 {
            let edge_index = edge as usize;
            term_flags[posting_doc[edge_index] as usize] = true;
            edge = posting_next[edge_index];
        }
        for doc_id in 0..MAX_DOCS {
            if operation == 0 { result_flags[doc_id] &= term_flags[doc_id]; }
            else { result_flags[doc_id] |= term_flags[doc_id]; }
        }
    }
    let mut result_ids = [0i64; MAX_DOCS];
    let mut result_count = 0usize;
    for doc_id in 0..MAX_DOCS {
        if result_flags[doc_id] { result_ids[result_count] = doc_id as i64; result_count += 1; }
    }
    let mut hash = hash_i64(FNV_OFFSET, result_count as i64);
    for &doc_id in &result_ids[..result_count] { hash = hash_i64(hash, doc_id); }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}
