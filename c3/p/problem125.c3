module problem125;

const long MAX_LIMIT = 100000000;
const usz HASH_CAPACITY = 32768;
const usz HASH_MASK = HASH_CAPACITY - 1;

fn bool is_palindrome(long value) {
    if (value % 10 == 0) return false;
    long original = value;
    long reversed = 0;
    while (value > 0) {
        reversed = reversed * 10 + value % 10;
        value /= 10;
    }
    return original == reversed;
}

fn bool insert_unique(long* seen, long value) {
    usz slot = ((usz)(((u64)value * 2654435761) >> 17)) & HASH_MASK;
    while (seen[slot] != 0 && seen[slot] != value) slot = (slot + 1) & HASH_MASK;
    if (seen[slot] == value) return false;
    seen[slot] = value;
    return true;
}

fn long problem125(long limit) @export("problem125") {
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    long[HASH_CAPACITY] seen = zeroed;
    long total = 0;
    long first = 1;
    while (true) {
        long last = first + 1;
        long sum = first * first + last * last;
        if (sum >= limit) break;
        while (sum < limit) {
            if (is_palindrome(sum) && insert_unique(&seen[0], sum)) total += sum;
            last++;
            sum += last * last;
        }
        first++;
    }
    return total;
}
