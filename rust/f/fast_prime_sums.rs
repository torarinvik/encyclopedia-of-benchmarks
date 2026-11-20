const SIEVE_LIMIT: usize = 32_000;
const PHI_ROWS: usize = 12;
const PHI_COLUMNS: usize = 30_000;

struct PrimeSumContext {
    primes: Vec<i64>,
    prime_count: Vec<usize>,
    prime_sum: Vec<i64>,
    phi: Vec<i64>,
}

impl PrimeSumContext {
    fn new() -> Self {
        let mut composite = vec![false; SIEVE_LIMIT + 1];
        let mut candidate = 2usize;
        while candidate * candidate <= SIEVE_LIMIT {
            if !composite[candidate] {
                let mut multiple = candidate * candidate;
                while multiple <= SIEVE_LIMIT {
                    composite[multiple] = true;
                    multiple += candidate;
                }
            }
            candidate += 1;
        }
        let mut primes = Vec::new();
        let mut prime_count = vec![0; SIEVE_LIMIT + 1];
        let mut prime_sum = vec![0i64; SIEVE_LIMIT + 1];
        for n in 2..=SIEVE_LIMIT {
            if !composite[n] {
                primes.push(n as i64);
            }
            prime_count[n] = prime_count[n - 1] + if composite[n] { 0 } else { 1 };
            prime_sum[n] = prime_sum[n - 1] + if composite[n] { 0 } else { n as i64 };
        }
        let mut phi = vec![0i64; PHI_ROWS * PHI_COLUMNS];
        for n in 0..PHI_COLUMNS {
            phi[n] = (n as i64) * (n as i64 + 1) / 2;
        }
        for row in 1..PHI_ROWS {
            let prime = primes[row - 1];
            let previous = (row - 1) * PHI_COLUMNS;
            let current = row * PHI_COLUMNS;
            for n in 0..PHI_COLUMNS {
                phi[current + n] = phi[previous + n] - prime * phi[previous + n / prime as usize];
            }
        }
        Self { primes, prime_count, prime_sum, phi }
    }

    fn sqrt_floor(n: i64) -> i64 {
        let (mut low, mut high) = (0, n + 1);
        while low + 1 < high {
            let middle = low + (high - low) / 2;
            if middle <= n / middle { low = middle; } else { high = middle; }
        }
        low
    }

    fn cbrt_floor(n: i64) -> i64 {
        let (mut low, mut high) = (0, 1);
        while high * high * high <= n { high *= 2; }
        while low + 1 < high {
            let middle = low + (high - low) / 2;
            if middle * middle * middle <= n { low = middle; } else { high = middle; }
        }
        low
    }

    fn partial_sum(&self, n: i64, count: usize) -> i64 {
        if n <= 0 { return 0; }
        if count == 0 { return n * (n + 1) / 2; }
        let prime = self.primes[count - 1];
        if n <= prime { return 1; }
        if count < PHI_ROWS && n < PHI_COLUMNS as i64 {
            return self.phi[count * PHI_COLUMNS + n as usize];
        }
        if n < SIEVE_LIMIT as i64 && prime * prime >= n {
            return self.prime_sum[n as usize] - self.prime_sum[prime as usize] + 1;
        }
        if n < SIEVE_LIMIT as i64 && prime * prime * prime >= n {
            let mut result = self.prime_sum[n as usize] - self.prime_sum[prime as usize] + 1;
            let limit = self.prime_count[Self::sqrt_floor(n) as usize];
            for i in count..limit {
                let other = self.primes[i];
                result += other * (self.prime_sum[(n / other) as usize] - self.prime_sum[other as usize - 1]);
            }
            return result;
        }
        self.partial_sum(n, count - 1) - prime * self.partial_sum(n / prime, count - 1)
    }

    fn query(&self, n: i64) -> i64 {
        if n <= SIEVE_LIMIT as i64 { return self.prime_sum[n as usize]; }
        let cube = Self::cbrt_floor(n) as usize;
        let square = Self::sqrt_floor(n) as usize;
        let first = self.prime_count[cube];
        let last = self.prime_count[square];
        let mut result = self.partial_sum(n, first) + self.prime_sum[cube] - 1;
        for i in first..last {
            let prime = self.primes[i];
            let quotient = n / prime;
            result -= (self.query(quotient) - self.prime_sum[prime as usize - 1]) * prime;
        }
        result
    }
}

#[no_mangle]
pub extern "C" fn fast_prime_sums(value: i64) -> i64 {
    if !(0..=1_000_000_000).contains(&value) { return -1; }
    PrimeSumContext::new().query(value)
}
