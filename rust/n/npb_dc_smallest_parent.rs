/* Bounded clean-room NASA NPB DC smallest-parent profile; see NAS-03-005. */
const MAX_DIMS: usize = 5;
const MAX_ROWS: usize = 16;
const MAX_MASKS: usize = 32;

fn key_equal(a: &[i64; MAX_DIMS], b: &[i64; MAX_DIMS], mask: usize, dimensions: usize) -> bool {
    (0..dimensions).all(|d| mask & (1 << d) == 0 || a[d] == b[d])
}

fn key_less(a: &[i64; MAX_DIMS], b: &[i64; MAX_DIMS], mask: usize, dimensions: usize) -> bool {
    for d in 0..dimensions {
        if mask & (1 << d) == 0 { continue; }
        if a[d] < b[d] { return true; }
        if a[d] > b[d] { return false; }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn npb_dc_smallest_parent(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > 98 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_DIMS as i64 || values[1] < 1 || values[1] > MAX_ROWS as i64 { return -1; }
    let dimensions = values[0] as usize;
    let rows = values[1] as usize;
    if length != 2 + rows * (dimensions + 1) { return -1; }
    let mut attributes = [[0i64; MAX_DIMS]; MAX_ROWS];
    let mut measures = [0i64; MAX_ROWS];
    let mut offset = 2;
    for row in 0..rows {
        for dimension in 0..dimensions {
            let value = values[offset];
            offset += 1;
            if !(0..=7).contains(&value) { return -1; }
            attributes[row][dimension] = value;
        }
        measures[row] = values[offset];
        offset += 1;
        if !(0..=1000).contains(&measures[row]) { return -1; }
    }

    let mut keys = [[[0i64; MAX_DIMS]; MAX_ROWS]; MAX_MASKS];
    let mut sums = [[0i64; MAX_ROWS]; MAX_MASKS];
    let mut counts = [0usize; MAX_MASKS];
    let mut parents = [-2i32; MAX_MASKS];
    let full = (1usize << dimensions) - 1;
    parents[full] = -1;
    for row in 0..rows {
        let mut group = 0;
        while group < counts[full] && !key_equal(&keys[full][group], &attributes[row], full, dimensions) { group += 1; }
        if group == counts[full] {
            keys[full][group] = attributes[row];
            sums[full][group] = measures[row];
            counts[full] += 1;
        } else { sums[full][group] += measures[row]; }
    }
    for index in 1..counts[full] {
        let mut position = index;
        while position > 0 && key_less(&keys[full][position], &keys[full][position - 1], full, dimensions) {
            keys[full].swap(position, position - 1);
            sums[full].swap(position, position - 1);
            position -= 1;
        }
    }

    for wanted in (0..dimensions).rev() {
        for mask in 0..=full {
            if mask.count_ones() as usize != wanted { continue; }
            let mut parent = usize::MAX;
            let mut best = MAX_ROWS + 1;
            for dimension in 0..dimensions {
                let bit = 1usize << dimension;
                if mask & bit != 0 { continue; }
                let candidate = mask | bit;
                if parent == usize::MAX || counts[candidate] < best {
                    parent = candidate;
                    best = counts[candidate];
                }
            }
            if parent == usize::MAX { return -1; }
            parents[mask] = parent as i32;
            for parent_group in 0..counts[parent] {
                let mut group = 0;
                while group < counts[mask] && !key_equal(&keys[mask][group], &keys[parent][parent_group], mask, dimensions) { group += 1; }
                if group == counts[mask] {
                    for dimension in 0..dimensions {
                        if mask & (1 << dimension) != 0 { keys[mask][group][dimension] = keys[parent][parent_group][dimension]; }
                    }
                    sums[mask][group] = sums[parent][parent_group];
                    counts[mask] += 1;
                } else { sums[mask][group] += sums[parent][parent_group]; }
            }
            for index in 1..counts[mask] {
                let mut position = index;
                while position > 0 && key_less(&keys[mask][position], &keys[mask][position - 1], mask, dimensions) {
                    keys[mask].swap(position, position - 1);
                    sums[mask].swap(position, position - 1);
                    position -= 1;
                }
            }
        }
    }

    let mut checksum = 0i64;
    for mask in 0..=full {
        let view = mask as i64 + 1;
        checksum += view * 1_000_000 + (parents[mask] as i64 + 2) * 10_000 + counts[mask] as i64 * 1_000;
        for group in 0..counts[mask] {
            let rank = group as i64 + 1;
            checksum += rank * (sums[mask][group] + 1);
            for dimension in 0..dimensions {
                if mask & (1 << dimension) != 0 {
                    checksum += rank * (dimension as i64 + 1) * (keys[mask][group][dimension] + 1);
                }
            }
        }
    }
    checksum
}
