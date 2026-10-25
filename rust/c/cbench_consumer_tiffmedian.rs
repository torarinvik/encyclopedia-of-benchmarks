const BIN_SIDE: usize = 32;
const HISTOGRAM_SIZE: usize = BIN_SIDE * BIN_SIDE * BIN_SIDE;
const MAX_PALETTE: usize = 8;
const MAX_PIXELS: usize = 16;
const MAX_INPUT_LENGTH: usize = 50;

#[derive(Clone, Copy, Default)]
struct ColorBox {
    rmin: usize,
    rmax: usize,
    gmin: usize,
    gmax: usize,
    bmin: usize,
    bmax: usize,
    total: usize,
}

fn hist_at(histogram: &[i32; HISTOGRAM_SIZE], r: usize, g: usize, b: usize) -> i32 {
    histogram[(r * BIN_SIDE + g) * BIN_SIDE + b]
}

fn shrink_box(histogram: &[i32; HISTOGRAM_SIZE], b: &mut ColorBox) {
    let mut rmin = BIN_SIDE;
    let mut gmin = BIN_SIDE;
    let mut bmin = BIN_SIDE;
    let mut rmax = 0usize;
    let mut gmax = 0usize;
    let mut bmax = 0usize;
    for r in b.rmin..=b.rmax {
        for g in b.gmin..=b.gmax {
            for blue in b.bmin..=b.bmax {
                if hist_at(histogram, r, g, blue) != 0 {
                    rmin = rmin.min(r); rmax = rmax.max(r);
                    gmin = gmin.min(g); gmax = gmax.max(g);
                    bmin = bmin.min(blue); bmax = bmax.max(blue);
                }
            }
        }
    }
    b.rmin=rmin; b.rmax=rmax; b.gmin=gmin; b.gmax=gmax; b.bmin=bmin; b.bmax=bmax;
}

fn largest_box(boxes: &[ColorBox; MAX_PALETTE], count: usize) -> Option<usize> {
    let mut selected = None;
    let mut largest_total = 0usize;
    for (i, b) in boxes[..count].iter().enumerate() {
        let spans = b.rmax > b.rmin || b.gmax > b.gmin || b.bmax > b.bmin;
        if spans && (selected.is_none() || b.total > largest_total) {
            selected = Some(i);
            largest_total = b.total;
        }
    }
    selected
}

fn split_box(histogram: &[i32; HISTOGRAM_SIZE], boxes: &mut [ColorBox; MAX_PALETTE], count: &mut usize, selected: usize) {
    let mut upper = boxes[selected];
    let rs = upper.rmax - upper.rmin;
    let gs = upper.gmax - upper.gmin;
    let bs = upper.bmax - upper.bmin;
    let axis = if rs >= gs && rs >= bs { 0 } else if gs >= bs { 1 } else { 2 };
    let first = if axis == 0 { upper.rmin } else if axis == 1 { upper.gmin } else { upper.bmin };
    let last = if axis == 0 { upper.rmax } else if axis == 1 { upper.gmax } else { upper.bmax };
    let mut along = [0i32; BIN_SIDE];
    for r in upper.rmin..=upper.rmax {
        for g in upper.gmin..=upper.gmax {
            for b in upper.bmin..=upper.bmax {
                let coordinate = if axis == 0 { r } else if axis == 1 { g } else { b };
                along[coordinate] += hist_at(histogram, r, g, b);
            }
        }
    }
    let median = upper.total / 2;
    let mut accumulated = 0usize;
    let mut split = first;
    while split <= last {
        accumulated += along[split] as usize;
        if accumulated >= median { break; }
        split += 1;
    }
    if split == first { split += 1; }
    let mut lower = upper;
    let lower_total = along[first..split].iter().map(|v| *v as usize).sum();
    let upper_total = along[split..=last].iter().map(|v| *v as usize).sum();
    lower.total=lower_total; upper.total=upper_total;
    if axis == 0 { lower.rmax=split-1; upper.rmin=split; }
    else if axis == 1 { lower.gmax=split-1; upper.gmin=split; }
    else { lower.bmax=split-1; upper.bmin=split; }
    shrink_box(histogram, &mut lower);
    shrink_box(histogram, &mut upper);
    boxes[selected]=upper;
    for i in (1..=*count).rev() { boxes[i]=boxes[i-1]; }
    boxes[0]=lower;
    *count += 1;
}

#[no_mangle]
pub unsafe extern "C" fn cbench_consumer_tiffmedian(
    input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 5 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let palette_value = values[0];
    let pixel_value = values[1];
    if palette_value < 1 || palette_value > MAX_PALETTE as i64 || pixel_value < 1 || pixel_value > MAX_PIXELS as i64 { return -1; }
    let palette_limit = palette_value as usize;
    let pixel_count = pixel_value as usize;
    if input_length != 2 + 3 * pixel_count { return -1; }
    if values[2..].iter().any(|v| *v < 0 || *v > 255) { return -1; }

    let mut histogram = [0i32; HISTOGRAM_SIZE];
    let mut boxes = [ColorBox::default(); MAX_PALETTE];
    let mut rmin=BIN_SIDE; let mut gmin=BIN_SIDE; let mut bmin=BIN_SIDE;
    let mut rmax=0usize; let mut gmax=0usize; let mut bmax=0usize;
    for p in 0..pixel_count {
        let r=(values[2+3*p] >> 3) as usize;
        let g=(values[3+3*p] >> 3) as usize;
        let b=(values[4+3*p] >> 3) as usize;
        histogram[(r*BIN_SIDE+g)*BIN_SIDE+b]+=1;
        rmin=rmin.min(r);rmax=rmax.max(r);gmin=gmin.min(g);gmax=gmax.max(g);bmin=bmin.min(b);bmax=bmax.max(b);
    }
    boxes[0]=ColorBox{rmin,rmax,gmin,gmax,bmin,bmax,total:pixel_count};
    let mut box_count=1usize;
    while box_count < palette_limit {
        let Some(selected)=largest_box(&boxes,box_count) else { break; };
        split_box(&histogram,&mut boxes,&mut box_count,selected);
    }
    let output_bytes=1+3*box_count;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    let result=std::slice::from_raw_parts_mut(output,output_bytes);
    result[0]=box_count as u8;
    for i in 0..box_count {
        result[1+3*i]=((boxes[i].rmin+boxes[i].rmax)*4) as u8;
        result[2+3*i]=((boxes[i].gmin+boxes[i].gmax)*4) as u8;
        result[3+3*i]=((boxes[i].bmin+boxes[i].bmax)*4) as u8;
    }
    output_bytes as i64
}
