const CELLS: usize = 27;
const MAX_SAMPLES: i64 = 4;
const WIDTH: f32 = 2.5_f32;
const OVERSAMPLE: f32 = 0.608933_f32;
const COEFF: [f32; 15] = [
    0.210580722890567e-22_f32, 0.380715242345326e-19_f32, 0.479440257548300e-16_f32,
    0.435125971262668e-13_f32, 0.300931127112960e-10_f32, 0.160224679395361e-7_f32,
    0.654858370096785e-5_f32, 0.202591084143397e-2_f32, 0.463076284721000e0_f32,
    0.754337328948189e2_f32, 0.830792541809429e4_f32, 0.571661130563785e6_f32,
    0.216415572361227e8_f32, 0.356644482244025e9_f32, 0.144048298227235e10_f32,
];

fn decode(raw: i64) -> f32 { (raw as f32) / 1_000_000.0_f32 }

fn kernel(value: f32) -> f32 {
    let z = value * value;
    let mut num = COEFF[0];
    for i in 1..15 {
        let product = z * num;
        num = product + COEFF[i];
    }
    let mut den = z - 0.307646912682801e4_f32;
    den = z * den;
    den = den + 0.347626332405882e7_f32;
    den = z * den;
    den = den - 0.144048298227235e10_f32;
    -num / den
}

fn beta_value() -> f32 {
    let mut first = 4.0_f32 * WIDTH;
    first = first * WIDTH;
    let divisor = OVERSAMPLE * OVERSAMPLE;
    first = first / divisor;
    let shifted = f64::from(OVERSAMPLE) - 0.5_f64;
    let mut argument = f64::from(first) * shifted;
    argument = argument * shifted;
    argument = argument - 0.8_f64;
    (3.14159265359_f64 * argument.sqrt()) as f32
}

fn weight(v: f32, inverse: f32, beta: f32, sdc: f32) -> f32 {
    let product = v * inverse;
    let radicand = 1.0_f64 - f64::from(product);
    let argument = (f64::from(beta) * radicand.sqrt()) as f32;
    kernel(argument) * sdc
}

fn lower(k: f32, cutoff: f32) -> usize {
    let delta = k - cutoff;
    if delta < 0.0_f32 { 0 } else { delta as usize }
}
fn upper(k: f32, cutoff: f32) -> usize {
    let total = k + cutoff;
    if total > 2.0_f32 { 2 } else { total as usize }
}
fn quantize(value: f32) -> i64 {
    let scaled = value * 1000.0_f32;
    let magnitude = if scaled < 0.0_f32 { -scaled } else { scaled };
    let mut whole = magnitude as i64;
    if magnitude - whole as f32 >= 0.5_f32 { whole += 1; }
    if scaled < 0.0_f32 { -whole } else { whole }
}

#[no_mangle]
pub unsafe extern "C" fn parboil_mri_gridding(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > 25 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n = values[0];
    if n < 0 || n > MAX_SAMPLES || length != 1 + 6 * n as usize { return -1; }
    for s in 0..n as usize {
        let p = 1 + 6*s;
        for axis in 0..3 {
            if values[p+axis] != 0 && values[p+axis] != 1_000_000 && values[p+axis] != 2_000_000 { return -1; }
        }
        if values[p+3] < -1_000_000 || values[p+3] > 1_000_000 ||
           values[p+4] < -1_000_000 || values[p+4] > 1_000_000 ||
           values[p+5] < 0 || values[p+5] > 1_000_000 { return -1; }
    }
    let mut real = [0.0_f32; CELLS];
    let mut imag = [0.0_f32; CELLS];
    let mut density = [0.0_f32; CELLS];
    let cutoff = (f64::from(WIDTH) / 2.0_f64) as f32;
    let cutoff2 = cutoff * cutoff;
    let inverse = 1.0_f32 / cutoff2;
    let beta = beta_value();
    for s in 0..n as usize {
        let p = 1 + 6*s;
        let kx=decode(values[p]); let ky=decode(values[p+1]); let kz=decode(values[p+2]);
        let sr=decode(values[p+3]); let si=decode(values[p+4]); let sdc=decode(values[p+5]);
        if !(sr != 0.0_f32 || si != 0.0_f32) || sdc == 0.0_f32 { continue; }
        let x0=lower(kx,cutoff); let x1=upper(kx,cutoff);
        let y0=lower(ky,cutoff); let y1=upper(ky,cutoff);
        let z0=lower(kz,cutoff); let z1=upper(kz,cutoff);
        for z in z0..=z1 {
            let dz=kz-z as f32; let dz2=dz*dz;
            if dz2 < cutoff2 {
                for y in y0..=y1 {
                    let dy=ky-y as f32; let dy2=dy*dy; let yz=dz2+dy2;
                    if yz < cutoff2 {
                        for x in x0..=x1 {
                            let dx=kx-x as f32; let dx2=dx*dx; let v=yz+dx2;
                            if v < cutoff2 {
                                let index=x+3*y+9*z;
                                let w=weight(v,inverse,beta,sdc);
                                let dr=w*sr; let di=w*si;
                                real[index]=real[index]+dr;
                                imag[index]=imag[index]+di;
                                density[index]=(f64::from(density[index])+1.0_f64) as f32;
                            }
                        }
                    }
                }
            }
        }
    }
    let mut checksum=0_i64;
    for i in 0..CELLS {
        checksum += (i as i64+1)*(quantize(real[i])+quantize(imag[i])+density[i] as i64);
    }
    checksum
}
