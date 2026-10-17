module sdes;

const u8[8] P8 = {6,3,7,4,8,5,10,9};
const u8[10] P10 = {3,5,2,7,4,10,1,9,8,6};
const u8[4] P4 = {2,4,3,1};
const u8[8] IP = {2,6,3,1,4,8,5,7};
const u8[8] IP_INV = {4,1,3,5,7,2,8,6};
const u8[8] EXPANSION = {4,1,2,3,2,3,4,1};
const u8[32] SBOXES = {1,0,3,2,3,2,1,0,0,2,1,3,3,1,3,2,0,1,2,3,2,0,1,3,3,0,1,0,2,1,0,3};

fn uint table_value(uint table, usz index) {
    if (table == 0) return P8[index];
    if (table == 1) return P10[index];
    if (table == 2) return IP[index];
    if (table == 3) return IP_INV[index];
    if (table == 4) return EXPANSION[index];
    return P4[index];
}

fn uint permute(uint value, uint input_bits, uint table, usz count) {
    uint result = 0;
    for (usz index = 0; index < count; index += 1) {
        uint position = table_value(table, index);
        result = (result << 1) | ((value >> (input_bits - position)) & 1);
    }
    return result;
}

fn uint rotate5(uint value, uint amount) {
    return ((value << amount) | (value >> (5 - amount))) & 31;
}

fn uint subkey(uint key, uint round) {
    uint selected = permute(key, 10, 1, 10);
    uint left = selected >> 5;
    uint right = selected & 31;
    left = rotate5(left, 1);
    right = rotate5(right, 1);
    if (round != 0) {
        left = rotate5(left, 2);
        right = rotate5(right, 2);
    }
    return permute((left << 5) | right, 10, 0, 8);
}

fn uint sbox_value(uint box, uint nibble) {
    uint row = ((nibble & 8) >> 2) | (nibble & 1);
    uint column = (nibble >> 1) & 3;
    return SBOXES[box * 16 + row * 4 + column];
}

fn uint fk(uint state, uint key) {
    uint left = state >> 4;
    uint right = state & 15;
    uint mixed = permute(right, 4, 4, 8) ^ key;
    uint substituted = (sbox_value(0, mixed >> 4) << 2) | sbox_value(1, mixed & 15);
    return ((left ^ permute(substituted, 4, 5, 4)) << 4) | right;
}

fn uint crypt(uint message, uint key, bool decrypt) {
    uint first = subkey(key, 0);
    uint second = subkey(key, 1);
    uint state = permute(message, 8, 2, 8);
    state = fk(state, decrypt ? second : first);
    state = ((state & 15) << 4) | (state >> 4);
    state = fk(state, decrypt ? first : second);
    return permute(state, 8, 3, 8);
}

// Return ciphertext and the plaintext recovered with the reversed subkeys.
fn long sdes(long* input, usz length, char* output, usz output_capacity)
    @export("sdes") {
    if (input == null || length != 2) return -1;
    if (input[0] < 0 || input[0] > 1023 || input[1] < 0 || input[1] > 255) return -1;
    if (output == null || output_capacity < 2) return -2;
    uint key = (uint)input[0];
    uint ciphertext = crypt((uint)input[1], key, false);
    uint recovered = crypt(ciphertext, key, true);
    output[0] = (char)ciphertext;
    output[1] = (char)recovered;
    return 2;
}
