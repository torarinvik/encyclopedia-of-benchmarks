const MAX_N: usize = 32;
const MAX_Q: usize = 128;
const MAX_INPUT: usize = 419;
const T_BYTES: usize = 43;
const L_BYTES: usize = 128;
const T_MAX_BITS: usize = 340;
const NODE_CAP: usize = 256;

fn bitGet(bits: []const u8, index: usize) u8 {
    return (bits[index >> 3] >> @intCast(index & 7)) & 1;
}

fn bitSet(bits: []u8, index: usize) void {
    bits[index >> 3] |= @as(u8, 1) << @intCast(index & 7);
}

fn blockNonempty(rows: []const i64, rowOffset: usize, n: usize,
    rowStart: usize, colStart: usize, side: usize) bool {
    const mask = ((@as(u64, 1) << @intCast(side)) - 1) << @intCast(colStart);
    for (rowStart..rowStart + side) |row| {
        if (row < n and (@as(u64, @intCast(rows[rowOffset + row])) & mask) != 0) return true;
    }
    return false;
}

fn buildTree(values: []const i64, tBits: *[T_BYTES]u8, lBits: *[L_BYTES]u8,
    rankPrefix: *[T_MAX_BITS + 1]u16, currentRows: *[NODE_CAP]u8,
    currentCols: *[NODE_CAP]u8, nextRows: *[NODE_CAP]u8,
    nextCols: *[NODE_CAP]u8, n: usize) struct { t_len: usize, height: usize } {
    var side: usize = 2;
    var height: usize = 1;
    while (side < n) : (height += 1) side <<= 1;
    var currentCount: usize = 1;
    var currentSide = side;
    var tLen: usize = 0;
    var lLen: usize = 0;
    currentRows[0] = 0;
    currentCols[0] = 0;
    for (1..height + 1) |level| {
        const childSide = currentSide / 2;
        var nextCount: usize = 0;
        for (0..currentCount) |parent| {
            const parentRow: usize = currentRows[parent];
            const parentCol: usize = currentCols[parent];
            for (0..4) |quadrant| {
                const childRow = parentRow + (quadrant / 2) * childSide;
                const childCol = parentCol + (quadrant % 2) * childSide;
                const occupied = blockNonempty(values, 1, n, childRow, childCol, childSide);
                if (level < height) {
                    if (occupied) {
                        bitSet(tBits[0..], tLen);
                        nextRows[nextCount] = @intCast(childRow);
                        nextCols[nextCount] = @intCast(childCol);
                        nextCount += 1;
                    }
                    tLen += 1;
                } else {
                    if (occupied) bitSet(lBits[0..], lLen);
                    lLen += 1;
                }
            }
        }
        if (level < height) {
            for (0..nextCount) |i| {
                currentRows[i] = nextRows[i];
                currentCols[i] = nextCols[i];
            }
            currentCount = nextCount;
            currentSide = childSide;
        }
    }
    rankPrefix[0] = 0;
    for (0..tLen) |i| rankPrefix[i + 1] = rankPrefix[i] + @as(u16, bitGet(tBits[0..], i));
    return .{ .t_len = tLen, .height = height };
}

fn edgeQuery(tBits: []const u8, lBits: []const u8, tLen: usize,
    rankPrefix: []const u16, height: usize, u: usize, v: usize) bool {
    var parent: isize = -1;
    var rowStart: usize = 0;
    var colStart: usize = 0;
    var side: usize = 1 << @intCast(height);
    for (0..height) |_| {
        const childSide = side / 2;
        const rowBit: usize = if (u >= rowStart + childSide) 1 else 0;
        const colBit: usize = if (v >= colStart + childSide) 1 else 0;
        const quadrant = 2 * rowBit + colBit;
        const childBase: usize = if (parent < 0) 0 else 4 * @as(usize, rankPrefix[@intCast(parent) + 1]);
        const child = childBase + quadrant;
        if (rowBit != 0) rowStart += childSide;
        if (colBit != 0) colStart += childSide;
        if (child < tLen) {
            if (bitGet(tBits, child) == 0) return false;
            parent = @intCast(child);
        } else {
            return bitGet(lBits, child - tLen) != 0;
        }
        side = childSide;
    }
    return false;
}

fn putI64Le(output: [*]u8, offset: usize, value: u64) void {
    var bits = value;
    for (0..8) |byte| {
        output[offset + byte] = @truncate(bits);
        bits >>= 8;
    }
}

export fn k2_tree_compact_graph(inputOpt: ?[*]const i64, length: usize,
    outputOpt: ?[*]u8, capacity: usize) i64 {
    if (inputOpt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = inputOpt.?;
    const values = input[0..length];
    const nValue = values[0];
    if (nValue < 1 or nValue > @as(i64, @intCast(MAX_N)) or length < @as(usize, @intCast(nValue)) + 2) return -1;
    const n: usize = @intCast(nValue);
    const rowLimit = (@as(u64, 1) << @intCast(n)) - 1;
    for (0..n) |row| {
        if (values[1 + row] < 0 or @as(u64, @intCast(values[1 + row])) > rowLimit) return -1;
    }
    const qValue = values[n + 1];
    if (qValue < 0 or qValue > @as(i64, @intCast(MAX_Q))) return -1;
    const q: usize = @intCast(qValue);
    if (length != n + 2 + 3 * q) return -1;
    const queryStart = n + 2;
    for (0..q) |j| {
        const op = values[queryStart + 3 * j];
        const u = values[queryStart + 3 * j + 1];
        const v = values[queryStart + 3 * j + 2];
        if (u < 0 or u >= nValue) return -1;
        if (op == 0) {
            if (v < 0 or v >= nValue) return -1;
        } else if (op == 1) {
            if (v != 0) return -1;
        } else return -1;
    }
    const outputBytes = 8 * (q + 1);
    if (outputOpt == null or capacity < outputBytes) return -2;
    const output = outputOpt.?;

    var tBits: [T_BYTES]u8 = @splat(0);
    var lBits: [L_BYTES]u8 = @splat(0);
    var rankPrefix: [T_MAX_BITS + 1]u16 = @splat(0);
    var currentRows: [NODE_CAP]u8 = @splat(0);
    var currentCols: [NODE_CAP]u8 = @splat(0);
    var nextRows: [NODE_CAP]u8 = @splat(0);
    var nextCols: [NODE_CAP]u8 = @splat(0);
    const built = buildTree(values, &tBits, &lBits, &rankPrefix, &currentRows,
        &currentCols, &nextRows, &nextCols, n);
    putI64Le(output, 0, @intCast(q));
    for (0..q) |j| {
        const op = values[queryStart + 3 * j];
        const u: usize = @intCast(values[queryStart + 3 * j + 1]);
        const v: usize = @intCast(values[queryStart + 3 * j + 2]);
        var result: u64 = 0;
        if (op == 0) {
            result = @intFromBool(edgeQuery(tBits[0..], lBits[0..], built.t_len,
                rankPrefix[0..], built.height, u, v));
        } else {
            for (0..n) |successor| {
                if (edgeQuery(tBits[0..], lBits[0..], built.t_len,
                    rankPrefix[0..], built.height, u, successor)) result |= @as(u64, 1) << @intCast(successor);
            }
        }
        putI64Le(output, 8 * (j + 1), result);
    }
    return @intCast(outputBytes);
}
