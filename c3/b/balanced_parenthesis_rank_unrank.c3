module balanced_parenthesis_rank_unrank;

const usz MAX_PAIRS = 10;
const usz MAX_INPUT_LENGTH = 22;
const usz WAYS_STRIDE = 11;
const usz WAYS_COUNT = 231;

fn long balanced_parenthesis_rank_unrank(long* input, usz length)
        @export("balanced_parenthesis_rank_unrank") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long mode = input[0], pairs_value = input[1];
    if (pairs_value < 1 || pairs_value > (long)MAX_PAIRS) return -1;
    usz pairs = (usz)pairs_value, sequence_length = 2 * pairs;
    if (mode == 0) {
        if (length != 2 + sequence_length) return -1;
        long balance = 0;
        for (usz i = 0; i < sequence_length; i++) {
            long symbol = input[2 + i];
            if (symbol != 0 && symbol != 1) return -1;
            balance += if (symbol == 0) 1 else -1;
            if (balance < 0) return -1;
        }
        if (balance != 0) return -1;
    } else if (mode == 1) {
        if (length != 3) return -1;
    } else {
        return -1;
    }

    long[WAYS_COUNT] ways = zeroed;
    ways[0] = 1;
    usz remaining = 1;
    while (remaining <= sequence_length) {
        usz balance = 0;
        while (balance <= pairs) {
            long count = 0;
            if (balance < pairs) count += ways[(remaining - 1) * WAYS_STRIDE + balance + 1];
            if (balance > 0) count += ways[(remaining - 1) * WAYS_STRIDE + balance - 1];
            ways[remaining * WAYS_STRIDE + balance] = count;
            balance++;
        }
        remaining++;
    }

    if (mode == 0) {
        long rank = 0;
        usz balance = 0;
        for (usz i = 0; i < sequence_length; i++) {
            long symbol = input[2 + i];
            usz suffix = sequence_length - i - 1;
            if (symbol == 1 && balance < pairs) rank += ways[suffix * WAYS_STRIDE + balance + 1];
            if (symbol == 0) balance++;
            else balance--;
        }
        return rank;
    }

    long rank = input[2];
    if (rank < 0 || rank >= ways[sequence_length * WAYS_STRIDE]) return -1;
    usz balance = 0;
    ulong code = 0;
    for (usz i = 0; i < sequence_length; i++) {
        usz suffix = sequence_length - i - 1;
        long opening_count = if (balance < pairs) ways[suffix * WAYS_STRIDE + balance + 1] else 0;
        long symbol;
        if (rank < opening_count) {
            symbol = 0;
            balance++;
        } else {
            rank -= opening_count;
            symbol = 1;
            balance--;
        }
        code = (code << 1) | (ulong)symbol;
    }
    return (long)code;
}
