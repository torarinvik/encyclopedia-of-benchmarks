fn ideaMul(left: u16, right: u16) u16 {
    const a: u64 = if (left == 0) 65536 else left;
    const b: u64 = if (right == 0) 65536 else right;
    const residue = (a * b) % 65537;
    return if (residue == 65536) 0 else @intCast(residue);
}

fn ideaInverse(value: u16) u16 {
    var old_r: i64 = 65537;
    var r: i64 = if (value == 0) 65536 else value;
    var old_s: i64 = 0;
    var s: i64 = 1;
    while (r != 0) {
        const quotient = @divTrunc(old_r, r);
        const next_r = old_r - quotient * r;
        const next_s = old_s - quotient * s;
        old_r = r; r = next_r; old_s = s; s = next_s;
    }
    var residue = @mod(old_s, 65537);
    if (residue == 65536) return 0;
    return @intCast(residue);
}

fn expandKey(key: [8]u16) [52]u16 {
    var state = key;
    var keys: [52]u16 = [_]u16{0} ** 52;
    var offset: usize = 0;
    while (offset < 52) {
        const amount: usize = @min(8, 52 - offset);
        for (0..amount) |i| keys[offset + i] = state[i];
        var rotated: [8]u16 = undefined;
        for (0..8) |i| {
            rotated[i] = @truncate((@as(u32, state[(i + 1) & 7]) << 9) | (@as(u32, state[(i + 2) & 7]) >> 7));
        }
        state = rotated;
        offset += amount;
    }
    return keys;
}

fn encryptBlock(key: [52]u16, block: [4]u16) [4]u16 {
    var x1 = block[0]; var x2 = block[1]; var x3 = block[2]; var x4 = block[3];
    for (0..8) |round| {
        const k = round * 6;
        const a = ideaMul(x1, key[k]);
        const b = x2 +% key[k + 1];
        const c = x3 +% key[k + 2];
        const d = ideaMul(x4, key[k + 3]);
        const p = ideaMul(a ^ c, key[k + 4]);
        const q = ideaMul((b ^ d) +% p, key[k + 5]);
        const r = p +% q;
        x1 = a ^ q; x2 = c ^ q; x3 = b ^ r; x4 = d ^ r;
    }
    return .{ ideaMul(x1, key[48]), x3 +% key[49], x2 +% key[50], ideaMul(x4, key[51]) };
}

fn decryptBlock(key: [52]u16, cipher: [4]u16) [4]u16 {
    var x1 = ideaMul(cipher[0], ideaInverse(key[48]));
    var x2 = cipher[2] -% key[50];
    var x3 = cipher[1] -% key[49];
    var x4 = ideaMul(cipher[3], ideaInverse(key[51]));
    var step: usize = 8;
    while (step > 0) {
        step -= 1;
        const k = step * 6;
        const p = ideaMul(x1 ^ x2, key[k + 4]);
        const q = ideaMul((x3 ^ x4) +% p, key[k + 5]);
        const r = p +% q;
        const a = x1 ^ q; const c = x2 ^ q; const b = x3 ^ r; const d = x4 ^ r;
        x1 = ideaMul(a, ideaInverse(key[k]));
        x2 = b -% key[k + 1]; x3 = c -% key[k + 2];
        x4 = ideaMul(d, ideaInverse(key[k + 3]));
    }
    return .{ x1, x2, x3, x4 };
}

export fn idea_encrypt_decrypt(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 12) return -1;
    var key_words: [8]u16 = undefined;
    var block: [4]u16 = undefined;
    for (0..12) |i| {
        if (input[i] < 0 or input[i] > 65535) return -1;
        if (i < 8) key_words[i] = @intCast(input[i]) else block[i - 8] = @intCast(input[i]);
    }
    if (output == null or capacity < 16) return -2;
    const keys = expandKey(key_words);
    const encrypted = encryptBlock(keys, block);
    const recovered = decryptBlock(keys, encrypted);
    for (0..4) |i| {
        output[i * 2] = @truncate(encrypted[i]); output[i * 2 + 1] = @truncate(encrypted[i] >> 8);
        output[8 + i * 2] = @truncate(recovered[i]); output[9 + i * 2] = @truncate(recovered[i] >> 8);
    }
    return 16;
}
