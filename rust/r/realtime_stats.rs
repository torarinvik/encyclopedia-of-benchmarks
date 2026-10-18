const INVALID_RESULT: f64 = -1.0e300;
const MAX_INPUT_LENGTH: usize = 36;
const MAX_SAMPLES: i64 = 32;

#[no_mangle]
pub unsafe extern "C" fn realtime_stats(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 3 || length > MAX_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    let variant = *values;
    let statistic = *values.add(1);
    let count = *values.add(2);
    if !(0..=2).contains(&variant)
        || !(0..=2).contains(&statistic)
        || !(2..=MAX_SAMPLES).contains(&count)
        || length != (3 + count) as usize
    {
        return INVALID_RESULT;
    }
    for index in 0..count as usize {
        let value = *values.add(3 + index);
        if !(-64..=64).contains(&value) {
            return INVALID_RESULT;
        }
    }

    let mut mean32 = 0.0f32;
    let mut variance32 = 0.0f32;
    let mut mean64 = 0.0f64;
    let mut variance64 = 0.0f64;
    if variant == 0 {
        let mut anchor = 0.0f32;
        let mut ex = 0.0f32;
        let mut ex2 = 0.0f32;
        let mut n = 0usize;
        for index in 0..count as usize {
            let x = (*values.add(3 + index) as f32) / 16.0f32;
            if n == 0 {
                anchor = x;
            }
            n += 1;
            let tmp = x - anchor;
            ex += tmp;
            ex2 += tmp * tmp;
        }
        mean32 = anchor + ex / n as f32;
        variance32 = (ex2 - (ex * ex) / n as f32) / (n - 1) as f32;
    } else if variant == 1 {
        let mut mu = 0.0f32;
        let mut m = 0.0f32;
        let mut n = 0usize;
        for index in 0..count as usize {
            let x = (*values.add(3 + index) as f32) / 16.0f32;
            n += 1;
            let delta = x - mu;
            mu += delta / n as f32;
            let delta2 = x - mu;
            m += delta * delta2;
        }
        mean32 = mu;
        variance32 = m / n as f32;
    } else {
        let mut mu = 0.0f64;
        let mut m = 0.0f64;
        let mut n = 0usize;
        for index in 0..count as usize {
            let x32 = (*values.add(3 + index) as f32) / 16.0f32;
            let x = x32 as f64;
            n += 1;
            let delta = x - mu;
            mu += delta / n as f64;
            let delta2 = x - mu;
            m += delta * delta2;
        }
        mean64 = mu;
        variance64 = m / n as f64;
    }

    if variant < 2 {
        match statistic {
            0 => mean32 as f64,
            1 => variance32 as f64,
            _ => variance32.sqrt() as f64,
        }
    } else {
        match statistic {
            0 => mean64,
            1 => variance64,
            _ => variance64.sqrt(),
        }
    }
}
