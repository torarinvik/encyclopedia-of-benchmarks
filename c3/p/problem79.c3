module problem79;

fn bool next_permutation(long* digits, int length) {
    int pivot = length - 2;
    while (pivot >= 0 && digits[pivot] >= digits[pivot + 1]) pivot--;
    if (pivot < 0) return false;
    int successor = length - 1;
    while (digits[successor] <= digits[pivot]) successor--;
    long temporary = digits[pivot]; digits[pivot] = digits[successor]; digits[successor] = temporary;
    int left = pivot + 1, right = length - 1;
    while (left < right) { temporary = digits[left]; digits[left] = digits[right]; digits[right] = temporary; left++; right--; }
    return true;
}

fn long problem79(long placeholder) @export("problem79") {
    if (placeholder != 0) return -1;
    long[50] logins = {319,680,180,690,129,620,762,689,762,318,368,710,720,710,629,168,160,689,716,731,736,729,316,729,729,710,769,290,719,680,318,389,162,289,162,718,729,319,790,680,890,362,319,760,316,729,380,319,728,716};
    bool[10] present = {false};
    for (int i = 0; i < 50; i++) {
        long login = logins[i];
        present[(usz)(login / 100)] = true;
        present[(usz)((login / 10) % 10)] = true;
        present[(usz)(login % 10)] = true;
    }
    long[10] digits;
    int length = 0;
    for (int digit = 0; digit <= 9; digit++) if (present[(usz)digit]) digits[length++] = digit;
    do {
        long[10] positions;
        for (int digit = 0; digit <= 9; digit++) positions[digit] = -1;
        for (int i = 0; i < length; i++) positions[(usz)digits[i]] = i;
        bool satisfied = true;
        for (int i = 0; i < 50; i++) {
            long login = logins[i];
            int first = (int)(login / 100), second = (int)((login / 10) % 10), third = (int)(login % 10);
            if (!(positions[first] < positions[second] && positions[second] < positions[third])) { satisfied = false; break; }
        }
        if (satisfied) {
            long passcode = 0;
            for (int i = 0; i < length; i++) passcode = passcode * 10 + digits[i];
            return passcode;
        }
    } while (next_permutation(&digits[0], length));
    return -1;
}
