/// Build a bounded term-to-document table and rank one query by BM25.
pub export fn bm25_inverted_index(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > 2114 or values[0] < 0 or values[0] > 32) return -2;
    const document_count: usize = @intCast(values[0]);
    if (values[length - 1] < 1 or values[length - 1] > 255) return -2;
    const query = values[length - 1];
    var frequency: [32]i64 = @splat(0);
    var document_length: [32]i64 = @splat(0);
    var document_id: [32]i64 = @splat(0);
    var seen_ids: [256]bool = @splat(false);
    var offset: usize = 1;
    var total_terms: i64 = 0;
    for (0..document_count) |document| {
        if (offset + 2 > length - 1) return -2;
        const id = values[offset];
        const term_count_value = values[offset + 1];
        offset += 2;
        if (id < 0 or id > 255 or term_count_value < 0 or term_count_value > 64) return -2;
        const id_index: usize = @intCast(id);
        const term_count: usize = @intCast(term_count_value);
        if (seen_ids[id_index] or term_count > length - 1 - offset) return -2;
        seen_ids[id_index] = true;
        document_id[document] = id;
        document_length[document] = term_count_value;
        total_terms += term_count_value;
        for (0..term_count) |_| {
            const term_value = values[offset];
            offset += 1;
            if (term_value < 1 or term_value > 255) return -2;
            if (term_value == query) frequency[document] += 1;
        }
    }
    if (offset != length - 1) return -2;
    var result_id: [32]i64 = @splat(0);
    var result_tf: [32]i64 = @splat(0);
    var result_denominator: [32]i64 = @splat(0);
    var result_count: usize = 0;
    for (0..document_count) |document| {
        const tf = frequency[document];
        if (tf == 0) continue;
        const denominator = 8 * total_terms * tf + 3 * total_terms
            + 9 * @as(i64, @intCast(document_count)) * document_length[document];
        var position = result_count;
        while (position > 0) {
            const previous = position - 1;
            const left = tf * result_denominator[previous];
            const right = result_tf[previous] * denominator;
            if (left < right or (left == right and document_id[document] > result_id[previous])) break;
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
    if (result_count > output_capacity) return -2;
    for (0..result_count) |index| output[index] = @intCast(result_id[index]);
    return @intCast(result_count);
}
