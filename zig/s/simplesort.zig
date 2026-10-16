const MAX_LENGTH: usize = 256;
const MIN_VALUE: i64 = -1_000_000;
const MAX_VALUE: i64 = 1_000_000;
const CHECKSUM_OFFSET: i64 = 1_000_001;
const INVALID_RESULT: i64 = -1;

export fn simplesort(values: [*c]const i64, length: usize) i64 {
    if (length > MAX_LENGTH or (length != 0 and values == null)) return INVALID_RESULT;
    var working: [MAX_LENGTH]i64 = undefined;
    for (0..length) |index| {
        if (values[index] < MIN_VALUE or values[index] > MAX_VALUE) return INVALID_RESULT;
        working[index] = values[index];
    }

    var i: usize = 0;
    while (i < length) : (i += 1) {
        var j: usize = 0;
        while (j < length) : (j += 1) {
            if (working[i] < working[j]) {
                const temporary = working[i];
                working[i] = working[j];
                working[j] = temporary;
            }
        }
    }
    var checksum: i64 = 0;
    for (0..length) |index| {
        const weight: i64 = @intCast(index + 1);
        checksum += weight * (working[index] + CHECKSUM_OFFSET);
    }
    return checksum;
}
