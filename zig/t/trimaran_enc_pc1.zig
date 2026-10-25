// Pukall Cipher 1 adaptation; source author Alexander Pukall (1991), unrestricted use.
const MAX_NUM_INPUT: i64 = 2049;

const State = struct { words: [16]u16 = .{0} ** 16, si: u16 = 0, x1a2: u16 = 0 };

fn codeStep(s: *State, index: usize) u16 {
    var dx = s.x1a2 +% @as(u16, @intCast(index));
    var ax = s.words[index];
    var cx: u16 = 0x015a;
    const bx: u16 = 0x4e35;
    var tmp = ax;
    ax = s.si; s.si = tmp; tmp = ax; ax = dx; dx = tmp;
    if (ax != 0) ax = ax *% bx;
    tmp = ax; ax = cx; cx = tmp;
    if (ax != 0) { ax = ax *% s.si; cx = cx +% ax; }
    tmp = ax; ax = s.si; s.si = tmp;
    ax = ax *% bx;
    dx = dx +% cx;
    ax = ax +% 1;
    s.x1a2 = dx; s.words[index] = ax;
    return ax ^ dx;
}

fn assemble(s: *State, key: *const [32]u8) u16 {
    s.words[0] = (@as(u16, key[0]) << 8) | key[1];
    var inter = codeStep(s, 0);
    for (1..16) |i| {
        const word = (@as(u16, key[2 * i]) << 8) | key[2 * i + 1];
        s.words[i] = s.words[i - 1] ^ word;
        inter ^= codeStep(s, i);
    }
    return inter;
}

export fn trimaran_enc_pc1(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 1 or input[0] < 1 or input[0] > MAX_NUM_INPUT) return -1;
    var key: [32]u8 = "abcdefghijklmnopqrstuvwxyz012345".*;
    var state = State{};
    var seed: u32 = 1;
    var last: u16 = 0;
    var step: i64 = 0;
    while (step < input[0] - 1) : (step += 1) {
        seed = seed *% 1664525 +% 1013904223;
        const plain: u16 = @intCast((seed >> 16) & 0x7fff);
        const inter = assemble(&state, &key);
        const cipher = plain ^ ((inter >> 8) ^ (inter & 255));
        const feedback: u8 = @truncate(plain);
        for (&key) |*byte| byte.* ^= feedback;
        last = cipher;
    }
    return last;
}
