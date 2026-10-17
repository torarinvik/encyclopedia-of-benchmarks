const MT_N: usize = 624;
const MT_M: usize = 397;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 3;

#[inline(never)]
fn rounded_mul(left: f64, right: f64) -> f64 {
    std::hint::black_box(left * right)
}

#[inline(never)]
fn rounded_add(left: f64, right: f64) -> f64 {
    std::hint::black_box(left + right)
}

struct Mt19937 {
    state: [u32; MT_N],
    index: usize,
}

impl Mt19937 {
    fn seeded(seed: u32) -> Self {
        let mut state = [0_u32; MT_N];
        state[0] = 19_650_218;
        for index in 1..MT_N {
            let previous = state[index - 1];
            state[index] = 1_812_433_253_u32
                .wrapping_mul(previous ^ (previous >> 30))
                .wrapping_add(index as u32);
        }

        let mut index = 1;
        let mut key_index = 0;
        for _ in 0..MT_N {
            let previous = state[index - 1];
            state[index] = (state[index]
                ^ (previous ^ (previous >> 30)).wrapping_mul(1_664_525))
                .wrapping_add(seed)
                .wrapping_add(key_index as u32);
            index += 1;
            key_index += 1;
            if index >= MT_N { state[0] = state[MT_N - 1]; index = 1; }
            if key_index >= 1 { key_index = 0; }
        }
        for _ in 0..MT_N - 1 {
            let previous = state[index - 1];
            state[index] = (state[index]
                ^ (previous ^ (previous >> 30)).wrapping_mul(1_566_083_941))
                .wrapping_sub(index as u32);
            index += 1;
            if index >= MT_N { state[0] = state[MT_N - 1]; index = 1; }
        }
        state[0] = 0x8000_0000;
        Self { state, index: MT_N }
    }

    fn next_u32(&mut self) -> u32 {
        if self.index >= MT_N {
            for index in 0..MT_N - MT_M {
                let joined = (self.state[index] & 0x8000_0000) | (self.state[index + 1] & 0x7fff_ffff);
                self.state[index] = self.state[index + MT_M] ^ (joined >> 1) ^ if joined & 1 != 0 { 0x9908_b0df } else { 0 };
            }
            for index in MT_N - MT_M..MT_N - 1 {
                let joined = (self.state[index] & 0x8000_0000) | (self.state[index + 1] & 0x7fff_ffff);
                self.state[index] = self.state[index - (MT_N - MT_M)] ^ (joined >> 1) ^ if joined & 1 != 0 { 0x9908_b0df } else { 0 };
            }
            let joined = (self.state[MT_N - 1] & 0x8000_0000) | (self.state[0] & 0x7fff_ffff);
            self.state[MT_N - 1] = self.state[MT_M - 1] ^ (joined >> 1) ^ if joined & 1 != 0 { 0x9908_b0df } else { 0 };
            self.index = 0;
        }
        let mut value = self.state[self.index];
        self.index += 1;
        value ^= value >> 11;
        value ^= (value << 7) & 0x9d2c_5680;
        value ^= (value << 15) & 0xefc6_0000;
        value ^= value >> 18;
        value
    }

    fn random(&mut self) -> f64 {
        let high = self.next_u32() >> 5;
        let low = self.next_u32() >> 6;
        (high as f64 * 67_108_864.0 + low as f64) * (1.0 / 9_007_199_254_740_992.0)
    }
}

#[no_mangle]
pub unsafe extern "C" fn pi_monte_carlo_estimation(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    if input_length != 2 { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let simulations_value = values[0];
    let seed_value = values[1];
    if !simulations_value.is_finite() || !seed_value.is_finite()
        || simulations_value.fract() != 0.0 || seed_value.fract() != 0.0
        || simulations_value < 1.0 || simulations_value > 100_000.0
        || seed_value < 0.0 || seed_value > 4_294_967_295.0 { return -1; }
    if output.is_null() || output_capacity < 1 { return -2; }

    let simulations = simulations_value as usize;
    let seed = seed_value as u32;
    let mut rng = Mt19937::seeded(seed);
    let mut hits = 0_usize;
    for _ in 0..simulations {
        let x = rng.random();
        let y = rng.random();
        let x_squared = rounded_mul(x, x);
        let y_squared = rounded_mul(y, y);
        if rounded_add(x_squared, y_squared) <= 1.0 { hits += 1; }
    }
    *output = (4 * hits) as f64 / simulations as f64;
    1
}
