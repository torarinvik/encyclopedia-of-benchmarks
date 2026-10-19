const MAX_BITS: usize = 4096;
const MAX_OPS: usize = 32;
const MAX_OUT: usize = MAX_BITS / 8;
#[no_mangle]
pub unsafe extern "C" fn bitmap_block_allocation(values: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 2 || length > 2 + 2 * MAX_OPS { return -1; }
    let v = std::slice::from_raw_parts(values, length);
    let (rb, ro) = (v[0], v[1]);
    if rb < 1 || rb > MAX_BITS as i64 || ro < 0 || ro > MAX_OPS as i64 || length != 2 + 2 * ro as usize { return -1; }
    let bits = rb as usize; let ops = ro as usize;
    let mut op = [(0usize, 0usize); MAX_OPS];
    for i in 0..ops {
        let (o,n)=(v[2+2*i],v[3+2*i]);
        if o<0 || o as usize>bits || n<0 || n as usize>bits-o as usize { return -1; }
        op[i]=(o as usize,n as usize);
    }
    let bytes=(bits+7)/8; let mut bitmap=[0u8;MAX_OUT];
    for b in (0..bits).step_by(2) { bitmap[b/8] |= 1 << (b%8); }
    for (i,(offset,run)) in op[..ops].iter().enumerate() {
        for b in *offset..(*offset+*run) { let mask=1u8<<(b%8);
            if i%3==0 { bitmap[b/8]|=mask; } else if i%3==1 { bitmap[b/8]&=!mask; } else { bitmap[b/8]^=mask; }
        }
    }
    if output.is_null() || capacity<bytes { return -2; }
    for i in 0..bytes { *output.add(i)=bitmap[i]; }
    bytes as i64
}
