module problem14;

const long MAX_LIMIT = 1000000;
const ulong MAX_CHAIN_LENGTH = 10000ul;
const ulong MAX_SAFE_ODD = 6148914691236517204ul;

fn ulong collatz_length(ulong start) {
    ulong current = start;
    ulong length = 1ul;
    while (current != 1ul) {
        if (length >= MAX_CHAIN_LENGTH) return 0ul;
        if (current % 2ul == 0ul) current /= 2ul;
        else {
            if (current > MAX_SAFE_ODD) return 0ul;
            current = 3ul * current + 1ul;
        }
        length++;
    }
    return length;
}

fn long problem14(long limit) @export("problem14") {
    if (limit < 1 || limit > MAX_LIMIT) return -1;
    ulong best_start = 1ul;
    ulong best_length = 1ul;
    for (ulong start = 2ul; start <= (ulong)limit; start++) {
        ulong length = collatz_length(start);
        if (length == 0ul) return -1;
        if (length > best_length) {
            best_start = start;
            best_length = length;
        }
    }
    return (long)best_start;
}
