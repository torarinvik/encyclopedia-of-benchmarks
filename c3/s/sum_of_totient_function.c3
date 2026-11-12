module sum_of_totient_function;

const long MAX_N = 1000000000;
const usz BASE_LIMIT = 100000;
const usz MAX_CACHE = 10002;
const long MODULUS = 998244353;

fn long triangular_mod(long n) {
    long left = n, right = n + 1;
    if (left % 2 == 0) left /= 2;
    else right /= 2;
    return ((left % MODULUS) * (right % MODULUS)) % MODULUS;
}

fn long summatory_phi(long value, long total_n, long* prefix, long* memo, bool* visited) {
    if (value <= BASE_LIMIT.long()) return prefix[value.usz()];
    usz cache_index = (total_n / value).usz();
    if (visited[cache_index]) return memo[cache_index];
    long answer = triangular_mod(value);
    long left = 2;
    while (left <= value) {
        long quotient = value / left;
        long right = value / quotient;
        long block_size = right - left + 1;
        long sub_sum = summatory_phi(quotient, total_n, prefix, memo, visited);
        long contribution = ((block_size % MODULUS) * sub_sum) % MODULUS;
        answer = (answer - contribution + MODULUS) % MODULUS;
        left = right + 1;
    }
    visited[cache_index] = true;
    memo[cache_index] = answer;
    return answer;
}

fn long sum_of_totient_function(long n) @export("sum_of_totient_function") {
    if (n < 1 || n > MAX_N) return -1;
    long[BASE_LIMIT + 1] prefix = zeroed;
    for (usz value = 0; value <= BASE_LIMIT; value++) prefix[value] = value.long();
    usz sieve_limit = n < BASE_LIMIT.long() ? n.usz() : BASE_LIMIT;
    for (usz prime = 2; prime <= sieve_limit; prime++) {
        if (prefix[prime] != prime.long()) continue;
        for (usz multiple = prime; multiple <= sieve_limit; multiple += prime)
            prefix[multiple] -= prefix[multiple] / prime.long();
    }
    long running = 0;
    for (usz value = 1; value <= sieve_limit; value++) {
        running = (running + prefix[value]) % MODULUS;
        prefix[value] = running;
    }
    if (n <= BASE_LIMIT.long()) return prefix[n.usz()];

    long[MAX_CACHE] memo = zeroed;
    bool[MAX_CACHE] visited = zeroed;
    return summatory_phi(n, n, &prefix[0], &memo[0], &visited[0]);
}
