module shortest_path_modulo_small_multiple;

fn long minimum_digit_sum(long n) {
    long[16] distance;
    long[512] deque;
    for (usz i = 0; i < (usz)n; i++) distance[i] = 1000;
    usz head = 0, tail = 0, count = 0;
    usz start = (usz)(1 % n);
    distance[start] = 1;
    deque[tail] = (long)start;
    tail = (tail + 1) % 512;
    count++;
    while (count > 0) {
        usz residue = (usz)deque[head];
        head = (head + 1) % 512;
        count--;
        long zero_next = ((long)residue * 10) % n;
        if (distance[(usz)zero_next] > distance[residue]) {
            distance[(usz)zero_next] = distance[residue];
            head = (head + 511) % 512;
            deque[head] = zero_next;
            count++;
        }
        long one_next = (zero_next + 1) % n;
        if (distance[(usz)one_next] > distance[residue] + 1) {
            distance[(usz)one_next] = distance[residue] + 1;
            deque[tail] = one_next;
            tail = (tail + 1) % 512;
            count++;
        }
    }
    return distance[0];
}

fn long shortest_path_modulo_small_multiple(long* input, usz length) @export("shortest_path_modulo_small_multiple") {
    if (input == null || length != 1) return -1;
    long n = input[0];
    if (n < 1 || n > 16) return -1;
    return minimum_digit_sum(n);
}
