use std::slice;

const MAX_TEXT: usize = 12;
const MAX_PATTERN: usize = 8;
const MAX_SIGMA: usize = 4;
const MAX_SUFFIXES: usize = MAX_TEXT + 1;
const MAX_NODES: usize = 2 * MAX_SUFFIXES - 1;
const MAX_INPUT: usize = 24;
const MAX_OUTPUT: usize = 16;

#[derive(Clone, Copy)]
struct Node {
    edge_start: usize,
    edge_length: usize,
    depth: usize,
    leaf_start: i32,
    child: [i32; 5],
    leaf_count: usize,
    sa_left: usize,
    sa_right: usize,
    sigma: bool,
    kind: u8,
    sigma_child_count: usize,
    sigma_child: [i32; 5],
    child_by_symbol: [i32; MAX_SIGMA],
    group_by_symbol: [i32; MAX_SIGMA],
    gap_left: [i32; 5],
    gap_right: [i32; 5],
    separator: i8,
    only_sigma_child: i32,
    left_interval: [i32; 2],
    right_interval: [i32; 2],
}

impl Node {
    const fn empty() -> Self {
        Self {
            edge_start: 0, edge_length: 0, depth: 0, leaf_start: -1,
            child: [-1; 5], leaf_count: 0, sa_left: 0, sa_right: 0,
            sigma: false, kind: 0, sigma_child_count: 0, sigma_child: [-1; 5],
            child_by_symbol: [-1; MAX_SIGMA], group_by_symbol: [-1; MAX_SIGMA],
            gap_left: [-1; 5], gap_right: [-1; 5], separator: -2,
            only_sigma_child: -1, left_interval: [-1; 2], right_interval: [-1; 2],
        }
    }
}

fn slot(symbol: i8) -> usize { (symbol + 1) as usize }

fn suffix_cmp(text: &[i8; MAX_SUFFIXES], length: usize, a: usize, b: usize) -> i32 {
    let mut offset = 0;
    while a + offset < length && b + offset < length {
        if text[a + offset] != text[b + offset] {
            return if text[a + offset] < text[b + offset] { -1 } else { 1 };
        }
        offset += 1;
    }
    if a + offset == length && b + offset == length { 0 }
    else if a + offset == length { -1 } else { 1 }
}

fn make_suffix_array(text: &[i8; MAX_SUFFIXES], length: usize) -> ([usize; MAX_SUFFIXES], [usize; MAX_SUFFIXES]) {
    let mut sa = [0; MAX_SUFFIXES];
    let mut rank = [0; MAX_SUFFIXES];
    for i in 0..length { sa[i] = i; }
    for i in 1..length {
        let item = sa[i];
        let mut j = i;
        while j > 0 && suffix_cmp(text, length, item, sa[j - 1]) < 0 {
            sa[j] = sa[j - 1];
            j -= 1;
        }
        sa[j] = item;
    }
    for i in 0..length { rank[sa[i]] = i; }
    (sa, rank)
}

fn insert_suffix(nodes: &mut [Node; MAX_NODES], node_count: &mut usize,
                 text: &[i8; MAX_SUFFIXES], text_length: usize, start: usize) {
    let mut current = 0;
    let mut position = start;
    while position < text_length {
        let sym = text[position];
        let child_id = nodes[current].child[slot(sym)];
        if child_id < 0 {
            let id = *node_count;
            *node_count += 1;
            let edge_length = text_length - position;
            nodes[id] = Node { edge_start: position, edge_length,
                depth: nodes[current].depth + edge_length, leaf_start: start as i32,
                ..Node::empty() };
            nodes[current].child[slot(sym)] = id as i32;
            return;
        }
        let child = child_id as usize;
        let mut common = 0;
        while common < nodes[child].edge_length && position + common < text_length &&
              text[position + common] == text[nodes[child].edge_start + common] {
            common += 1;
        }
        if common == nodes[child].edge_length {
            position += common;
            current = child;
            continue;
        }
        let split = *node_count;
        *node_count += 1;
        let old_start = nodes[child].edge_start;
        nodes[split] = Node { edge_start: old_start, edge_length: common,
            depth: nodes[current].depth + common, ..Node::empty() };
        nodes[current].child[slot(sym)] = split as i32;
        nodes[child].edge_start += common;
        nodes[child].edge_length -= common;
        nodes[split].child[slot(text[nodes[child].edge_start])] = child as i32;
        let new_start = position + common;
        let id = *node_count;
        *node_count += 1;
        let new_length = text_length - new_start;
        nodes[id] = Node { edge_start: new_start, edge_length: new_length,
            depth: nodes[split].depth + new_length, leaf_start: start as i32,
            ..Node::empty() };
        nodes[split].child[slot(text[new_start])] = id as i32;
        return;
    }
}

