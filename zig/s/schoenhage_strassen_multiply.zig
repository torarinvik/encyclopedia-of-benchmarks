// Fresh bounded port based on NyaanNyaan's CC0 radix-2 Schönhage-Strassen method.
const LIMBS: usize = 513;
const PADDED: usize = 2048;
const SCRATCH: usize = 4096;
const OUTPUT_BYTES: usize = 129;

fn ssZero(a: [*]i64, n: usize) void { for (0..n) |i| a[i] = 0; }
fn ssCopy(dst: [*]i64, src: [*]const i64, n: usize) void { for (0..n) |i| dst[i] = src[i]; }
fn ssAdd(dst: [*]i64, src: [*]const i64, n: usize) void { for (0..n) |i| dst[i] += src[i]; }
fn ssSub(dst: [*]i64, src: [*]const i64, n: usize) void { for (0..n) |i| dst[i] -= src[i]; }

fn ssRot(dst: [*]i64, src: [*]const i64, size: usize, shift: usize) void {
    const wrapped = shift >= size;
    const d = if (wrapped) shift - size else shift;
    var i: usize = 0;
    if (wrapped) {
        while (i < size - d) : (i += 1) dst[i + d] = -src[i];
        while (i < size) : (i += 1) dst[i + d - size] = src[i];
    } else {
        while (i < size - d) : (i += 1) dst[i + d] = src[i];
        while (i < size) : (i += 1) dst[i + d - size] = -src[i];
    }
}

fn ssCtz(value: usize) usize {
    var x = value;
    var bits: usize = 0;
    while ((x & 1) == 0) : (x >>= 1) bits += 1;
    return bits;
}

fn ssFft(a: [*]i64, l: usize, m: usize, buf: [*]i64) void {
    if (l == 0) return;
    const len = @as(usize, 1) << @intCast(l);
    const block = @as(usize, 1) << @intCast(m);
    var dw = [_]i32{0} ** 16;
    for (0..l - 1) |i| {
        var value: i32 = (@as(i32, 1) << @intCast(l - 2 - i)) + (@as(i32, 1) << @intCast(l - 1 - i)) - (@as(i32, 1) << @intCast(l - 1));
        if (value < 0) value += @intCast(len);
        if (len == block) value *= 2;
        if (2 * len == block) value *= 4;
        dw[i] = value;
    }
    var d = len / 2;
    while (d > 0) : (d /= 2) {
        var w: i32 = 0;
        var s: usize = 0;
        var k: usize = 0;
        while (true) {
            for (s..s + d) |i| {
                const ai = a + i * block;
                const aj = a + (i + d) * block;
                ssRot(buf, aj, block, @intCast(w));
                ssCopy(aj, ai, block);
                ssAdd(ai, buf, block);
                ssSub(aj, buf, block);
            }
            s += 2 * d;
            if (s >= len) break;
            k += 1;
            w += dw[ssCtz(k)];
            if (w >= 2 * @as(i32, @intCast(block))) w -= 2 * @as(i32, @intCast(block));
        }
    }
}

fn ssIfft(a: [*]i64, l: usize, m: usize, buf: [*]i64) void {
    if (l == 0) return;
    const len = @as(usize, 1) << @intCast(l);
    const block = @as(usize, 1) << @intCast(m);
    var dw = [_]i32{0} ** 16;
    for (0..l - 1) |i| {
        var value: i32 = (@as(i32, 1) << @intCast(l - 2 - i)) + (@as(i32, 1) << @intCast(l - 1 - i)) - (@as(i32, 1) << @intCast(l - 1));
        if (value < 0) value += @intCast(len);
        if (len == block) value *= 2;
        if (2 * len == block) value *= 4;
        dw[i] = value;
    }
    var d: usize = 1;
    while (d < len) : (d *= 2) {
        var w: i32 = 0;
        var s: usize = 0;
        var k: usize = 0;
        while (true) {
            for (s..s + d) |i| {
                const ai = a + i * block;
                const aj = a + (i + d) * block;
                ssCopy(buf, ai, block);
                ssAdd(ai, aj, block);
                ssSub(buf, aj, block);
                ssRot(aj, buf, block, @intCast(w));
            }
            s += 2 * d;
            if (s >= len) break;
            k += 1;
            w -= dw[ssCtz(k)];
            if (w < 0) w += 2 * @as(i32, @intCast(block));
        }
    }
}

fn ssNaive(a: [*]i64, b: [*]const i64, n: usize, buf: [*]i64) void {
    const size = @as(usize, 1) << @intCast(n);
    ssZero(buf, size);
    for (0..size) |i| {
        var j: usize = 0;
        while (j < size - i) : (j += 1) buf[i + j] += a[i] * b[j];
        while (j < size) : (j += 1) buf[i + j - size] -= a[i] * b[j];
    }
    ssCopy(a, buf, size);
}

