module parse_integer;

const long INVALID_RESULT = -9223372036854775807L - 1L;

fn long parse_integer(long* bytes, usz length) @export("parse_integer") {
    if (bytes == null || length == 0 || length > 64) return INVALID_RESULT;
    for (usz i = 0; i < length; i++) if (bytes[i] < 0 || bytes[i] > 127) return INVALID_RESULT;
    bool negative = bytes[0] == 45;
    usz index = (bytes[0] == 45 || bytes[0] == 43) ? 1 : 0;
    long number = 0;
    while (index < length) {
        long byte = bytes[index];
        if (byte < 48 || byte > 57) return INVALID_RESULT;
        number = (number * 10 + byte - 48) % 4294967296L;
        index++;
    }
    if (negative && number != 0) number = 4294967296L - number;
    return number >= 2147483648L ? number - 4294967296L : number;
}
