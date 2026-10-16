module frequency_finder;

const usz MAX_INPUT_LENGTH = 1024;
const char* ETAOIN = "ETAOINSHRDLCUMWFGYPBVKJXQZ";

fn long frequency_finder(long* input, usz length) @export("frequency_finder") {
    if (input == null) { if (length == 0) return 0; return -1; }
    if (length > MAX_INPUT_LENGTH) return -1;
    long[26] counts = {0};
    for (usz i = 0; i < length; i++) {
        long b = input[i]; if (b < 0 || b > 127) return -1;
        if (b >= 97 && b <= 122) b -= 32;
        if (b >= 65 && b <= 90) counts[(usz)(b - 65)]++;
    }
    int[26] order;
    for (usz i = 0; i < 26; i++) order[i] = (int)i;
    for (usz i = 1; i < 26; i++) {
        int key = order[i], j = (int)i, kr = 0;
        while (ETAOIN[kr] != 65 + key) kr++;
        while (j > 0) {
            int p = order[j - 1], pr = 0; while (ETAOIN[pr] != 65 + p) pr++;
            if (counts[p] > counts[key] || (counts[p] == counts[key] && pr > kr)) break;
            order[j] = p; j--;
        }
        order[j] = key;
    }
    long score = 0;
    for (usz i = 0; i < 6; i++) {
        for (usz j = 0; j < 6; j++) if (65 + order[i] == ETAOIN[j]) { score++; break; }
        for (usz j = 20; j < 26; j++) if (65 + order[20 + i] == ETAOIN[j]) { score++; break; }
    }
    return score;
}
