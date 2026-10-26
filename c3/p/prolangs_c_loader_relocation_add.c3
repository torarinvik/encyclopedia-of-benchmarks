module prolangs_c_loader_relocation_add;

// Copyright (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
fn long prolangs_c_loader_relocation_add(long* input, usz length, char* output, usz capacity)
    @export("prolangs_c_loader_relocation_add") {
    if (input == null || length < 3 || length > 5) return -1;
    if (input[0] < 1 || input[0] > 6 || input[1] < -65535 || input[1] > 65535) return -1;
    usz width = (input[0].usz() + 1) / 2;
    if (length != 2 + width) return -1;
    ulong field = 0;
    for (usz i = 0; i < width; i++) {
        if (input[2 + i] < 0 || input[2 + i] > 255) return -1;
        field = field * 256 + input[2 + i].ulong();
    }
    long adjusted = field.long() + input[1];
    if (adjusted < 0) return -1;
    if (capacity < width || output == null) return -2;
    ulong result = adjusted.ulong();
    for (usz i = width; i > 0; i--) { output[i - 1] = (char)(result & 255); result >>= 8; }
    return width.long();
}
