const MAX_TEXT: usize = 64;
const MAX_NODES: usize = MAX_TEXT + 2;
const ALPHABET: usize = 4;

#[derive(Clone, Copy)]
struct Node {
    length: i32,
    suffix_link: usize,
    difference: i32,
    series_link: usize,
    series_best: i32,
    series_start: usize,
    next: [usize; ALPHABET],
}

const EMPTY_NODE: Node = Node {
    length: 0,
    suffix_link: 1,
    difference: 0,
    series_link: 1,
    series_best: 0,
    series_start: 0,
    next: [0; ALPHABET],
};

fn find_extendable(nodes: &[Node; MAX_NODES], text: &[usize], position: usize, start: usize) -> usize {
    let mut node = start;
    loop {
        let preceding = position as i32 - 1 - nodes[node].length;
        if preceding >= 0 && text[preceding as usize] == text[position] { return node; }
        node = nodes[node].suffix_link;
    }
}

fn put_i64(output: &mut [u8], value: i64) {
    output.copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn palindromic_partition_series_links(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_TEXT + 2).contains(&length) { return -1; }
    let packed = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_TEXT as i64).contains(&packed[0]) { return -1; }
    let n = packed[0] as usize;
    if length != n + 1 { return -1; }
    let mut text = [0usize; MAX_TEXT];
    for position in 0..n {
        if !(0..ALPHABET as i64).contains(&packed[position + 1]) { return -1; }
        text[position] = packed[position + 1] as usize;
    }

    let mut nodes = [EMPTY_NODE; MAX_NODES];
    nodes[0].length = 0;
    nodes[0].suffix_link = 1;
    nodes[1].length = -1;
    nodes[1].suffix_link = 1;
    let mut node_count = 2usize;
    let mut last = 0usize;
    let mut dp = [MAX_TEXT as i32 + 1; MAX_TEXT + 1];
    let mut predecessor = [0usize; MAX_TEXT + 1];
    dp[0] = 0;

    for position in 0..n {
        let end = position + 1;
        let symbol = text[position];
        let parent = find_extendable(&nodes, &text[..n], position, last);
        let mut next = nodes[parent].next[symbol];
        if next == 0 {
            next = node_count;
            node_count += 1;
            nodes[next].length = nodes[parent].length + 2;
            nodes[next].suffix_link = 0;
            nodes[parent].next[symbol] = next;
            if nodes[next].length == 1 {
                nodes[next].suffix_link = 0;
            } else {
                let suffix_parent = find_extendable(&nodes, &text[..n], position, nodes[parent].suffix_link);
                nodes[next].suffix_link = nodes[suffix_parent].next[symbol];
            }
            let fail = nodes[next].suffix_link;
            nodes[next].difference = nodes[next].length - nodes[fail].length;
            nodes[next].series_link = if nodes[next].difference == nodes[fail].difference {
                nodes[fail].series_link
            } else {
                fail
            };
        }
        last = next;

        let mut best_value = MAX_TEXT as i32 + 1;
        let mut best_start = end;
        let mut node = last;
        while nodes[node].length > 0 {
            let start = (end as i32 - nodes[nodes[node].series_link].length - nodes[node].difference) as usize;
            nodes[node].series_best = dp[start];
            nodes[node].series_start = start;
            let fail = nodes[node].suffix_link;
            if nodes[node].difference == nodes[fail].difference &&
                (nodes[fail].series_best < nodes[node].series_best ||
                 nodes[fail].series_best == nodes[node].series_best &&
                 nodes[fail].series_start < nodes[node].series_start) {
                nodes[node].series_best = nodes[fail].series_best;
                nodes[node].series_start = nodes[fail].series_start;
            }
            let candidate = nodes[node].series_best + 1;
            if candidate < best_value ||
                candidate == best_value && nodes[node].series_start < best_start {
                best_value = candidate;
                best_start = nodes[node].series_start;
            }
            node = nodes[node].series_link;
        }
        dp[end] = best_value;
        predecessor[end] = best_start;
    }

    let mut reverse_pieces = [0usize; MAX_TEXT];
    let mut piece_count = 0usize;
    let mut end = n;
    while end > 0 {
        reverse_pieces[piece_count] = end - predecessor[end];
        piece_count += 1;
        end = predecessor[end];
    }
    let mut words = [0i64; MAX_TEXT + 1];
    let mut word_count = 0usize;
    words[word_count] = piece_count as i64;
    word_count += 1;
    for index in 0..piece_count {
        words[word_count] = reverse_pieces[piece_count - 1 - index] as i64;
        word_count += 1;
    }
    let bytes = word_count * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let encoded = std::slice::from_raw_parts_mut(output, bytes);
    for index in 0..word_count {
        put_i64(&mut encoded[index * 8..(index + 1) * 8], words[index]);
    }
    bytes as i64
}
