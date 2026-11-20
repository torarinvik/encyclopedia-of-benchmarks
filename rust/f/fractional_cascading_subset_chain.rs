const MAX_LEN: usize = 147;
const NO_SUCCESSOR: i64 = 34;

#[no_mangle]
pub unsafe extern "C" fn fractional_cascading_subset_chain(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_LEN { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let (m, q) = (words[0], words[1]);
    if !(2..=8).contains(&m) || !(1..=8).contains(&q) { return -1; }
    let (m, q) = (m as usize, q as usize);
    let mut catalogs: Vec<Vec<i64>> = Vec::with_capacity(m);
    let mut cursor = 2;
    for _ in 0..m {
        if cursor >= length || !(1..=16).contains(&words[cursor]) { return -1; }
        let n = words[cursor] as usize;
        cursor += 1;
        if cursor + n > length { return -1; }
        let catalog = words[cursor..cursor + n].to_vec();
        cursor += n;
        if catalog.iter().any(|&key| !(-16..=16).contains(&key))
            || catalog.windows(2).any(|pair| pair[0] >= pair[1]) { return -1; }
        if let Some(parent) = catalogs.last() {
            let mut parent_pos = 0;
            for key in &catalog {
                while parent_pos < parent.len() && parent[parent_pos] < *key { parent_pos += 1; }
                if parent_pos == parent.len() || parent[parent_pos] != *key { return -1; }
                parent_pos += 1;
            }
        }
        catalogs.push(catalog);
    }
    if cursor + q != length { return -1; }
    let queries = &words[cursor..];
    if queries.iter().any(|&key| !(-17..=17).contains(&key)) { return -1; }

    let mut bridges = Vec::with_capacity(m - 1);
    for pair in catalogs.windows(2) {
        let (parent, child) = (&pair[0], &pair[1]);
        let mut child_pos = 0;
        let mut bridge = Vec::with_capacity(parent.len() + 1);
        for &key in parent {
            while child_pos < child.len() && child[child_pos] < key { child_pos += 1; }
            bridge.push(child_pos);
        }
        bridge.push(child.len());
        bridges.push(bridge);
    }

    let mut checksum = 0i64;
    for (query_index, &key) in queries.iter().enumerate() {
        let mut low = 0usize;
        let mut high = catalogs[0].len();
        while low < high {
            let middle = (low + high) / 2;
            if catalogs[0][middle] < key { low = middle + 1; } else { high = middle; }
        }
        let mut slot = low;
        for (catalog_index, catalog) in catalogs.iter().enumerate() {
            let code = if slot < catalog.len() { catalog[slot] + 17 } else { NO_SUCCESSOR };
            checksum += (query_index as i64 + 1) * (catalog_index as i64 + 1) * code;
            if catalog_index + 1 < m { slot = bridges[catalog_index][slot]; }
        }
    }
    checksum
}
