// Uncompiled and unexecuted weighted-binary-search draft.
module wqs_path_independent_set;
struct WqsState { long score; long count; }
fn WqsState evaluate(long* weights, usz n, long penalty) {
    WqsState two = {0,0}, one = {0,0};
    for (usz i = 0; i < n; i++) {
        WqsState take = {two.score+weights[i]-penalty, two.count+1};
        WqsState current = take.score > one.score ||
            (take.score == one.score && take.count > one.count) ? take : one;
        two = one; one = current;
    }
    return one;
}
fn long wqs_path_independent_set(long* input, usz length) @export("wqs_path_independent_set") {
    if (input == null || length < 2 || length > 130) return -1000000000;
    if (input[0] < 0 || input[0] > 128 || input[1] < 0 || input[1] > (input[0]+1)/2) return -1000000000;
    usz n = (usz)input[0];
    if (length != n+2) return -1000000000;
    for (usz i = 0; i < n; i++) if (input[2+i] < -1000 || input[2+i] > 1000) return -1000000000;
    long low = -256001, high = 256001;
    while (low < high) {
        long middle = low+(high-low+1)/2;
        WqsState state = evaluate(input+2, n, middle);
        if (state.count >= input[1]) low = middle; else high = middle-1;
    }
    WqsState result = evaluate(input+2, n, low);
    return result.score+low*input[1];
}
