const sha = @import("../s/sha256.zig");
const std = @import("std");

const MAX_VALUES: usize = 465;
const MAX_CHAIN: usize = 8;
const MAX_DATA: usize = 64;
const MAX_HEADER: usize = 160;
const NONCE_ATTEMPTS: i64 = 4096;
const MAX_OUTPUT: usize = 728;

const Block = struct {
    timestamp_sec: i64,
    data: [MAX_DATA]u8,
    data_length: usize,
    previous_hash: [64]u8,
    previous_hash_length: usize,
    nonce: i64,
    hash: [64]u8,
};

fn appendDecimal(buffer: *[MAX_HEADER]i64, position_value: usize, value_value: i64) usize {
    var position = position_value;
    var value = value_value;
    var digits: [20]i64 = undefined;
    var count: usize = 0;
    while (true) {
        digits[count] = @as(i64, '0') + @mod(value, 10);
        count += 1;
        value = @divTrunc(value, 10);
        if (value == 0) break;
    }
    while (count != 0) {
        count -= 1;
        buffer[position] = digits[count];
        position += 1;
    }
    return position;
}

fn makeHeader(index: usize, block: *const Block, nonce: i64, header: *[MAX_HEADER]i64) usize {
    var length = appendDecimal(header, 0, @intCast(index));
    length = appendDecimal(header, length, block.timestamp_sec);
    header[length] = '.';
    length += 1;
    header[length] = '0';
    length += 1;
    for (0..block.data_length) |i| {
        header[length] = block.data[i];
        length += 1;
    }
    for (0..block.previous_hash_length) |i| {
        header[length] = block.previous_hash[i];
        length += 1;
    }
    return appendDecimal(header, length, nonce);
}

fn toHex(digest: *const [32]u8, output: *[64]u8) void {
    const hex = "0123456789abcdef";
    for (0..32) |i| {
        output[2 * i] = hex[digest[i] >> 4];
        output[2 * i + 1] = hex[digest[i] & 15];
    }
}

fn computeHash(index: usize, block: *const Block, nonce: i64, output: *[64]u8) bool {
    var header: [MAX_HEADER]i64 = undefined;
    var digest: [32]u8 = undefined;
    const length = makeHeader(index, block, nonce, &header);
    if (sha.sha256(&header[0], length, &digest[0], digest.len) != 32) return false;
    toHex(&digest, output);
    return true;
}

fn hasPrefix(hash: *const [64]u8, difficulty: i64) bool {
    const prefix_length: usize = @intCast(difficulty);
    for (0..prefix_length) |i| {
        if (hash[i] != '0') return false;
    }
    return true;
}

fn isValid(blocks: *const [MAX_CHAIN]Block, chain_length: usize, difficulty: i64) bool {
    for (1..chain_length) |i| {
        if (blocks[i].previous_hash_length != 64 or
            !std.mem.eql(u8, &blocks[i].previous_hash, &blocks[i - 1].hash) or
            !hasPrefix(&blocks[i].hash, difficulty)) return false;
        var recomputed: [64]u8 = undefined;
        if (!computeHash(i, &blocks[i], blocks[i].nonce, &recomputed) or
            !std.mem.eql(u8, &blocks[i].hash, &recomputed)) return false;
    }
    return true;
}

fn writeI64(payload: *[MAX_OUTPUT]u8, position_value: usize, value: i64) usize {
    var position = position_value;
    const bits: u64 = @bitCast(value);
    for (0..8) |i| {
        payload[position] = @truncate(bits >> @intCast(8 * i));
        position += 1;
    }
    return position;
}

pub export fn simple_blockchain(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    output_capacity: usize,
) i64 {
    if (input == null or length < 3 or length > MAX_VALUES) return -1;
    const difficulty = input[0];
    const chain_length_value = input[1];
    if (difficulty < 1 or difficulty > 2 or chain_length_value < 1 or chain_length_value > @as(i64, @intCast(MAX_CHAIN))) return -1;
    const chain_length: usize = @intCast(chain_length_value);
    const max_timestamp: i64 = 2_147_483_647;
    if (input[2] < 0 or input[2] > max_timestamp) return -1;

    var blocks: [MAX_CHAIN]Block = undefined;
    for (0..MAX_CHAIN) |i| {
        blocks[i] = .{
            .timestamp_sec = 0,
            .data = [_]u8{0} ** MAX_DATA,
            .data_length = 0,
            .previous_hash = [_]u8{0} ** 64,
            .previous_hash_length = 0,
            .nonce = 0,
            .hash = [_]u8{0} ** 64,
        };
    }
    blocks[0].timestamp_sec = input[2];
    const genesis = "Genesis Block";
    for (0..genesis.len) |i| blocks[0].data[i] = genesis[i];
    blocks[0].data_length = genesis.len;
    blocks[0].previous_hash[0] = '0';
    blocks[0].previous_hash_length = 1;

    var cursor: usize = 3;
    for (1..chain_length) |i| {
        if (cursor + 2 > length) return -1;
        const timestamp_sec = input[cursor];
        const data_length_value = input[cursor + 1];
        cursor += 2;
        if (timestamp_sec < 0 or timestamp_sec > max_timestamp or data_length_value < 0 or data_length_value > @as(i64, @intCast(MAX_DATA))) return -1;
        const data_length: usize = @intCast(data_length_value);
        if (cursor + data_length > length) return -1;
        blocks[i].timestamp_sec = timestamp_sec;
        blocks[i].data_length = data_length;
        for (0..data_length) |j| {
            const value = input[cursor + j];
            if (value < 0 or value > 127) return -1;
            blocks[i].data[j] = @intCast(value);
        }
        cursor += data_length;
    }
    if (cursor != length) return -1;

    for (0..chain_length) |i| {
        if (i > 0) {
            for (0..64) |j| blocks[i].previous_hash[j] = blocks[i - 1].hash[j];
            blocks[i].previous_hash_length = 64;
        }
        var mined = false;
        var nonce: i64 = 0;
        while (nonce < NONCE_ATTEMPTS) : (nonce += 1) {
            var candidate: [64]u8 = undefined;
            if (!computeHash(i, &blocks[i], nonce, &candidate)) return -1;
            if (hasPrefix(&candidate, difficulty)) {
                blocks[i].nonce = nonce;
                blocks[i].hash = candidate;
                mined = true;
                break;
            }
        }
        if (!mined) return -3;
    }

    const valid: i64 = if (isValid(&blocks, chain_length, difficulty)) 1 else 0;
    var payload: [MAX_OUTPUT]u8 = undefined;
    var written: usize = 0;
    written = writeI64(&payload, written, 0);
    written = writeI64(&payload, written, chain_length_value);
    for (0..chain_length) |i| {
        written = writeI64(&payload, written, @intCast(i));
        written = writeI64(&payload, written, blocks[i].timestamp_sec);
        written = writeI64(&payload, written, blocks[i].nonce);
        for (0..64) |j| {
            payload[written] = blocks[i].hash[j];
            written += 1;
        }
    }
    written = writeI64(&payload, written, valid);
    if (output == null or output_capacity < written) return -2;
    for (0..written) |i| output[i] = payload[i];
    return @intCast(written);
}
