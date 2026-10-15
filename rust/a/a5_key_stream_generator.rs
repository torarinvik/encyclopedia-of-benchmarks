#[derive(Clone, Copy)]
struct State { r1: u32, r2: u32, r3: u32 }

fn parity(mut x: u32) -> u32 { x ^= x >> 16; x ^= x >> 8; x ^= x >> 4; x ^= x >> 2; x ^= x >> 1; x & 1 }
fn fb1(s: &State) -> u32 { parity(s.r1 & ((1<<13)|(1<<16)|(1<<17)|(1<<18))) }
fn fb2(s: &State) -> u32 { parity(s.r2 & ((1<<20)|(1<<21))) }
fn fb3(s: &State) -> u32 { parity(s.r3 & ((1<<7)|(1<<20)|(1<<21)|(1<<22))) }
fn push(r: u32, n: u32, bit: u32) -> u32 { ((r << 1) | bit) & ((1u32 << n) - 1) }
fn initialize(key: u64, frame: u32) -> State {
    let mut s = State { r1: 0, r2: 0, r3: 0 };
    for i in (0..64).rev() { let b = ((key >> i) & 1) as u32; s.r1=push(s.r1,19,b^fb1(&s)); s.r2=push(s.r2,22,b^fb2(&s)); s.r3=push(s.r3,23,b^fb3(&s)); }
    for i in (0..22).rev() { let b=(frame>>i)&1; s.r1=push(s.r1,19,b^fb1(&s)); s.r2=push(s.r2,22,b^fb2(&s)); s.r3=push(s.r3,23,b^fb3(&s)); }
    s
}
fn tick(s: &mut State) -> u32 {
    let (c1,c2,c3)=((s.r1>>8)&1,(s.r2>>10)&1,(s.r3>>10)&1); let majority=(c1+c2+c3>=2) as u32;
    let out=((s.r1>>18)^(s.r2>>21)^(s.r3>>22))&1;
    if c1==majority { s.r1=push(s.r1,19,fb1(s)); } if c2==majority { s.r2=push(s.r2,22,fb2(s)); } if c3==majority { s.r3=push(s.r3,23,fb3(s)); } out
}
fn next_frame(mut f: u32) -> u32 { for i in (0..22).rev() { let mask=1u32<<i; if f&mask==0 { return f|mask; } f&=!mask; } f }

#[no_mangle]
pub unsafe extern "C" fn a5_key_stream_generator(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let data = std::slice::from_raw_parts(input, length);
    if !(1..=4).contains(&data[2]) { return -1; }
    let blocks = data[2] as usize;
    let bytes = 29 * blocks;
    if output.is_null() || capacity < bytes { return -2; }
    let out = std::slice::from_raw_parts_mut(output, bytes);
    let key = data[0] as u64;
    let mut frame = (data[1] as u64 as u32) & 0x3fffff;
    for block in 0..blocks {
        let mut state = initialize(key, frame);
        for _ in 0..100 { let _ = tick(&mut state); }
        let dst = &mut out[29 * block..29 * (block + 1)];
        dst.fill(0);
        for bit in 0..228 {
            let value = tick(&mut state) as u8;
            dst[bit / 8] |= value << (bit % 8);
        }
        frame = next_frame(frame);
    }
    bytes as i64
}
