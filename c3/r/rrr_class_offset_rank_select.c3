module rrr_class_offset_rank_select;

fn int popcount_byte(uint value) {
    int count = 0;
    for (uint bit = 0; bit < 8; bit++) count += (int)((value >> bit) & 1);
    return count;
}

fn uint decode(int cls, int offset) {
    for (uint candidate = 0; candidate < 256; candidate++) {
        if (popcount_byte(candidate) == cls) {
            if (offset == 0) return candidate;
            offset--;
        }
    }
    return 0;
}

fn long rrr_class_offset_rank_select(long* input, usz length, char* output, usz capacity) @export("rrr_class_offset_rank_select") {
    if (input == null || length < 3 || length > 35 || input[0] < 1 || input[0] > 63 || input[1] < 0 || input[2] < 0 || input[2] > 16) return -1;
    usz n = (usz)input[0], q = (usz)input[2];
    ulong bits = (ulong)input[1];
    if ((bits >> n) != 0 || length != 3+2*q) return -1;
    for (usz i = 0; i < q; i++) {
        long op = input[3+2*i], index = input[4+2*i];
        if ((op != 0 && op != 1) || index < 1 || (op == 0 && index > (long)n) || (op == 1 && index > 64)) return -1;
    }
    if (output == null || capacity < 8*q) return -2;
    int[8] classes = {}, offsets = {};
    int[9] prefix = {};
    usz blocks = (n+7)/8;
    for (usz block = 0; block < blocks; block++) {
        uint byte = (uint)((bits >> (8*block)) & 255);
        classes[block] = popcount_byte(byte);
        for (uint candidate = 0; candidate < byte; candidate++) if (popcount_byte(candidate) == classes[block]) offsets[block]++;
        prefix[block+1] = prefix[block]+classes[block];
    }
    for (usz i = 0; i < q; i++) {
        long op = input[3+2*i];
        usz index = (usz)input[4+2*i];
        long answer = -1;
        if (op == 0) {
            usz block = (index-1)/8;
            uint byte = decode(classes[block], offsets[block]);
            answer = prefix[block];
            for (usz bit = 0; bit < index-8*block; bit++) answer += (long)((byte >> bit) & 1);
        } else {
            usz block = 0;
            while (block < blocks && prefix[block+1] < (int)index) block++;
            if (block < blocks) {
                int remaining = (int)index-prefix[block];
                uint byte = decode(classes[block], offsets[block]);
                for (usz bit = 0; bit < 8 && 8*block+bit < n; bit++) {
                    if (((byte >> bit) & 1) != 0) {
                        remaining--;
                        if (remaining == 0) { answer = (long)(8*block+bit+1); break; }
                    }
                }
            }
        }
        ulong encoded = (ulong)answer;
        for (usz byte = 0; byte < 8; byte++) { output[8*i+byte] = (char)(encoded & 255); encoded >>= 8; }
    }
    return (long)(8*q);
}