fn ssMul(a: [*]i64, b: [*]const i64, n: usize, buf: [*]i64) void {
    if (n <= 5) { ssNaive(a, b, n, buf); return; }
    const l = (n + 1) / 2;
    const m = n / 2;
    const len = @as(usize, 1) << @intCast(l);
    const block = @as(usize, 1) << @intCast(m);
    var aa = [_]i64{0} ** SCRATCH;
    var bb = [_]i64{0} ** SCRATCH;
    ssZero(buf + block, block);
    for (0..len) |i| {
        const s = i * (2 * block / len);
        ssCopy(buf, a + i * block, block);
        ssRot(&aa[i * block * 2], buf, 2 * block, s);
        ssCopy(buf, b + i * block, block);
        ssRot(&bb[i * block * 2], buf, 2 * block, s);
    }
    ssFft(&aa[0], l, m + 1, buf);
    ssFft(&bb[0], l, m + 1, buf);
    for (0..len) |i| ssMul(&aa[i * block * 2], &bb[i * block * 2], m + 1, buf);
    ssIfft(&aa[0], l, m + 1, buf);
    for (0..len) |i| {
        const s = i * (2 * block / len);
        ssCopy(buf, &aa[i * block * 2], 2 * block);
        ssRot(&aa[i * block * 2], buf, 2 * block, s);
    }
    for (0..len) |i| {
        for (0..block) |j| {
            const index = i * block + j;
            aa[index] = aa[i * block * 2 + j];
            if (i == 0) {
                aa[index] -= aa[(len - 1) * block * 2 + block + j];
            } else {
                aa[index] += aa[(i - 1) * block * 2 + block + j];
            }
        }
    }
    for (0..len * block) |i| a[i] = aa[i];
}

fn ssMulCyclic(a: [*]i64, b: [*]const i64, n: usize, buf: [*]i64) void {
    if (n <= 5) { ssNaive(a, b, n, buf); return; }
    const l = (n + 1) / 2;
    const m = n / 2;
    const len = @as(usize, 1) << @intCast(l);
    const block = @as(usize, 1) << @intCast(m);
    var aa = [_]i64{0} ** SCRATCH;
    var bb = [_]i64{0} ** SCRATCH;
    for (0..len) |i| {
        ssCopy(&aa[i * block * 2], a + i * block, block);
        ssCopy(&bb[i * block * 2], b + i * block, block);
    }
    ssFft(&aa[0], l, m + 1, buf);
    ssFft(&bb[0], l, m + 1, buf);
    for (0..len) |i| ssMul(&aa[i * block * 2], &bb[i * block * 2], m + 1, buf);
    ssIfft(&aa[0], l, m + 1, buf);
    for (0..len) |i| {
        for (0..block) |j| {
            const prev = if (i == 0) len - 1 else i - 1;
            a[i * block + j] = aa[i * block * 2 + j] + aa[prev * block * 2 + block + j];
        }
    }
}

export fn schoenhage_strassen_multiply(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length != 1 + 2 * LIMBS) return -1;
    const values = input.?;
    if (values[0] != LIMBS) return -1;
    var a = [_]i64{0} ** PADDED;
    var b = [_]i64{0} ** PADDED;
    var scratch = [_]i64{0} ** PADDED;
    for (0..LIMBS) |i| {
        const x = values[1 + i];
        const y = values[1 + LIMBS + i];
        if (x < 0 or x > 1 or y < 0 or y > 1) return -1;
        a[i] = x; b[i] = y;
    }
    if (a[LIMBS - 1] != 1 or b[LIMBS - 1] != 1) return -1;
    if (output == null or capacity < OUTPUT_BYTES) return -2;
    ssMulCyclic(&a[0], &b[0], 11, &scratch[0]);
    var result = [_]u8{0} ** OUTPUT_BYTES;
    var carry: i64 = 0;
    for (0..1025) |i| {
        const value = a[i] + carry;
        const bit: u8 = @intCast(@mod(value, 2));
        carry = @divTrunc(value, 2);
        if (bit != 0) result[OUTPUT_BYTES - 1 - i / 8] |= bit << @intCast(i % 8);
    }
    var bit_index: usize = 1025;
    while (carry > 0) {
        if (@mod(carry, 2) != 0) result[OUTPUT_BYTES - 1 - bit_index / 8] |= @as(u8, 1) << @intCast(bit_index % 8);
        carry = @divTrunc(carry, 2);
        bit_index += 1;
    }
    const out = output.?;
    for (0..OUTPUT_BYTES) |i| out[i] = result[i];
    return OUTPUT_BYTES;
}
