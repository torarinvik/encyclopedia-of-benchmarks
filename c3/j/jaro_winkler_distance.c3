module jaro_winkler_distance;

const long MAX_STRING_LENGTH = 32;
const usz MAX_INPUT_LENGTH = 66;
const long SCALE = 1000000000;

fn long jaro_winkler_distance(long* input, usz length) @export("jaro_winkler_distance") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long first_length_value = input[0];
    if (first_length_value < 0 || first_length_value > MAX_STRING_LENGTH) return -1;
    int first_length = (int)first_length_value;
    int second_length_index = 1 + first_length;
    if ((usz)second_length_index >= length) return -1;
    long second_length_value = input[second_length_index];
    if (second_length_value < 0 || second_length_value > MAX_STRING_LENGTH ||
        first_length_value < second_length_value ||
        length != (usz)(second_length_index + 1 + (int)second_length_value)) return -1;
    int second_length = (int)second_length_value;

    for (int i = 0; i < first_length; i++) if (input[1 + i] < 0 || input[1 + i] > 127) return -1;
    for (int i = 0; i < second_length; i++) {
        int index = second_length_index + 1 + i;
        if (input[index] < 0 || input[index] > 127) return -1;
    }
    if (first_length == second_length) {
        bool equal = true;
        for (int i = 0; i < first_length; i++) {
            if (input[1 + i] != input[second_length_index + 1 + i]) { equal = false; break; }
        }
        if (equal) return 0;
    }
    if (second_length == 0) return SCALE;

    int half = first_length / 2;
    int radius = half > 0 ? half - 1 : 0;
    bool[MAX_STRING_LENGTH] first_matched = {};
    bool[MAX_STRING_LENGTH] second_matched = {};
    int match_count = 0;
    for (int i = 0; i < first_length; i++) {
        int start = i > radius ? i - radius : 0;
        int ending = i + radius;
        if (ending >= second_length) ending = second_length - 1;
        if (start > ending) continue;
        for (int j = start; j <= ending; j++) {
            if (input[1 + i] == input[second_length_index + 1 + j] && !second_matched[j]) {
                first_matched[i] = true;
                second_matched[j] = true;
                match_count++;
                break;
            }
        }
    }
    if (match_count == 0) return SCALE;

    int second_index = 0;
    int mismatched_pairs = 0;
    for (int i = 0; i < first_length; i++) {
        if (!first_matched[i]) continue;
        while (second_index < second_length && !second_matched[second_index]) second_index++;
        if (second_index == second_length) return -1;
        if (input[1 + i] != input[second_length_index + 1 + second_index]) mismatched_pairs++;
        second_index++;
    }
    long matches = (long)match_count;
    long first_size = (long)first_length;
    long second_size = (long)second_length;
    long transpositions = (long)(mismatched_pairs / 2);
    long jaro_numerator = matches * matches * second_size + matches * matches * first_size +
        (matches - transpositions) * first_size * second_size;
    long jaro_denominator = 3 * first_size * second_size * matches;

    int prefix_length = 0;
    int prefix_limit = second_length < 4 ? second_length : 4;
    while (prefix_length < prefix_limit && input[1 + prefix_length] == input[second_length_index + 1 + prefix_length]) prefix_length++;
    long denominator = 10 * jaro_denominator;
    long numerator = (long)(10 - prefix_length) * (jaro_denominator - jaro_numerator);
    return (numerator * SCALE + denominator / 2) / denominator;
}
