const MD5_SHIFTS: [64]u32 = .{
    7,12,17,22,7,12,17,22,7,12,17,22,7,12,17,22,
    5,9,14,20,5,9,14,20,5,9,14,20,5,9,14,20,
    4,11,16,23,4,11,16,23,4,11,16,23,4,11,16,23,
    6,10,15,21,6,10,15,21,6,10,15,21,6,10,15,21,
};
const MD5_K: [64]u32 = .{
    0xd76aa478,0xe8c7b756,0x242070db,0xc1bdceee,0xf57c0faf,0x4787c62a,0xa8304613,0xfd469501,
    0x698098d8,0x8b44f7af,0xffff5bb1,0x895cd7be,0x6b901122,0xfd987193,0xa679438e,0x49b40821,
    0xf61e2562,0xc040b340,0x265e5a51,0xe9b6c7aa,0xd62f105d,0x02441453,0xd8a1e681,0xe7d3fbc8,
    0x21e1cde6,0xc33707d6,0xf4d50d87,0x455a14ed,0xa9e3e905,0xfcefa3f8,0x676f02d9,0x8d2a4c8a,
    0xfffa3942,0x8771f681,0x6d9d6122,0xfde5380c,0xa4beea44,0x4bdecfa9,0xf6bb4b60,0xbebfbc70,
    0x289b7ec6,0xeaa127fa,0xd4ef3085,0x04881d05,0xd9d4d039,0xe6db99e5,0x1fa27cf8,0xc4ac5665,
    0xf4292244,0x432aff97,0xab9423a7,0xfc93a039,0x655b59c3,0x8f0ccc92,0xffeff47d,0x85845dd1,
    0x6fa87e4f,0xfe2ce6e0,0xa3014314,0x4e0811a1,0xf7537e82,0xbd3af235,0x2ad7d2bb,0xeb86d391,
};

fn md5Add32(left: u32, right: u32) u32 {
    return @truncate((@as(u64, left) + @as(u64, right)) & 0xffff_ffff);
}

fn md5RotateLeft(value: u32, amount: u32) u32 {
    const left: u5 = @intCast(amount);
    const right: u5 = @intCast(32 - amount);
    return (value << left) | (value >> right);
}

fn md5Byte(input: [*c]const i64, length: usize, padded_length: usize,
           bit_length: u64, position: usize) u32 {
    if (position < length) return @intCast(input[position]);
    if (position == length) return 0x80;
    if (position >= padded_length - 8) {
        const shift: u6 = @intCast(8 * (position - (padded_length - 8)));
        return @truncate((bit_length >> shift) & 0xff);
    }
    return 0;
}

fn md5Word(input: [*c]const i64, length: usize, padded_length: usize,
            bit_length: u64, block_offset: usize, word_index: usize) u32 {
    var word: u32 = 0;
    const start = block_offset + word_index * 4;
    for (0..4) |byte| {
        const shift: u5 = @intCast(8 * byte);
        word |= md5Byte(input, length, padded_length, bit_length, start + byte) << shift;
    }
    return word;
}

export fn md5(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (length > 4096 or (length != 0 and input == null)) return -1;
    for (0..length) |index| {
        if (input[index] < 0 or input[index] > 255) return -1;
    }
    if (output == null or capacity < 16) return -2;

    const padded_length = ((length + 8) / 64 + 1) * 64;
    const bit_length: u64 = @as(u64, @intCast(length)) * 8;
    var h0: u32 = 0x67452301;
    var h1: u32 = 0xefcdab89;
    var h2: u32 = 0x98badcfe;
    var h3: u32 = 0x10325476;
    var offset: usize = 0;
    while (offset < padded_length) : (offset += 64) {
        var words: [16]u32 = @splat(0);
        for (0..16) |index| words[index] = md5Word(input, length, padded_length, bit_length, offset, index);
        var a = h0;
        var b = h1;
        var c = h2;
        var d = h3;
        for (0..64) |index| {
            var f: u32 = 0;
            var g: usize = 0;
            if (index < 16) {
                f = (b & c) | (~b & d);
                g = index;
            } else if (index < 32) {
                f = (d & b) | (~d & c);
                g = (5 * index + 1) % 16;
            } else if (index < 48) {
                f = b ^ c ^ d;
                g = (3 * index + 5) % 16;
            } else {
                f = c ^ (b | ~d);
                g = (7 * index) % 16;
            }
            const total = md5Add32(md5Add32(md5Add32(a, f), MD5_K[index]), words[g]);
            const previous_d = d;
            d = c;
            c = b;
            b = md5Add32(b, md5RotateLeft(total, MD5_SHIFTS[index]));
            a = previous_d;
        }
        h0 = md5Add32(h0, a);
        h1 = md5Add32(h1, b);
        h2 = md5Add32(h2, c);
        h3 = md5Add32(h3, d);
    }
    const state = [4]u32{h0, h1, h2, h3};
    for (0..4) |word| {
        for (0..4) |byte| {
            const shift: u5 = @intCast(8 * byte);
            output[word * 4 + byte] = @truncate(state[word] >> shift);
        }
    }
    return 16;
}
