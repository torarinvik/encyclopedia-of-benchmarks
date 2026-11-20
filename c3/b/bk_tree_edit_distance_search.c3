module bk_tree_edit_distance_search;

const long MAX_WORDS = 16;
const long MAX_QUERIES = 8;
const long MAX_WORD_LENGTH = 10;

fn bool valid_word(long word) {
    if (word < 0 || ((ulong)word >> 44) != 0) return false;
    long word_length = (long)(((ulong)word >> 40) & 15);
    if (word_length > MAX_WORD_LENGTH) return false;
    for (long i = 0; i < MAX_WORD_LENGTH; i++) {
        long symbol = (long)(((ulong)word >> (4 * i)) & 15);
        if (i < word_length) {
            if (symbol == 0) return false;
        } else if (symbol != 0) return false;
    }
    return true;
}

fn long edit_distance(long left, long right) {
    long left_length = (long)(((ulong)left >> 40) & 15);
    long right_length = (long)(((ulong)right >> 40) & 15);
    int[11] previous = zeroed;
    int[11] current = zeroed;
    for (long j = 0; j <= right_length; j++) previous[(usz)j] = (int)j;
    for (long i = 1; i <= left_length; i++) {
        current[0] = (int)i;
        long a = (long)(((ulong)left >> (4 * (i - 1))) & 15);
        for (long j = 1; j <= right_length; j++) {
            long b = (long)(((ulong)right >> (4 * (j - 1))) & 15);
            int deletion = previous[(usz)j] + 1;
            int insertion = current[(usz)(j - 1)] + 1;
            int replacement = previous[(usz)(j - 1)] + (a != b ? 1 : 0);
            current[(usz)j] = deletion < insertion ? deletion : insertion;
            if (replacement < current[(usz)j]) current[(usz)j] = replacement;
        }
        for (long j = 0; j <= right_length; j++) previous[(usz)j] = current[(usz)j];
    }
    return previous[(usz)right_length];
}

fn long bk_tree_edit_distance_search(long* input, usz length) @export("bk_tree_edit_distance_search") {
    if (input == null || length < 3 || length > 28) return -1;
    long n_value = input[0];
    long q_value = input[1];
    long radius_value = input[2];
    if (n_value < 0 || n_value > MAX_WORDS || q_value < 0 || q_value > MAX_QUERIES
        || radius_value < 0 || radius_value > 3
        || length != (usz)(3 + n_value + q_value)) return -1;
    long n = n_value;
    long q = q_value;
    long radius = radius_value;
    long* words = input + 3;
    long* queries = words + n;
    for (long i = 0; i < n + q; i++)
        if (!valid_word(words[(usz)i])) return -1;
    for (long i = 0; i < n; i++)
        for (long j = 0; j < i; j++)
            if (words[(usz)i] == words[(usz)j]) return -1;

    int[176] children = zeroed;
    for (long i = 0; i < 176; i++) children[(usz)i] = -1;
    for (long node = 1; node < n; node++) {
        long pivot = 0;
        while (true) {
            long edge = edit_distance(words[(usz)node], words[(usz)pivot]);
            long slot = pivot * 11 + edge;
            if (children[(usz)slot] == -1) {
                children[(usz)slot] = (int)node;
                break;
            }
            pivot = children[(usz)slot];
        }
    }

    long result = 0;
    for (long qi = 0; qi < q; qi++) {
        long matches = 0;
        long index_sum = 0;
        if (n != 0) {
            int[16] stack = zeroed;
            long top = 1;
            stack[0] = 0;
            while (top != 0) {
                top--;
                long node = stack[(usz)top];
                long distance = edit_distance(queries[(usz)qi], words[(usz)node]);
                if (distance <= radius) {
                    matches++;
                    index_sum += node;
                }
                long low = distance - radius;
                if (low < 0) low = 0;
                long high = distance + radius;
                if (high > MAX_WORD_LENGTH) high = MAX_WORD_LENGTH;
                for (long edge = low; edge <= high; edge++) {
                    int child = children[(usz)(node * 11 + edge)];
                    if (child >= 0) {
                        stack[(usz)top] = child;
                        top++;
                    }
                }
            }
        }
        result += (qi + 1) * (17 * matches + index_sum);
    }
    return result;
}
