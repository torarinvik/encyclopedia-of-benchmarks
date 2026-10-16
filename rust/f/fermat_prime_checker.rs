fn dotnet_sample(seed: &mut [i32; 56], next: &mut usize, next_p: &mut usize) -> i32 {
    *next += 1;
    if *next >= 56 { *next = 1; }
    *next_p += 1;
    if *next_p >= 56 { *next_p = 1; }
    let mut value = seed[*next] - seed[*next_p];
    if value == 2_147_483_647 { value -= 1; }
    if value < 0 { value += 2_147_483_647; }
    seed[*next] = value;
    value
}

fn mod_pow(mut base: i64, mut exponent: i64, modulus: i64) -> i64 {
    let mut result = 1i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % modulus; }
        base = base * base % modulus;
        exponent >>= 1;
    }
    result
}

#[no_mangle]
pub extern "C" fn fermat_prime_checker(number: i64, times_to_check: i64) -> i64 {
    if !(2..=1_000_000).contains(&number) || !(2..=64).contains(&times_to_check) { return -1; }
    let mut seed = [0i32; 56];
    let (mut mj, mut mk) = (161_803_398i32, 1i32);
    seed[55] = mj;
    for i in 1..55 {
        let index = (21 * i) % 55;
        seed[index] = mk;
        mk = mj - mk;
        if mk < 0 { mk += 2_147_483_647; }
        mj = seed[index];
    }
    for _ in 0..4 {
        for i in 1..56 {
            seed[i] -= seed[1 + (i + 30) % 55];
            if seed[i] < 0 { seed[i] += 2_147_483_647; }
        }
    }
    let (mut next, mut next_p) = (0usize, 21usize);
    for _ in 1..times_to_check {
        let sample = dotnet_sample(&mut seed, &mut next, &mut next_p);
        let base = ((sample as f64 / 2_147_483_647.0 * (number - 1) as f64) as i64) + 1;
        if mod_pow(base, number - 1, number) != 1 { return 0; }
    }
    1
}
