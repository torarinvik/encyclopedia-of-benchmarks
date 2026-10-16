const MAX_DOCS: usize = 256;
const MAX_WORDS_PER_DOC: usize = 256;
const MAX_TOTAL_WORDS: usize = 4096;
const MAX_QUERY_TERMS: usize = 16;
const MAX_INPUT: usize = 4627;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn hashI64(hash: u64, value: i64) u64 {
    var result = hash;
    const bits: u64 = @bitCast(value);
    for (0..8) |byte_index| result = (result ^ @as(u64, @truncate(bits >> @intCast(byte_index * 8)))) *% FNV_PRIME;
    return result;
}

export fn inverted_index(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 3 or length > MAX_INPUT) return -1;
    const doc_count64 = values[0];
    if (doc_count64 < 0 or doc_count64 > MAX_DOCS) return -1;
    const doc_count: usize = @intCast(doc_count64);
    var seen_docs: [MAX_DOCS]bool = [_]bool{false} ** MAX_DOCS;
    var posting_heads: [65536]i32 = undefined;
    var posting_next: [MAX_TOTAL_WORDS]i32 = undefined;
    var posting_doc: [MAX_TOTAL_WORDS]u8 = undefined;
    for (0..65536) |word| posting_heads[word] = -1;
    var posting_count: usize = 0;
    var total_words: usize = 0;
    var cursor: usize = 1;

    for (0..doc_count) |_| {
        if (cursor > length or length - cursor < 2) return -1;
        const doc_id64 = values[cursor];
        const word_count64 = values[cursor + 1];
        cursor += 2;
        if (doc_id64 < 0 or doc_id64 >= MAX_DOCS or word_count64 < 1 or word_count64 > MAX_WORDS_PER_DOC) return -1;
        const doc_id: usize = @intCast(doc_id64);
        const word_count: usize = @intCast(word_count64);
        if (seen_docs[doc_id] or word_count > length - cursor or total_words > MAX_TOTAL_WORDS - word_count) return -1;
        seen_docs[doc_id] = true;
        total_words += word_count;
        for (0..word_count) |_| {
            const word64 = values[cursor];
            cursor += 1;
            if (word64 < 0 or word64 > 65535) return -1;
            const word_id: usize = @intCast(word64);
            var duplicate = false;
            var edge = posting_heads[word_id];
            while (edge >= 0) {
                const edge_index: usize = @intCast(edge);
                if (posting_doc[edge_index] == @as(u8, @intCast(doc_id))) { duplicate = true; break; }
                edge = posting_next[edge_index];
            }
            if (!duplicate) {
                if (posting_count >= MAX_TOTAL_WORDS) return -1;
                posting_doc[posting_count] = @intCast(doc_id);
                posting_next[posting_count] = posting_heads[word_id];
                posting_heads[word_id] = @intCast(posting_count);
                posting_count += 1;
            }
        }
    }
    if (cursor > length or length - cursor < 2) return -1;
    const operation = values[cursor];
    const term_count64 = values[cursor + 1];
    cursor += 2;
    if ((operation != 0 and operation != 1) or term_count64 < 1 or term_count64 > MAX_QUERY_TERMS or @as(usize, @intCast(term_count64)) != length - cursor) return -1;
    const term_count: usize = @intCast(term_count64);
    var terms: [MAX_QUERY_TERMS]usize = undefined;
    for (0..term_count) |i| {
        const term64 = values[cursor + i];
        if (term64 < 0 or term64 > 65535) return -1;
        terms[i] = @intCast(term64);
    }

    var result_flags: [MAX_DOCS]bool = undefined;
    var term_flags: [MAX_DOCS]bool = undefined;
    for (0..MAX_DOCS) |doc_id| result_flags[doc_id] = operation == 0 and seen_docs[doc_id];
    for (0..term_count) |t| {
        for (0..MAX_DOCS) |doc_id| term_flags[doc_id] = false;
        var edge = posting_heads[terms[t]];
        while (edge >= 0) {
            const edge_index: usize = @intCast(edge);
            term_flags[posting_doc[edge_index]] = true;
            edge = posting_next[edge_index];
        }
        for (0..MAX_DOCS) |doc_id| {
            if (operation == 0) result_flags[doc_id] = result_flags[doc_id] and term_flags[doc_id]
            else result_flags[doc_id] = result_flags[doc_id] or term_flags[doc_id];
        }
    }
    var result_ids: [MAX_DOCS]i64 = undefined;
    var result_count: usize = 0;
    for (0..MAX_DOCS) |doc_id| {
        if (result_flags[doc_id]) {
            result_ids[result_count] = @intCast(doc_id);
            result_count += 1;
        }
    }
    var hash = hashI64(FNV_OFFSET, @intCast(result_count));
    for (result_ids[0..result_count]) |doc_id| hash = hashI64(hash, doc_id);
    return @intCast(hash & 0x7fffffffffffffff);
}