fn summarize(nodes: &mut [Node; MAX_NODES], id: usize, rank: &[usize; MAX_SUFFIXES], sigma: usize) {
    if nodes[id].leaf_start >= 0 {
        nodes[id].leaf_count = 1;
        nodes[id].sa_left = rank[nodes[id].leaf_start as usize];
        nodes[id].sa_right = nodes[id].sa_left;
        return;
    }
    let mut children = [0usize; 5];
    let mut count = 0;
    for symbol in -1..(sigma as i8) {
        let child = nodes[id].child[slot(symbol)];
        if child >= 0 { children[count] = child as usize; count += 1; }
    }
    let mut leaf_count = 0;
    let mut left = MAX_SUFFIXES;
    let mut right = 0;
    for child in children[..count].iter().copied() {
        summarize(nodes, child, rank, sigma);
        leaf_count += nodes[child].leaf_count;
        left = left.min(nodes[child].sa_left);
        right = right.max(nodes[child].sa_right);
    }
    nodes[id].leaf_count = leaf_count;
    nodes[id].sa_left = left;
    nodes[id].sa_right = right;
}

fn build_tray(nodes: &mut [Node; MAX_NODES], node_count: usize, sigma: usize,
              text: &[i8; MAX_SUFFIXES]) {
    for node in nodes.iter_mut().take(node_count) { node.sigma = node.leaf_count >= sigma; }
    for id in 0..node_count {
        if !nodes[id].sigma { continue; }
        let mut children = [0usize; 5];
        let mut child_count = 0;
        for symbol in -1..(sigma as i8) {
            let child = nodes[id].child[slot(symbol)];
            if child >= 0 { children[child_count] = child as usize; child_count += 1; }
        }
        let mut sig = [0usize; 5];
        let mut sig_count = 0;
        for child in children[..child_count].iter().copied() {
            if nodes[child].sigma { sig[sig_count] = child; sig_count += 1; }
        }
        nodes[id].sigma_child_count = sig_count;
        for i in 0..sig_count { nodes[id].sigma_child[i] = sig[i] as i32; }
        if sig_count == 0 { nodes[id].kind = 3; continue; }
        if sig_count == 1 {
            let child = sig[0];
            nodes[id].kind = 2;
            nodes[id].only_sigma_child = child as i32;
            nodes[id].separator = text[nodes[child].edge_start];
            let mut left = [0usize; 5]; let mut right = [0usize; 5];
            let mut lc = 0; let mut rc = 0; let mut after = false;
            for item in children[..child_count].iter().copied() {
                if item == child { after = true; continue; }
                if !nodes[item].sigma {
                    if after { right[rc] = item; rc += 1; }
                    else { left[lc] = item; lc += 1; }
                }
            }
            if lc > 0 {
                nodes[id].left_interval = [nodes[left[0]].sa_left as i32,
                                           nodes[left[lc - 1]].sa_right as i32];
            }
            if rc > 0 {
                nodes[id].right_interval = [nodes[right[0]].sa_left as i32,
                                            nodes[right[rc - 1]].sa_right as i32];
            }
            continue;
        }
        nodes[id].kind = 1;
        let mut groups = [[0usize; 5]; 6];
        let mut sizes = [0usize; 6];
        let mut gap = 0;
        for item in children[..child_count].iter().copied() {
            if nodes[item].sigma { gap += 1; }
            else { groups[gap][sizes[gap]] = item; sizes[gap] += 1; }
        }
        nodes[id].gap_count = sig_count + 1;
        for g in 0..=sig_count {
            if sizes[g] > 0 {
                nodes[id].gap_left[g] = nodes[groups[g][0]].sa_left as i32;
                nodes[id].gap_right[g] = nodes[groups[g][sizes[g] - 1]].sa_right as i32;
            }
        }
        for symbol in 0..sigma {
            let mut exact = -1;
            let mut preceding = 0;
            for child in sig[..sig_count].iter().copied() {
                let first = text[nodes[child].edge_start] as usize;
                if first == symbol { exact = child as i32; break; }
                if first < symbol { preceding += 1; }
            }
            if exact >= 0 { nodes[id].child_by_symbol[symbol] = exact; }
            else if sizes[preceding] > 0 { nodes[id].group_by_symbol[symbol] = preceding as i32; }
        }
    }
}

fn compare_pattern(text: &[i8; MAX_SUFFIXES], text_length: usize, suffix: usize,
                   pattern: &[i8; MAX_PATTERN], q: usize, from: usize) -> (i32, usize) {
    let mut i = from;
    while i < q && suffix + i < text_length {
        if text[suffix + i] != pattern[i] {
            return (if text[suffix + i] < pattern[i] { -1 } else { 1 }, i);
        }
        i += 1;
    }
    (if i == q { 1 } else { -1 }, i)
}

