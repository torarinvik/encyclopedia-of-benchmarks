const MAX_WIDTH: usize = 32;
const MAX_HEIGHT: usize = 32;
const MAX_PIXELS: usize = MAX_WIDTH * MAX_HEIGHT;
const INVALID_RESULT: f64 = -1e300;

fn filter_once(width: usize, height: usize, image: &[f32; MAX_PIXELS],
               output: &mut [f32; MAX_PIXELS], y1: &mut [f32; MAX_PIXELS],
               y2: &mut [f32; MAX_PIXELS]) {
    let alpha = 0.25f32;
    let exp_neg_alpha = (-alpha).exp();
    let difference = 1.0f32 - exp_neg_alpha;
    let numerator = difference * difference;
    let denominator_left = 1.0f32 + 2.0f32 * alpha * exp_neg_alpha;
    let k = numerator / (denominator_left - (2.0f32 * alpha).exp());
    let a1 = k;
    let a2 = k * exp_neg_alpha * (alpha - 1.0f32);
    let a3 = k * exp_neg_alpha * (alpha + 1.0f32);
    let a4 = -k * (-2.0f32 * alpha).exp();
    let a5 = k; let a6 = a2; let a7 = a3; let a8 = a4;
    let b1 = 2.0f32.powf(-alpha); let b2 = -(-2.0f32 * alpha).exp();
    for i in 0..width {
        let (mut ym1, mut ym2, mut xm1) = (0.0f32, 0.0f32, 0.0f32);
        for j in 0..height {
            let at = i * height + j;
            let mut value = a1 * image[at] + a2 * xm1;
            value = value + b1 * ym1; value = value + b2 * ym2;
            y1[at] = value; xm1 = image[at]; ym2 = ym1; ym1 = value;
        }
    }
    for i in 0..width {
        let (mut yp1, mut yp2, mut xp1, mut xp2) = (0.0f32, 0.0f32, 0.0f32, 0.0f32);
        for j in (0..height).rev() {
            let at = i * height + j;
            let mut value = a3 * xp1 + a4 * xp2;
            value = value + b1 * yp1; value = value + b2 * yp2;
            y2[at] = value; xp2 = xp1; xp1 = image[at]; yp2 = yp1; yp1 = value;
        }
    }
    for i in 0..width { for j in 0..height {
        let at = i * height + j; output[at] = 1.0f32 * (y1[at] + y2[at]);
    }}
    for j in 0..height {
        let (mut tm1, mut ym1, mut ym2) = (0.0f32, 0.0f32, 0.0f32);
        for i in 0..width {
            let at = i * height + j;
            let mut value = a5 * output[at] + a6 * tm1;
            value = value + b1 * ym1; value = value + b2 * ym2;
            y1[at] = value; tm1 = output[at]; ym2 = ym1; ym1 = value;
        }
    }
    for j in 0..height {
        let (mut tp1, mut tp2, mut yp1, mut yp2) = (0.0f32, 0.0f32, 0.0f32, 0.0f32);
        for i in (0..width).rev() {
            let at = i * height + j;
            let mut value = a7 * tp1 + a8 * tp2;
            value = value + b1 * yp1; value = value + b2 * yp2;
            y2[at] = value; tp2 = tp1; tp1 = output[at]; yp2 = yp1; yp1 = value;
        }
    }
    for at in 0..width * height { output[at] = 1.0f32 * (y1[at] + y2[at]); }
}

#[no_mangle]
pub extern "C" fn deriche(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input[0] < 1 || input[0] > MAX_WIDTH as i64 || input[1] < 1 || input[1] > MAX_HEIGHT as i64 ||
       input[2] < 1 || input[2] > 4 { return INVALID_RESULT; }
    let (width, height) = (input[0] as usize, input[1] as usize);
    let mut image = [0.0f32; MAX_PIXELS]; let mut output = [0.0f32; MAX_PIXELS];
    let mut y1 = [0.0f32; MAX_PIXELS]; let mut y2 = [0.0f32; MAX_PIXELS];
    for i in 0..width { for j in 0..height {
        image[i * height + j] = ((313 * i + 991 * j) % 65536) as f32 / 65535.0f32;
    }}
    for _ in 0..input[2] {
        filter_once(width, height, &image, &mut output, &mut y1, &mut y2);
        for at in 0..width * height { image[at] = output[at]; }
    }
    let mut checksum = 0.0f64;
    for at in 0..width * height { checksum += output[at] as f64; }
    checksum
}
