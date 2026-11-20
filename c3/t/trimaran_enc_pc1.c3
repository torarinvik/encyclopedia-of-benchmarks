module trimaran_enc_pc1;

const long MAX_NUM_INPUT = 2049;

struct Pc1State { ushort[16] words; ushort si; ushort x1a2; }

fn ushort code_step(Pc1State* state, int index) {
    ushort dx = (ushort)((uint)state.x1a2 + (uint)index);
    ushort ax = state.words[index];
    ushort cx = 0x015a;
    ushort bx = 0x4e35;
    ushort tmp = ax;
    ax = state.si; state.si = tmp; tmp = ax; ax = dx; dx = tmp;
    if (ax != 0) ax = (ushort)(((uint)ax * (uint)bx) & 65535);
    tmp = ax; ax = cx; cx = tmp;
    if (ax != 0) {
        ax = (ushort)(((uint)ax * (uint)state.si) & 65535);
        cx = (ushort)((uint)ax + (uint)cx);
    }
    tmp = ax; ax = state.si; state.si = tmp;
    ax = (ushort)(((uint)ax * (uint)bx) & 65535);
    dx = (ushort)((uint)cx + (uint)dx); ax = (ushort)((uint)ax + 1);
    state.x1a2 = dx; state.words[index] = ax;
    return ax ^ dx;
}

fn ushort assemble(Pc1State* state, char* key) {
    state.words[0] = (ushort)(((uint)key[0] << 8) | (uint)key[1]);
    ushort inter = code_step(state, 0);
    for (int i = 1; i < 16; i++) {
        ushort word = (ushort)(((uint)key[2 * i] << 8) | (uint)key[2 * i + 1]);
        state.words[i] = state.words[i - 1] ^ word;
        inter = inter ^ code_step(state, i);
    }
    return inter;
}

fn long trimaran_enc_pc1(long* input, usz length) @export("trimaran_enc_pc1") {
    if (input == null || length != 1 || input[0] < 1 || input[0] > MAX_NUM_INPUT) return -1;
    char[32] key = { 'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p',
                      'q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5' };
    Pc1State state = {};
    ushort last = 0;
    uint seed = 1;
    for (long step = 0; step < input[0] - 1; step++) {
        seed = (uint)(((ulong)seed * 1664525ul + 1013904223ul) & 0xfffffffful);
        ushort plain = (ushort)((seed >> 16) & 0x7fff);
        ushort inter = assemble(&state, &key[0]);
        ushort cipher = plain ^ ((inter >> 8) ^ (inter & 255));
        char feedback = (char)plain;
        for (usz i = 0; i < 32; i++) key[i] = key[i] ^ feedback;
        last = cipher;
    }
    return (long)last;
}
