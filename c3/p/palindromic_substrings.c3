module palindromic_substrings;

// Count all palindromic substrings by expanding around odd and even centers.
fn long palindromic_substrings(long* values, usz length) @export("palindromic_substrings") {
    if (length == 0 || length > 1000 || values == null) {
        return -1;
    }
    for (usz index = 0; index < length; index++) {
        if (values[index] < 'a' || values[index] > 'z') {
            return -1;
        }
    }

    long count = 0;
    for (usz center = 0; center < length; center++) {
        count++;
        usz left = center;
        usz right = center;
        while (left > 0 && right + 1 < length && values[left - 1] == values[right + 1]) {
            count++;
            left--;
            right++;
        }

        left = center;
        right = center + 1;
        while (right < length && values[left] == values[right]) {
            count++;
            if (left == 0 || right + 1 == length) {
                break;
            }
            left--;
            right++;
        }
    }
    return count;
}
