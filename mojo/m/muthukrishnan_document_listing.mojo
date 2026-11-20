const MAX_N: usize = 32
const MAX_DOCS: usize = 8
const MAX_Q: usize = 16
const MAX_INPUT: usize = 68
const MAX_OUTPUT: usize = 144
const LEVELS: usize = 6

def mdl_range_min(previous: view[i64], table: view[i32], logs: view[i32],
        lo: usize, hi: usize) -> usize:
    length: usize = hi - lo + 1
    level: usize = logs[length].usize()
    width: usize = 1 << level
    left: usize = table[level * MAX_N + lo].usize()
    right: usize = table[level * MAX_N + hi - width + 1].usize()
    if previous[left] < previous[right] or (previous[left] == previous[right] and left < right):
        return left
    return right

def mdl_report(lo: usize, hi: usize, query_lo: usize, previous: view[i64],
        documents: view[i64], table: view[i32], logs: view[i32],
        ranks: mutable view[usize], found_docs: mutable view[u8], count: mutable usize&):
    if lo > hi:
        return
    index: usize = mdl_range_min(previous, table, logs, lo, hi)
    if previous[index] >= query_lo.i64():
        return
    ranks[count] <- index
    found_docs[count] <- documents[index].u8()
    count <- count + 1
    if index > lo:
        mdl_report(lo, index - 1, query_lo, previous, documents, table, logs, ranks, found_docs, count)
    if index < hi:
        mdl_report(index + 1, hi, query_lo, previous, documents, table, logs, ranks, found_docs, count)

def mdl_impl(input: view[i64], output: mutable view[u8], output_capacity: usize) -> i64:
    input_length: usize = input.len()
    if input_length < 3 or input_length > MAX_INPUT:
        return -1
    n_value: i64 = input[0]
    docs_value: i64 = input[1]
    q_value: i64 = input[2]
    if n_value < 1 or n_value > MAX_N.i64() or docs_value < 1 or docs_value > MAX_DOCS.i64() or
        q_value < 1 or q_value > MAX_Q.i64():
        return -1
    n: usize = n_value.usize()
    docs: usize = docs_value.usize()
    q: usize = q_value.usize()
    if input_length != 3 + n + 2 * q:
        return -1

    documents: mutable i64[MAX_N] = zeroed
    previous: mutable i64[MAX_N] = zeroed
    last: mutable i64[MAX_DOCS] = zeroed
    for doc in 0..<docs:
        last[doc] <- -1
    for index in 0..<n:
        document: i64 = input[3 + index]
        if document < 0 or document >= docs_value:
            return -1
        documents[index] <- document
        previous[index] <- last[document.usize()]
        last[document.usize()] <- index.i64()
    for query in 0..<q:
        lo: i64 = input[3 + n + 2 * query]
        hi: i64 = input[4 + n + 2 * query]
        if lo < 0 or hi < lo or hi >= n_value:
            return -1

    logs: mutable i32[MAX_N + 1] = zeroed
    for size in 2..=n:
        logs[size] <- logs[size / 2] + 1
    table: mutable i32[LEVELS * MAX_N] = zeroed
    for index in 0..<n:
        table[index] <- index.i32()
    level_count: usize = logs[n].usize() + 1
    for level in 1..<level_count:
        width: usize = 1 << level
        half: usize = width / 2
        for start in 0..<(n - width + 1):
            left: usize = table[(level - 1) * MAX_N + start].usize()
            right: usize = table[(level - 1) * MAX_N + start + half].usize()
            if previous[left] < previous[right] or (previous[left] == previous[right] and left < right):
                table[level * MAX_N + start] <- left.i32()
            else:
                table[level * MAX_N + start] <- right.i32()

    staged: mutable u8[MAX_OUTPUT] = zeroed
    written: mutable usize = 0
    for query in 0..<q:
        lo: usize = input[3 + n + 2 * query].usize()
        hi: usize = input[4 + n + 2 * query].usize()
        count_at: usize = written
        written <- written + 1
        ranks: mutable usize[MAX_DOCS] = zeroed
        found_docs: mutable u8[MAX_DOCS] = zeroed
        count: mutable usize = 0
        mdl_report(lo, hi, lo, previous[0:n], documents[0:n], table[0:LEVELS * MAX_N],
            logs[0:MAX_N + 1], ranks[0:MAX_DOCS], found_docs[0:MAX_DOCS], count)
        for i in 1..<count:
            rank: usize = ranks[i]
            document: u8 = found_docs[i]
            j: mutable usize = i
            while j > 0 and ranks[j - 1] > rank:
                ranks[j] <- ranks[j - 1]
                found_docs[j] <- found_docs[j - 1]
                j <- j - 1
            ranks[j] <- rank
            found_docs[j] <- document
        staged[count_at] <- count.u8()
        for i in 0..<count:
            staged[written] <- found_docs[i]
            written <- written + 1
    if written > MAX_OUTPUT:
        return -1
    if output_capacity < written or output.len() < written:
        return -2
    for index in 0..<written:
        output[index] <- staged[index]
    written.i64()

export fn muthukrishnan_document_listing(input: i64&, length: usize,
        output: mutable u8&, output_capacity: usize) -> i64:
    if input.is_null() or length < 3 or length > MAX_INPUT:
        return -1
    frame: view[i64] = input[0:length]
    if output.is_null():
        scratch: mutable u8[1] = zeroed
        return mdl_impl(frame, scratch[0:0], 0)
    writable_length: usize = output_capacity
    if writable_length > MAX_OUTPUT:
        writable_length <- MAX_OUTPUT
    mdl_impl(frame, output[0:writable_length], output_capacity)
