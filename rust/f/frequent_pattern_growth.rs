struct Context { min_support: i64, order: [usize; 8], result: i64 }

fn grow(ctx: &mut Context, masks: &[i64], weights: &[i64], rank_limit: usize) {
    for rank in (0..rank_limit).rev() {
        let bit = 1_i64 << ctx.order[rank];
        let support: i64 = masks.iter().zip(weights).filter(|(mask, _)| **mask & bit != 0).map(|(_, weight)| *weight).sum();
        if support < ctx.min_support { continue; }
        ctx.result += 1;
        let mut ancestor_mask = 0_i64;
        for r in 0..rank { ancestor_mask |= 1_i64 << ctx.order[r]; }
        let mut next_masks = [0_i64; 64];
        let mut next_weights = [0_i64; 64];
        let mut next_len = 0;
        for i in 0..masks.len() {
            if masks[i] & bit != 0 {
                next_masks[next_len] = masks[i] & ancestor_mask;
                next_weights[next_len] = weights[i];
                next_len += 1;
            }
        }
        grow(ctx, &next_masks[..next_len], &next_weights[..next_len], rank);
    }
}

#[no_mangle]
pub unsafe extern "C" fn frequent_pattern_growth(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 || length > 67 { return -1; }
    let v = std::slice::from_raw_parts(values, length);
    let (n, m, minimum) = (v[0], v[1], v[2]);
    if !(1..=64).contains(&n) || !(1..=8).contains(&m) || minimum < 1 || minimum > n || length != (3+n) as usize { return -1; }
    let limit = 1_i64 << m;
    let mut masks = [0_i64; 64];
    let weights = [1_i64; 64];
    let mut support = [0_i32; 8];
    for i in 0..n as usize {
        let mask = v[3+i]; if mask < 0 || mask >= limit { return -1; }
        masks[i] = mask;
        for item in 0..m as usize { support[item] += ((mask >> item) & 1) as i32; }
    }
    let mut order = [0_usize; 8]; for i in 0..m as usize { order[i]=i; }
    for i in 1..m as usize {
        let item=order[i]; let mut j=i;
        while j>0 && (support[order[j-1]] < support[item] || (support[order[j-1]] == support[item] && order[j-1] > item)) {order[j]=order[j-1];j-=1;}
        order[j]=item;
    }
    let mut ctx=Context{min_support:minimum,order,result:0};
    grow(&mut ctx,&masks[..n as usize],&weights[..n as usize],m as usize);
    ctx.result
}
