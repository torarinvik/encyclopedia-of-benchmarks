module rotate_left32;

fn long rotate_left32(ulong value, ulong shift) @export("rotate_left32") {
    if (value > 4294967295 || shift > 2147483647) return -1;
    ulong bits = value;
    ulong amount = shift % 32;
    if (amount == 0) return (long)bits;
    return (long)(((bits << amount) | (bits >> (32 - amount))) & 4294967295);
}
