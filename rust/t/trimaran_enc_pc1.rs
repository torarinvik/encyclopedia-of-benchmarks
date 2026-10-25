// Pukall Cipher 1 adaptation; source author Alexander Pukall (1991), unrestricted use.
const MAX_NUM_INPUT: i64 = 2049;
#[derive(Default)]
struct State { words: [u16; 16], si: u16, x1a2: u16 }

fn code_step(s: &mut State, index: usize) -> u16 {
    let mut dx = s.x1a2.wrapping_add(index as u16);
    let mut ax = s.words[index];
    let mut cx = 0x015au16;
    let bx = 0x4e35u16;
    let mut tmp = ax;
    ax = s.si; s.si = tmp; tmp = ax; ax = dx; dx = tmp;
    if ax != 0 { ax = ax.wrapping_mul(bx); }
    tmp = ax; ax = cx; cx = tmp;
    if ax != 0 { ax = ax.wrapping_mul(s.si); cx = cx.wrapping_add(ax); }
    tmp = ax; ax = s.si; s.si = tmp;
    ax = ax.wrapping_mul(bx);
    dx = dx.wrapping_add(cx);
    ax = ax.wrapping_add(1);
    s.x1a2 = dx; s.words[index] = ax;
    ax ^ dx
}

fn assemble(s: &mut State, key: &[u8; 32]) -> u16 {
    s.words[0] = u16::from_be_bytes([key[0], key[1]]);
    let mut inter = code_step(s, 0);
    for i in 1..16 {
        let word = u16::from_be_bytes([key[2*i], key[2*i+1]]);
        s.words[i] = s.words[i-1] ^ word;
        inter ^= code_step(s, i);
    }
    inter
}

#[no_mangle]
pub unsafe extern "C" fn trimaran_enc_pc1(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let count = *input;
    if !(1..=MAX_NUM_INPUT).contains(&count) { return -1; }
    let mut key = *b"abcdefghijklmnopqrstuvwxyz012345";
    let mut state = State::default();
    let mut seed = 1u32;
    let mut last = 0u16;
    for _ in 0..(count - 1) {
        seed = seed.wrapping_mul(1664525).wrapping_add(1013904223);
        let plain = ((seed >> 16) & 0x7fff) as u16;
        let inter = assemble(&mut state, &key);
        let cipher = plain ^ ((inter >> 8) ^ (inter & 255));
        for byte in &mut key { *byte ^= plain as u8; }
        last = cipher;
    }
    last as i64
}
