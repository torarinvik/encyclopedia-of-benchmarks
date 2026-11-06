const MAX_DIMENSION: usize = 16;
const MAX_A_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION * MAX_DIMENSION;
const MAX_C4_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

#[no_mangle]
pub extern "C" fn doitgen(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input.iter().any(|&value| value < 1 || value > MAX_DIMENSION as i64) { return INVALID_RESULT; }
    let (nr, nq, np) = (input[0] as usize, input[1] as usize, input[2] as usize);
    // Every element read below is written first within the validated bounds.
    let mut a = [std::mem::MaybeUninit::<f64>::uninit(); MAX_A_CELLS];
    let mut c4 = [std::mem::MaybeUninit::<f64>::uninit(); MAX_C4_CELLS];
    let mut sums = [std::mem::MaybeUninit::<f64>::uninit(); MAX_DIMENSION];
    for r in 0..nr {
        for q in 0..nq {
            for p in 0..np { a[(r * nq + q) * np + p].write(((r * q + p) % np) as f64 / np as f64); }
        }
    }
    for i in 0..np {
        for j in 0..np { c4[i * np + j].write(((i * j) % np) as f64 / np as f64); }
    }
    for r in 0..nr {
        for q in 0..nq {
            for p in 0..np {
                let mut value = 0.0;
                for s in 0..np {
                    // Initializers above cover every A and C4 element in this loop.
                    value += unsafe { a[(r * nq + q) * np + s].assume_init() * c4[s * np + p].assume_init() };
                }
                sums[p].write(value);
            }
            for p in 0..np { a[(r * nq + q) * np + p].write(unsafe { sums[p].assume_init() }); }
        }
    }
    let mut checksum = 0.0f64;
    for r in 0..nr {
        for q in 0..nq {
            for p in 0..np { checksum += unsafe { a[(r * nq + q) * np + p].assume_init() }; }
        }
    }
    checksum
}
