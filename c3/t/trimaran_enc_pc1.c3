module trimaran_enc_pc1;

const long MAX_NUM_INPUT = 2049;

struct Pc1State { ushort[16] words; ushort si; ushort x1a2; }

fn ushort code_step(Pc1State* state, int index) {
    ushort dx = (state.x1a2 + index.ushort()).ushort();
    ushort ax = state.words[index];
    ushort cx = 0x015a;
    ushort bx = 0x4e35;
    ushort tmp = ax;
    ax = state.si; state.si = tmp; tmp = ax; ax = dx; dx = tmp;
    if (ax != 0) ax = ((ax.uint() * bx.uint()) & 65535).ushort();
    tmp = ax; ax = cx; cx = tmp;
    if (ax != 0) {
        ax = ((ax.uint() * state.si.uint()) & 65535).ushort();
        cx = (ax + cx).ushort();
    }
    tmp = ax; ax = state.si; state.si = tmp;
    ax = ((ax.uint() * bx.uint()) & 65535).ushort();
    dx = (cx + dx).ushort(); ax = (ax + 1).ushort();
    state.x1a2 = dx; state.words[index] = ax;
    ax ^ dx
}

fn ushort assemble(Pc1State* state, uchar* key) {
    state.words[0] = ((key[0].ushort() << 8) | key[1].ushort()).ushort();
    ushort inter = code_step(state, 0);
    for (int i = 1; i < 16; i++) {
        ushort word = ((key[2 * i].ushort() << 8) | key[2 * i + 1].ushort()).ushort();
        state.words[i] = state.words[i - 1] ^ word;
        inter = inter ^ code_step(state, i);
    }
    inter
}

fn long trimaran_enc_pc1(long* input, usz length) @export("trimaran_enc_pc1") {
    if (input == null || length != 1 || input[0] < 1 || input[0] > MAX_NUM_INPUT) return -1;
    uchar[32] key = { 'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p',
                      'q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5' };
    Pc1State state = {};
    ushort last = 0;
    uint seed = 1;
    for (long step = 0; step < input[0] - 1; step++) {
        seed = ((seed.ulong() * 1664525u64 + 1013904223u64) & 0xffffffffu64).uint();
        ushort plain = ((seed >> 16) & 0x7fff).ushort();
        ushort inter = assemble(&state, &key[0]);
        ushort cipher = plain ^ ((inter >> 8) ^ (inter & 255));
        uchar feedback = plain.uchar();
        for (usz i = 0; i < 32; i++) key[i] = key[i] ^ feedback;
        last = cipher;
    }
    last.long()
}
