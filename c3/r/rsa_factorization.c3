module rsa_factorization;

const long INVALID_RESULT = -1;
const long FACTOR_BASE = 65536;
const usz MAX_PACKED_LENGTH = 21;

fn long gcd_i64(long a, long b) {
    if (a < 0) a = -a;
    if (b < 0) b = -b;
    while (b != 0) { long remainder = a % b; a = b; b = remainder; }
    return a;
}

fn long power_mod_i64(long base, long exponent, long modulus) {
    long result = 1, power = base % modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * power) % modulus;
        power = (power * power) % modulus;
        exponent /= 2;
    }
    return result;
}

fn long rsa_factorization(long* packed, usz length) @export("rsa_factorization") {
    if (packed == null || length < 4 || length > MAX_PACKED_LENGTH) return INVALID_RESULT;
    long d=packed[0], e=packed[1], modulus=packed[2], attempts=packed[3];
    if (d < 1 || d > 1000000 || e < 1 || e > 1000000 || modulus < 3 || modulus > 65535 ||
        (modulus & 1) == 0 || attempts < 1 || attempts > 16 || length != (usz)(4 + attempts)) return INVALID_RESULT;
    long k = d * e - 1;
    if (k <= 0 || (k & 1) != 0) return INVALID_RESULT;
    for (long i=0; i<attempts; i++) { long base=packed[4+(usz)i];if(base<2||base>modulus-1)return INVALID_RESULT; }
    for (long i=0; i<attempts; i++) {
        long base=packed[4+(usz)i], t=k;
        while ((t & 1) == 0) {
            t /= 2;
            long x=power_mod_i64(base,t,modulus);
            long factor=gcd_i64(x-1,modulus);
            if (x>1&&factor>1) {
                long other=modulus/factor, p=factor, q=other;
                if(p>q){long temporary=p;p=q;q=temporary;}
                return p*FACTOR_BASE+q;
            }
        }
    }
    return INVALID_RESULT;
}
