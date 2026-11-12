const MAX_DEPTH: usize = 5;

fn factor(tx: f64, ty: f64, source_area: f64, sx: f64, sy: f64, gap: f64) -> f64 {
    let distance_squared = (sx - tx) * (sx - tx) + (sy - ty) * (sy - ty) + gap * gap;
    source_area * gap * gap / (distance_squared * distance_squared)
}

fn visit(tx: f64, ty: f64, target_side: f64, sx: f64, sy: f64, source_side: f64,
         gap: f64, bound: f64, allowed_depth: usize, depth: usize, weight: f64,
         transfer: &mut f64, leaves: &mut usize, deepest: &mut usize) {
    let coarse = factor(tx, ty, source_side * source_side, sx, sy, gap);
    let split_source = source_side >= target_side;
    let parent_side = if split_source { source_side } else { target_side };
    let child_side = parent_side * 0.5;
    let offset = parent_side * 0.25;
    let mut fine = 0.0;
    for quadrant in 0..4 {
        let dx = if quadrant & 1 != 0 { offset } else { -offset };
        let dy = if quadrant & 2 != 0 { offset } else { -offset };
        if split_source {
            fine += factor(tx, ty, child_side * child_side, sx + dx, sy + dy, gap);
        } else {
            fine += 0.25 * factor(tx + dx, ty + dy, source_side * source_side, sx, sy, gap);
        }
    }
    if depth >= allowed_depth || (fine - coarse).abs() <= bound {
        *transfer += weight * coarse;
        *leaves += 1;
        *deepest = (*deepest).max(depth);
        return;
    }
    for quadrant in 0..4 {
        let dx = if quadrant & 1 != 0 { offset } else { -offset };
        let dy = if quadrant & 2 != 0 { offset } else { -offset };
        if split_source {
            visit(tx, ty, target_side, sx + dx, sy + dy, child_side, gap,
                  bound, allowed_depth, depth + 1, weight, transfer, leaves, deepest);
        } else {
            visit(tx + dx, ty + dy, child_side, sx, sy, source_side, gap,
                  bound, allowed_depth, depth + 1, weight * 0.25,
                  transfer, leaves, deepest);
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn splash2_radiosity_refine(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length != 11 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) { return -1; }
    let (tx, ty, ts, sx, sy, ss) = (values[0], values[1], values[2], values[3], values[4], values[5]);
    let (gap, brightness, reflectance, bound, depth_value) = (values[6], values[7], values[8], values[9], values[10]);
    if !(-8.0..=8.0).contains(&tx) || !(-8.0..=8.0).contains(&ty)
        || !(-8.0..=8.0).contains(&sx) || !(-8.0..=8.0).contains(&sy)
        || !(ts == 1.0 || ts == 2.0 || ts == 4.0) || !(ss == 1.0 || ss == 2.0 || ss == 4.0)
        || !(1.0..=8.0).contains(&gap) || ts > gap || ss > gap
        || !(0.0..=4.0).contains(&brightness) || !(0.0..=1.0).contains(&reflectance)
        || !(0.0..=1.0).contains(&bound) || depth_value.fract() != 0.0
        || !(0.0..=MAX_DEPTH as f64).contains(&depth_value) { return -1; }
    if output.is_null() || output_capacity < 3 { return -2; }
    let mut transfer = 0.0;
    let mut leaves = 0;
    let mut deepest = 0;
    visit(tx, ty, ts, sx, sy, ss, gap, bound, depth_value as usize, 0, 1.0,
          &mut transfer, &mut leaves, &mut deepest);
    unsafe {
        *output.add(0) = reflectance * brightness * transfer;
        *output.add(1) = leaves as f64;
        *output.add(2) = deepest as f64;
    }
    3
}
