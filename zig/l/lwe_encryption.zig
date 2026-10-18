const INVALID_RESULT: i64 = -1;
const DIMENSION: usize = 32;
const MODULUS: i64 = 3329;
const SAMPLES: usize = 128;
const MAX_MESSAGE_BYTES: usize = 4;
const MAX_PARSEABLE_LENGTH: usize = 8358;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const LOW_63_MASK: u64 = 0x7fffffffffffffff;

fn hashByte(hash_input: u64, byte: u8) u64 {
    return (hash_input ^ byte) *% FNV_PRIME;
}

fn hashWord(hash_input: u64, value: i64) u64 {
    var hash = hash_input;
    const bits: u64 = @intCast(value);
    hash = hashByte(hash, @intCast(bits & 255));
    hash = hashByte(hash, @intCast((bits >> 8) & 255));
    return hash;
}

export fn lwe_encryption(packed: ?[*]const i64, length: usize) i64 {
    const values = packed orelse return INVALID_RESULT;
    if (length < 1 or length > MAX_PARSEABLE_LENGTH) return INVALID_RESULT;
    const message_length_value = values[0];
    if (message_length_value < 1 or message_length_value > @as(i64, @intCast(MAX_MESSAGE_BYTES))) return INVALID_RESULT;
    const message_length: usize = @intCast(message_length_value);
    const message_start: usize = 1;
    const message_end = message_start + message_length;
    const secret_start = message_end;
    const matrix_start = secret_start + DIMENSION;
    const error_start = matrix_start + SAMPLES * DIMENSION;
    const subset_start = error_start + SAMPLES;
    const subset_count = message_length * 8 * SAMPLES;
    if (length != subset_start + subset_count) return INVALID_RESULT;

    for (0..message_length) |i| {
        if (values[message_start + i] < 0 or values[message_start + i] > 255) return INVALID_RESULT;
    }
    for (0..DIMENSION) |j| {
        if (values[secret_start + j] < 0 or values[secret_start + j] >= MODULUS) return INVALID_RESULT;
    }
    for (0..SAMPLES * DIMENSION) |i| {
        if (values[matrix_start + i] < 0 or values[matrix_start + i] >= MODULUS) return INVALID_RESULT;
    }
    for (0..SAMPLES) |i| {
        if (values[error_start + i] < 0 or values[error_start + i] > 6) return INVALID_RESULT;
    }
    for (0..subset_count) |i| {
        if (values[subset_start + i] != 0 and values[subset_start + i] != 1) return INVALID_RESULT;
    }

    var public_b = [_]i64{0} ** SAMPLES;
    for (0..SAMPLES) |row| {
        var sum: i64 = 0;
        for (0..DIMENSION) |column| {
            sum += values[matrix_start + row * DIMENSION + column] * values[secret_start + column];
        }
        const error_value = values[error_start + row] - 3;
        public_b[row] = @mod(sum + error_value, MODULUS);
    }

    var hash = FNV_OFFSET_BASIS;
    var decoded_message = [_]u8{0} ** MAX_MESSAGE_BYTES;
    var subset_cursor: usize = 0;
    for (0..message_length) |byte_index| {
        const message_byte: u8 = @intCast(values[message_start + byte_index]);
        var decoded_byte: u8 = 0;
        for (0..8) |bit_index| {
            const shift: u3 = @intCast(7 - bit_index);
            const message_bit: i64 = @intCast((message_byte >> shift) & 1);
            var u_accumulator = [_]i64{0} ** DIMENSION;
            var v_accumulator = message_bit * @divTrunc(MODULUS, 2);
            for (0..SAMPLES) |row| {
                const selected = values[subset_start + subset_cursor];
                subset_cursor += 1;
                if (selected != 0) {
                    for (0..DIMENSION) |column| {
                        u_accumulator[column] += values[matrix_start + row * DIMENSION + column];
                    }
                    v_accumulator += public_b[row];
                }
            }
            var u = [_]i64{0} ** DIMENSION;
            for (0..DIMENSION) |column| {
                u[column] = @mod(u_accumulator[column], MODULUS);
                hash = hashWord(hash, u[column]);
            }
            const v = @mod(v_accumulator, MODULUS);
            hash = hashWord(hash, v);

            var dot: i64 = 0;
            for (0..DIMENSION) |column| dot += u[column] * values[secret_start + column];
            const difference = @mod(v - dot, MODULUS);
            const decrypted_bit: u8 = if (difference >= 832 and difference < 2496) 1 else 0;
            decoded_byte = (decoded_byte << 1) | decrypted_bit;
        }
        decoded_message[byte_index] = decoded_byte;
    }
    for (0..message_length) |i| hash = hashByte(hash, decoded_message[i]);
    return @intCast(hash & LOW_63_MASK);
}
