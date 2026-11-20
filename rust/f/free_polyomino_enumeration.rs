const FP_MAX_N: usize = 8;
const FP_MAX_SHAPES: usize = 512;
const FP_LAYER_WORDS: usize = FP_MAX_SHAPES * FP_MAX_N;

fn canonical(xs: &[i64; FP_MAX_N], ys: &[i64; FP_MAX_N], size: usize) -> [i64; FP_MAX_N] {
    let mut best = [0i64; FP_MAX_N];
    let mut have_best = false;
    for mode in 0..8 {
        let mut tx = [0i64; FP_MAX_N];
        let mut ty = [0i64; FP_MAX_N];
        let mut codes = [0i64; FP_MAX_N];
        let (mut min_x, mut min_y) = (1000i64, 1000i64);
        for i in 0..size {
            let mut a = if mode >= 4 { ys[i] } else { xs[i] };
            let mut b = if mode >= 4 { xs[i] } else { ys[i] };
            if mode & 1 != 0 { a = -a; }
            if mode & 2 != 0 { b = -b; }
            tx[i] = a;
            ty[i] = b;
            min_x = min_x.min(a);
            min_y = min_y.min(b);
        }
        for i in 0..size {
            codes[i] = (tx[i] - min_x) * 8 + ty[i] - min_y;
            let mut j = i;
            while j > 0 && codes[j] < codes[j - 1] {
                codes.swap(j, j - 1);
                j -= 1;
            }
        }
        let mut less = !have_best;
        if have_best {
            for i in 0..size {
                if codes[i] != best[i] { less = codes[i] < best[i]; break; }
            }
        }
        if less {
            best[..size].copy_from_slice(&codes[..size]);
            have_best = true;
        }
    }
    best
}

#[no_mangle]
pub unsafe extern "C" fn free_polyomino_enumeration(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > FP_MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    let mut shapes = [0i64; 2 * FP_LAYER_WORDS];
    let (mut current, mut shape_count) = (0usize, 1usize);
    let dx = [1i64, -1, 0, 0];
    let dy = [0i64, 0, 1, -1];
    for size in 1..n {
        let next = 1 - current;
        let mut next_count = 0usize;
        for s in 0..shape_count {
            for cell in 0..size {
                let code = shapes[current * FP_LAYER_WORDS + s * FP_MAX_N + cell];
                let (x, y) = (code / 8, code % 8);
                for direction in 0..4 {
                    let (nx, ny) = (x + dx[direction], y + dy[direction]);
                    let mut occupied = false;
                    if (0..8).contains(&nx) && (0..8).contains(&ny) {
                        let neighbor = nx * 8 + ny;
                        for i in 0..size {
                            if shapes[current * FP_LAYER_WORDS + s * FP_MAX_N + i] == neighbor { occupied = true; }
                        }
                    }
                    if occupied { continue; }
                    let mut xs = [0i64; FP_MAX_N];
                    let mut ys = [0i64; FP_MAX_N];
                    for i in 0..size {
                        let previous = shapes[current * FP_LAYER_WORDS + s * FP_MAX_N + i];
                        xs[i] = previous / 8;
                        ys[i] = previous % 8;
                    }
                    xs[size] = nx;
                    ys[size] = ny;
                    let candidate = canonical(&xs, &ys, size + 1);
                    let mut duplicate = false;
                    for old in 0..next_count {
                        if !duplicate {
                            let mut same = true;
                            for i in 0..=size {
                                if shapes[next * FP_LAYER_WORDS + old * FP_MAX_N + i] != candidate[i] { same = false; }
                            }
                            if same { duplicate = true; }
                        }
                    }
                    if !duplicate {
                        if next_count >= FP_MAX_SHAPES { return -1; }
                        for i in 0..=size { shapes[next * FP_LAYER_WORDS + next_count * FP_MAX_N + i] = candidate[i]; }
                        next_count += 1;
                    }
                }
            }
        }
        current = next;
        shape_count = next_count;
    }
    shape_count as i64
}