fn interval_search(text: &[i8; MAX_SUFFIXES], text_length: usize,
                   pattern: &[i8; MAX_PATTERN], q: usize,
                   sa: &[usize; MAX_SUFFIXES], lo: usize, hi: usize,
                   known: usize) -> i32 {
    let mut low = lo as isize - 1;
    let mut high = hi as isize + 1;
    let mut low_lcp = known;
    let mut high_lcp = known;
    while high - low > 1 {
        let middle = ((low + high) / 2) as usize;
        let (comparison, lcp) = compare_pattern(text, text_length, sa[middle], pattern, q,
                                                low_lcp.min(high_lcp));
        if comparison < 0 { low = middle as isize; low_lcp = lcp; }
        else { high = middle as isize; high_lcp = lcp; }
    }
    if high > hi as isize { return -1; }
    let start = sa[high as usize];
    if start + q > text_length { return -1; }
    for i in 0..q { if text[start + i] != pattern[i] { return -1; } }
    start as i32
}

fn tray_query(text: &[i8; MAX_SUFFIXES], text_length: usize,
              pattern: &[i8; MAX_PATTERN], q: usize, sigma: usize,
              sa: &[usize; MAX_SUFFIXES], nodes: &[Node; MAX_NODES]) -> i32 {
    let mut current = 0usize;
    let mut matched = 0usize;
    loop {
        let node = nodes[current];
        if matched == q { return sa[node.sa_left] as i32; }
        if !node.sigma || node.kind == 3 {
            return interval_search(text, text_length, pattern, q, sa,
                                   node.sa_left, node.sa_right, matched);
        }
        let symbol = pattern[matched] as usize;
        let mut next = -1i32;
        let mut interval = [-1i32; 2];
        if node.kind == 1 {
            next = node.child_by_symbol[symbol];
            if next < 0 {
                let group = node.group_by_symbol[symbol];
                if group < 0 { return -1; }
                interval = [node.gap_left[group as usize], node.gap_right[group as usize]];
            }
        } else {
            next = node.only_sigma_child;
            if symbol as i8 != node.separator {
                interval = if (symbol as i8) < node.separator { node.left_interval } else { node.right_interval };
                if interval[0] < 0 { return -1; }
            }
        }
        if interval[0] >= 0 {
            return interval_search(text, text_length, pattern, q, sa,
                                   interval[0] as usize, interval[1] as usize, matched);
        }
        if next < 0 { return -1; }
        let child = nodes[next as usize];
        let representative = sa[child.sa_left];
        let mut edge_position = node.depth;
        while matched < q && edge_position < child.depth {
            if text[representative + edge_position] != pattern[matched] { return -1; }
            matched += 1;
            edge_position += 1;
        }
        if matched == q { return sa[child.sa_left] as i32; }
        if edge_position != child.depth { return -1; }
        current = next as usize;
    }
}

unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (i, byte) in bytes.iter().enumerate() { *output.add(offset + i) = *byte; }
}

#[no_mangle]
pub unsafe extern "C" fn suffix_tray_pattern_query(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = slice::from_raw_parts(input, length);
    let sigma64 = values[0]; let n64 = values[1]; let q64 = values[2];
    if !(2..=MAX_SIGMA as i64).contains(&sigma64) || !(1..=MAX_TEXT as i64).contains(&n64) ||
       !(1..=MAX_PATTERN as i64).contains(&q64) { return -1; }
    let sigma = sigma64 as usize; let n = n64 as usize; let q = q64 as usize;
    if length != 3 + n + q { return -1; }
    let mut text = [-1i8; MAX_SUFFIXES];
    let mut pattern = [0i8; MAX_PATTERN];
    for i in 0..n {
        if values[3 + i] < 0 || values[3 + i] >= sigma64 { return -1; }
        text[i] = values[3 + i] as i8;
    }
    for i in 0..q {
        if values[3 + n + i] < 0 || values[3 + n + i] >= sigma64 { return -1; }
        pattern[i] = values[3 + n + i] as i8;
    }
    if output.is_null() || capacity < MAX_OUTPUT { return -2; }

    let (sa, rank) = make_suffix_array(&text, n + 1);
    let mut nodes = [Node::empty(); MAX_NODES];
    let mut node_count = 1usize;
    for start in 0..=n { insert_suffix(&mut nodes, &mut node_count, &text, n + 1, start); }
    summarize(&mut nodes, 0, &rank, sigma);
    build_tray(&mut nodes, node_count, sigma, &text);
    let found = tray_query(&text, n + 1, &pattern, q, sigma, &sa, &nodes);
    put_i64_le(output, 0, if found < 0 { 0 } else { 1 });
    put_i64_le(output, 8, found as i64);
    MAX_OUTPUT as i64
}
