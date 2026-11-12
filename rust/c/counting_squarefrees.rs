const MAX_N: i64 = 1_000_000_000_000;
const MAX_ROOT: usize = 1_000_000;

fn integer_sqrt(value: i64) -> i64 {
    let (mut low, mut high) = (1i64, MAX_ROOT as i64);
    while low < high {
        let middle = low + (high - low + 1) / 2;
        if middle <= value / middle { low = middle; }
        else { high = middle - 1; }
    }
    low
}

#[no_mangle]
pub extern "C" fn counting_squarefrees(n: i64) -> i64 {
    if !(1..=MAX_N).contains(&n) { return -1; }
    let limit = integer_sqrt(n) as usize;
    let mut mobius = [0u8; MAX_ROOT + 1];
    let mut composite = [false; MAX_ROOT + 1];
    for value in 1..=limit { mobius[value] = 1; }

    for prime in 2..=limit {
        if composite[prime] { continue; }
        if prime <= limit / prime {
            let mut multiple = prime * prime;
            while multiple <= limit {
                composite[multiple] = true;
                multiple += prime;
            }
        }
        let mut multiple = prime;
        while multiple <= limit {
            if mobius[multiple] == 1 { mobius[multiple] = 2; }
            else if mobius[multiple] == 2 { mobius[multiple] = 1; }
            multiple += prime;
        }
        if prime <= limit / prime {
            let square = prime * prime;
            let mut multiple = square;
            while multiple <= limit {
                mobius[multiple] = 0;
                multiple += square;
            }
        }
    }

    let mut count = 0i64;
    for divisor in 1..=limit {
        let d = divisor as i64;
        let quotient = n / (d * d);
        if mobius[divisor] == 1 { count += quotient; }
        else if mobius[divisor] == 2 { count -= quotient; }
    }
    count
}
