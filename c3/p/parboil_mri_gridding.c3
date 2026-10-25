module parboil_mri_gridding;
import "math";

const int SIDE = 3;
const int CELLS = 27;
const long MAX_SAMPLES = 4;
const float WIDTH = 2.5f;
const float OVERSAMPLE = 0.608933f;
const float[15] COEFF = {
    0.210580722890567e-22f, 0.380715242345326e-19f, 0.479440257548300e-16f,
    0.435125971262668e-13f, 0.300931127112960e-10f, 0.160224679395361e-7f,
    0.654858370096785e-5f, 0.202591084143397e-2f, 0.463076284721000e0f,
    0.754337328948189e2f, 0.830792541809429e4f, 0.571661130563785e6f,
    0.216415572361227e8f, 0.356644482244025e9f, 0.144048298227235e10f
};

fn float decode(long raw) { return float(raw) / 1000000.0f; }
fn float kernel(float value) {
    float z = value * value;
    float num = COEFF[0];
    for (int i = 1; i < 15; i += 1) { float product = z * num; num = product + COEFF[i]; }
    float den = z - 0.307646912682801e4f;
    den = z * den; den = den + 0.347626332405882e7f;
    den = z * den; den = den - 0.144048298227235e10f;
    return -num / den;
}
fn float beta_value() {
    float first = 4.0f * WIDTH; first = first * WIDTH;
    float divisor = OVERSAMPLE * OVERSAMPLE; first = first / divisor;
    double shifted = double(OVERSAMPLE) - 0.5;
    double arg = double(first) * shifted; arg = arg * shifted; arg = arg - 0.8;
    return float(3.14159265359 * math.sqrt(arg));
}
fn float weight(float v, float inverse, float beta, float sdc) {
    float product = v * inverse;
    double radicand = 1.0 - double(product);
    float arg = float(double(beta) * math.sqrt(radicand));
    return kernel(arg) * sdc;
}
fn int lower(float k, float cutoff) { float d = k - cutoff; double v = double(d); if (v < 0.0) v = 0.0; return int(uint(v)); }
fn int upper(float k, float cutoff) { float s = k + cutoff; double v = double(s); if (v > 2.0) v = 2.0; return int(uint(v)); }
fn long quantize(float value) {
    float scaled = value * 1000.0f; float mag = scaled < 0.0f ? -scaled : scaled;
    long whole = long(mag); if (mag - float(whole) >= 0.5f) whole++;
    return scaled < 0.0f ? -whole : whole;
}

fn long parboil_mri_gridding(long* input, usz length) @export("parboil_mri_gridding") {
    if (input == null || length < 1 || length > 25) return -1;
    long n = input[0];
    if (n < 0 || n > MAX_SAMPLES || length != usz(1 + 6*n)) return -1;
    for (long s = 0; s < n; s += 1) {
        usz p = usz(1 + s*6);
        for (int a = 0; a < 3; a += 1) if (input[p+a] != 0 && input[p+a] != 1000000 && input[p+a] != 2000000) return -1;
        if (input[p+3] < -1000000 || input[p+3] > 1000000 || input[p+4] < -1000000 || input[p+4] > 1000000 || input[p+5] < 0 || input[p+5] > 1000000) return -1;
    }
    float[27] real = {}, imag = {}, density = {};
    float cutoff = float(double(WIDTH) / 2.0); float cutoff2 = cutoff*cutoff; float inverse = 1.0f/cutoff2; float beta = beta_value();
    for (long s = 0; s < n; s += 1) {
        usz p = usz(1+s*6);
        float kx=decode(input[p]), ky=decode(input[p+1]), kz=decode(input[p+2]);
        float sr=decode(input[p+3]), si=decode(input[p+4]), sdc=decode(input[p+5]);
        if (!(sr != 0.0f || si != 0.0f) || sdc == 0.0f) continue;
        int x0=lower(kx,cutoff), x1=upper(kx,cutoff), y0=lower(ky,cutoff), y1=upper(ky,cutoff), z0=lower(kz,cutoff), z1=upper(kz,cutoff);
        for (int z=z0; z<=z1; z+=1) {
            float dz=kz-float(z), dz2=dz*dz;
            if (dz2 < cutoff2) for (int y=y0; y<=y1; y+=1) {
                float dy=ky-float(y), dy2=dy*dy, yz=dz2+dy2;
                if (yz < cutoff2) for (int x=x0; x<=x1; x+=1) {
                    float dx=kx-float(x), dx2=dx*dx, v=yz+dx2;
                    if (v < cutoff2) {
                        int index=x+SIDE*y+SIDE*SIDE*z; float w=weight(v,inverse,beta,sdc);
                        float dr=w*sr, di=w*si; real[index]=real[index]+dr; imag[index]=imag[index]+di;
                        density[index]=float(double(density[index])+1.0);
                    }
                }
            }
        }
    }
    long checksum=0;
    for (int i=0;i<CELLS;i+=1) checksum += long(i+1)*(quantize(real[i])+quantize(imag[i])+long(density[i]));
    return checksum;
}
