const MAX_MODULES: usize = 8;
const MAX_NETS: usize = 16;
const MAX_INPUT: usize = 146;
type Nets = [[usize; MAX_MODULES]; MAX_NETS];

fn edge_cut(side: &[i32; MAX_MODULES], nets: &Nets, degrees: &[usize; MAX_NETS], net_count: usize) -> i32 {
    let mut total = 0;
    for net in 0..net_count {
        for i in 0..degrees[net] {
            for j in i + 1..degrees[net] {
                if side[nets[net][i]] != side[nets[net][j]] { total += 1; }
            }
        }
    }
    total
}

fn net_cut(side: &[i32; MAX_MODULES], nets: &Nets, degrees: &[usize; MAX_NETS], net_count: usize) -> i32 {
    let mut total = 0;
    for net in 0..net_count {
        let first = side[nets[net][0]];
        if (1..degrees[net]).any(|i| side[nets[net][i]] != first) { total += 1; }
    }
    total
}

#[no_mangle]
pub unsafe extern "C" fn ptrdist_ks(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let module_value = *input;
    let net_value = *input.add(1);
    if !(2..=MAX_MODULES as i64).contains(&module_value) || module_value % 2 != 0 ||
        !(0..=MAX_NETS as i64).contains(&net_value) { return -1; }
    let modules = module_value as usize;
    let net_count = net_value as usize;
    let mut nets: Nets = [[0; MAX_MODULES]; MAX_NETS];
    let mut degrees = [0usize; MAX_NETS];
    let mut cursor = 2usize;
    for net in 0..net_count {
        if cursor >= length { return -1; }
        let degree_value = *input.add(cursor);
        cursor += 1;
        if degree_value < 2 || degree_value > modules as i64 || cursor + degree_value as usize > length { return -1; }
        let degree = degree_value as usize;
        degrees[net] = degree;
        for i in 0..degree {
            let member_value = *input.add(cursor);
            cursor += 1;
            if member_value < 0 || member_value >= modules as i64 { return -1; }
            let member = member_value as usize;
            if nets[net][..i].contains(&member) { return -1; }
            nets[net][i] = member;
        }
    }
    if cursor != length { return -1; }

    let half = modules / 2;
    let mut order_a = [0usize; MAX_MODULES];
    let mut order_b = [0usize; MAX_MODULES];
    let mut side = [0i32; MAX_MODULES];
    for i in 0..half { order_a[i] = i; order_b[i] = half + i; side[i] = 0; side[half + i] = 1; }
    let mut accepted_passes = 0i64;
    loop {
        let mut work = side;
        let mut remaining_a = order_a;
        let mut remaining_b = order_b;
        let mut count_a = half;
        let mut count_b = half;
        let mut selected_a = [0usize; MAX_MODULES];
        let mut selected_b = [0usize; MAX_MODULES];
        let mut cumulative_gain = 0i32;
        let mut best_gain = i32::MIN;
        let mut best_prefix = 0usize;
        for step in 0..half {
            let baseline = edge_cut(&work, &nets, &degrees, net_count);
            let mut pair_gain = i32::MIN;
            let mut chosen = (usize::MAX, usize::MAX);
            for &a in &remaining_a[..count_a] {
                for &b in &remaining_b[..count_b] {
                    work[a] = 1; work[b] = 0;
                    let gain = baseline - edge_cut(&work, &nets, &degrees, net_count);
                    work[a] = 0; work[b] = 1;
                    if gain > pair_gain { pair_gain = gain; chosen = (a, b); }
                }
            }
            let (a, b) = chosen;
            selected_a[step] = a; selected_b[step] = b;
            work[a] = 1; work[b] = 0;
            let at_a = remaining_a[..count_a].iter().position(|&x| x == a).unwrap();
            remaining_a.copy_within(at_a + 1..count_a, at_a); count_a -= 1;
            let at_b = remaining_b[..count_b].iter().position(|&x| x == b).unwrap();
            remaining_b.copy_within(at_b + 1..count_b, at_b); count_b -= 1;
            cumulative_gain += pair_gain;
            if cumulative_gain > best_gain { best_gain = cumulative_gain; best_prefix = step + 1; }
        }
        if best_gain <= 0 { break; }
        let mut next_a = [0usize; MAX_MODULES];
        let mut next_b = [0usize; MAX_MODULES];
        for i in 0..best_prefix { next_a[i] = selected_b[i]; next_b[i] = selected_a[i]; }
        for i in best_prefix..half { next_a[i] = selected_a[i]; next_b[i] = selected_b[i]; }
        order_a = next_a; order_b = next_b;
        side = [1; MAX_MODULES];
        for i in 0..half { side[order_a[i]] = 0; side[order_b[i]] = 1; }
        accepted_passes += 1;
    }

    let mut mask = 0i64;
    for module in 0..modules { if side[module] == 0 { mask |= 1 << module; } }
    (mask + ((edge_cut(&side, &nets, &degrees, net_count) as i64) << 8) +
        ((net_cut(&side, &nets, &degrees, net_count) as i64) << 17) + (accepted_passes << 22))
}
