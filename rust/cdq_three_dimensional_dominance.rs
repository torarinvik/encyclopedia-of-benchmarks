const MAX_N: usize = 64;
const MAX_PARSEABLE_LENGTH: usize = 194;

#[derive(Clone, Copy, Default)]
struct Point {
    x: i64,
    y: i64,
    z: i64,
    multiplicity: i64,
    z_rank: usize,
    original_index: usize,
}

struct Workspace {
    points: [Point; MAX_N],
    original_group: [usize; MAX_N],
    dominated: [i64; MAX_N],
    bit: [i64; MAX_N + 1],
    source_order: [usize; MAX_N],
    target_order: [usize; MAX_N],
    z_values: [i64; MAX_N],
}

fn point_less(a: Point, b: Point) -> bool {
    (a.x, a.y, a.z) < (b.x, b.y, b.z)
}

fn same_coordinates(a: Point, b: Point) -> bool {
    a.x == b.x && a.y == b.y && a.z == b.z
}

fn bit_add(work: &mut Workspace, mut index: usize, delta: i64, limit: usize) {
    while index <= limit {
        work.bit[index] += delta;
        index += index & index.wrapping_neg();
    }
}

fn bit_sum(work: &Workspace, mut index: usize) -> i64 {
    let mut sum = 0_i64;
    while index > 0 {
        sum += work.bit[index];
        index -= index & index.wrapping_neg();
    }
    sum
}

fn cdq(work: &mut Workspace, left: usize, right: usize, group_count: usize) {
    if left >= right {
        return;
    }
    let middle = left + (right - left) / 2;
    cdq(work, left, middle, group_count);
    cdq(work, middle + 1, right, group_count);

    let mut source_cursor = left;
    for target_position in middle + 1..=right {
        let target = work.source_order[target_position];
        while source_cursor <= middle {
            let source = work.source_order[source_cursor];
            if work.points[source].y > work.points[target].y {
                break;
            }
            let rank = work.points[source].z_rank;
            let multiplicity = work.points[source].multiplicity;
            bit_add(work, rank, multiplicity, group_count);
            source_cursor += 1;
        }
        let target_rank = work.points[target].z_rank;
        let amount = bit_sum(work, target_rank);
        work.dominated[target] += amount;
    }
    for i in left..source_cursor {
        let source = work.source_order[i];
        let rank = work.points[source].z_rank;
        let multiplicity = work.points[source].multiplicity;
        bit_add(work, rank, -multiplicity, group_count);
    }

    let mut left_cursor = left;
    let mut right_cursor = middle + 1;
    let mut destination = left;
    while left_cursor <= middle && right_cursor <= right {
        let left_point = work.source_order[left_cursor];
        let right_point = work.source_order[right_cursor];
        if work.points[left_point].y <= work.points[right_point].y {
            work.target_order[destination] = left_point;
            left_cursor += 1;
        } else {
            work.target_order[destination] = right_point;
            right_cursor += 1;
        }
        destination += 1;
    }
    while left_cursor <= middle {
        work.target_order[destination] = work.source_order[left_cursor];
        left_cursor += 1;
        destination += 1;
    }
    while right_cursor <= right {
        work.target_order[destination] = work.source_order[right_cursor];
        right_cursor += 1;
        destination += 1;
    }
    for i in left..=right {
        work.source_order[i] = work.target_order[i];
    }
}

fn solve(values: &[i64]) -> i64 {
    if values.is_empty() || values.len() > MAX_PARSEABLE_LENGTH {
        return -1;
    }
    if !(1..=MAX_N as i64).contains(&values[0]) {
        return -1;
    }
    let n = values[0] as usize;
    if values.len() != 1 + 3 * n {
        return -1;
    }

    let mut work = Workspace {
        points: [Point::default(); MAX_N],
        original_group: [0; MAX_N],
        dominated: [0; MAX_N],
        bit: [0; MAX_N + 1],
        source_order: [0; MAX_N],
        target_order: [0; MAX_N],
        z_values: [0; MAX_N],
    };
    for i in 0..n {
        let x = values[1 + 3 * i];
        let y = values[2 + 3 * i];
        let z = values[3 + 3 * i];
        if !(-1000..=1000).contains(&x)
            || !(-1000..=1000).contains(&y)
            || !(-1000..=1000).contains(&z)
        {
            return -1;
        }
        work.points[i] = Point { x, y, z, multiplicity: 1, z_rank: 0, original_index: i };
    }
    for i in 1..n {
        let value = work.points[i];
        let mut j = i;
        while j > 0 && point_less(value, work.points[j - 1]) {
            work.points[j] = work.points[j - 1];
            j -= 1;
        }
        work.points[j] = value;
    }

    let mut group_count = 0;
    for i in 0..n {
        let point = work.points[i];
        if group_count > 0 && same_coordinates(point, work.points[group_count - 1]) {
            work.points[group_count - 1].multiplicity += 1;
            work.original_group[point.original_index] = group_count - 1;
        } else {
            work.points[group_count] = point;
            work.points[group_count].multiplicity = 1;
            work.original_group[point.original_index] = group_count;
            group_count += 1;
        }
    }

    for i in 0..group_count {
        work.z_values[i] = work.points[i].z;
    }
    for i in 1..group_count {
        let value = work.z_values[i];
        let mut j = i;
        while j > 0 && value < work.z_values[j - 1] {
            work.z_values[j] = work.z_values[j - 1];
            j -= 1;
        }
        work.z_values[j] = value;
    }
    let mut z_count = 0;
    for i in 0..group_count {
        let value = work.z_values[i];
        if z_count == 0 || value != work.z_values[z_count - 1] {
            work.z_values[z_count] = value;
            z_count += 1;
        }
    }
    for i in 0..group_count {
        let mut low = 0;
        let mut high = z_count;
        while low < high {
            let middle = low + (high - low) / 2;
            if work.z_values[middle] < work.points[i].z {
                low = middle + 1;
            } else {
                high = middle;
            }
        }
        work.points[i].z_rank = low + 1;
        work.source_order[i] = i;
    }

    if group_count > 1 {
        cdq(&mut work, 0, group_count - 1, z_count);
    }
    let mut result = 0_i64;
    for i in 0..n {
        let group = work.original_group[i];
        let count = work.dominated[group] + work.points[group].multiplicity - 1;
        result += (i as i64 + 1) * count;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn cdq_three_dimensional_dominance(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH {
        return -1;
    }
    solve(std::slice::from_raw_parts(input, length))
}
