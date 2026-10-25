const SAD_RANGE: i32 = 16;
const SAD_DIM: usize = 33;
const SAD_POS: usize = 1089;
const SAD_PAD: usize = 1092;
const SAD_SLOTS: usize = 44_772;
const TYPE_COUNT: [usize; 8] = [0, 1, 2, 2, 4, 8, 8, 16];
const TYPE_OFFSET: [usize; 8] = [0, 0, 1, 3, 5, 9, 17, 25];

unsafe fn pixel(values: *const i64, image: usize, y: usize, x: usize) -> i32 {
    let packed = *values.add(image * 64 + y * 4 + x / 4) as u32;
    ((packed >> ((x % 4) * 8)) & 255) as i32
}

#[no_mangle]
pub unsafe extern "C" fn parboil_sad(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 128 { return -1; }
    for i in 0..128 {
        let raw = *values.add(i);
        if raw < 0 || raw > 4_294_967_295 { return -1; }
    }

    let mut sads = [0u16; SAD_SLOTS];
    for py in -SAD_RANGE..=SAD_RANGE {
        for px in -SAD_RANGE..=SAD_RANGE {
            for by in 0..4usize {
                for bx in 0..4usize {
                    let base = (TYPE_OFFSET[7] + by * 4 + bx) * SAD_PAD;
                    let pos = ((py + SAD_RANGE) as usize) * SAD_DIM + (px + SAD_RANGE) as usize;
                    let mut sad = 0u32;
                    for y in 0..4usize {
                        for x in 0..4usize {
                            let fy = by * 4 + y;
                            let fx = bx * 4 + x;
                            let ry = (fy as i32 + py).clamp(0, 15) as usize;
                            let rx = (fx as i32 + px).clamp(0, 15) as usize;
                            let delta = pixel(values, 0, fy, fx) - pixel(values, 1, ry, rx);
                            sad += if delta < 0 { (-delta) as u32 } else { delta as u32 };
                        }
                    }
                    sads[base + pos] = sad as u16;
                }
            }
        }
    }

    // Source larger_sads hierarchy: types 6, 5, 4, 3, 2, then 1.
    for by in 0..2usize { for bx in 0..4usize {
        let dst = TYPE_OFFSET[6] + 4 * by + bx;
        let src = TYPE_OFFSET[7] + 8 * by + bx;
        for p in 0..SAD_POS { sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+4)*SAD_PAD+p]; }
    } }
    for by in 0..4usize { for bx in 0..2usize {
        let dst = TYPE_OFFSET[5] + 2 * by + bx;
        let src = TYPE_OFFSET[7] + 4 * by + 2 * bx;
        for p in 0..SAD_POS { sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+1)*SAD_PAD+p]; }
    } }
    for by in 0..2usize { for bx in 0..2usize {
        let dst = TYPE_OFFSET[4] + 2 * by + bx;
        let src = TYPE_OFFSET[5] + 4 * by + bx;
        for p in 0..SAD_POS { sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+2)*SAD_PAD+p]; }
    } }
    for bx in 0..2usize {
        let dst = TYPE_OFFSET[3] + bx;
        let src = TYPE_OFFSET[4] + bx;
        for p in 0..SAD_POS { sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+2)*SAD_PAD+p]; }
    }
    for by in 0..2usize {
        let dst = TYPE_OFFSET[2] + by;
        let src = TYPE_OFFSET[4] + 2 * by;
        for p in 0..SAD_POS { sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+1)*SAD_PAD+p]; }
    }
    for p in 0..SAD_POS {
        sads[TYPE_OFFSET[1]*SAD_PAD+p] = sads[TYPE_OFFSET[2]*SAD_PAD+p] + sads[(TYPE_OFFSET[2]+1)*SAD_PAD+p];
    }

    let mut checksum = 0i64;
    for kind in 1..=7 {
        for block in 0..TYPE_COUNT[kind] {
            for p in 0..SAD_POS { checksum += sads[(TYPE_OFFSET[kind]+block)*SAD_PAD+p] as i64; }
        }
    }
    checksum
}
