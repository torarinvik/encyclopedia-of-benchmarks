module perfect_shuffle_order;

const long MAX_DECK_SIZE = 10000;
const usz MAX_PARSEABLE_LENGTH = 2;

fn long perfect_shuffle_order(long* input, usz length)
    @export("perfect_shuffle_order") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH || length != 1) return -1;
    long deck_word = input[0];
    if (deck_word < 2 || deck_word > MAX_DECK_SIZE || (deck_word & 1) != 0) return -1;
    usz deck_size = (usz)deck_word;
    usz half = deck_size / 2;

    long[MAX_DECK_SIZE] first;
    long[MAX_DECK_SIZE] second;
    long* current = &first[0];
    long* next = &second[0];
    for (usz i = 0; i < deck_size; ++i) current[i] = (long)i;

    long count = 0;
    while (true) {
        for (usz i = 0; i < half; ++i) {
            next[2 * i] = current[i];
            next[2 * i + 1] = current[half + i];
        }
        count++;
        usz i = 0;
        while (i < deck_size && next[i] == (long)i) i++;
        if (i == deck_size) return count;
        long* temporary = current;
        current = next;
        next = temporary;
    }
}
