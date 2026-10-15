module verifying_an_alien_dictionary;

const MAX_WORDS = 100;
const MAX_WORD_LENGTH = 20;
const MAX_INPUT_LENGTH = 2127;
const INVALID_RESULT = -1;

fn long verifying_an_alien_dictionary(long* input, usz length) @export("verifying_an_alien_dictionary")
{
    if (input == null || length < 27 || length > MAX_INPUT_LENGTH || input[0] < 1 || input[0] > MAX_WORDS) return INVALID_RESULT;
    usz word_count = (usz)input[0];
    long[26] rank;
    bool[26] order_seen;
    for (usz position = 0; position < 26; position++) order_seen[position] = false;
    for (usz position = 0; position < 26; position++) {
        long letter = input[1 + position];
        if (letter < 'a' || letter > 'z') return INVALID_RESULT;
        usz index = (usz)(letter - 'a');
        if (order_seen[index]) return INVALID_RESULT;
        order_seen[index] = true;
        rank[index] = (long)position;
    }

    usz[MAX_WORDS] starts;
    usz[MAX_WORDS] word_lengths;
    usz offset = 27;
    for (usz word = 0; word < word_count; word++) {
        if (offset >= length || input[offset] < 1 || input[offset] > MAX_WORD_LENGTH) return INVALID_RESULT;
        usz word_length = (usz)input[offset];
        offset++;
        if (word_length > length - offset) return INVALID_RESULT;
        starts[word] = offset;
        word_lengths[word] = word_length;
        for (usz character = 0; character < word_length; character++) {
            long letter = input[offset + character];
            if (letter < 'a' || letter > 'z') return INVALID_RESULT;
        }
        offset += word_length;
    }
    if (offset != length) return INVALID_RESULT;

    for (usz word = 0; word + 1 < word_count; word++) {
        usz left_length = word_lengths[word];
        usz right_length = word_lengths[word + 1];
        usz limit = left_length < right_length ? left_length : right_length;
        bool decided = false;
        for (usz character = 0; character < limit; character++) {
            usz left_letter = (usz)(input[starts[word] + character] - 'a');
            usz right_letter = (usz)(input[starts[word + 1] + character] - 'a');
            if (rank[left_letter] < rank[right_letter]) {
                decided = true;
                break;
            }
            if (rank[left_letter] > rank[right_letter]) return 0;
        }
        if (!decided && left_length > right_length) return 0;
    }
    return 1;
}
