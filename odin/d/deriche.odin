package deriche

import "core:math"

MAX_WIDTH :: 32
MAX_HEIGHT :: 32
MAX_PIXELS :: MAX_WIDTH * MAX_HEIGHT
INVALID_RESULT :: -1.0e300

filter_once :: proc(width, height: int, image, output, y1, y2: [^]f32) {
    alpha := f32(0.25)
    exp_neg_alpha := f32(math.exp_f64(-f64(alpha)))
    difference := f32(1.0) - exp_neg_alpha
    numerator := difference * difference
    denominator_left := f32(1.0) + f32(2.0) * alpha * exp_neg_alpha
    k := numerator / (denominator_left - f32(math.exp_f64(f64(f32(2.0) * alpha))))
    a1 := k
    a2 := k * exp_neg_alpha * (alpha - f32(1.0))
    a3 := k * exp_neg_alpha * (alpha + f32(1.0))
    a4 := -k * f32(math.exp_f64(f64(f32(-2.0) * alpha)))
    a5, a6, a7, a8 := k, a2, a3, a4
    b1 := f32(math.pow_f64(2.0, -f64(alpha)))
    b2 := -f32(math.exp_f64(f64(f32(-2.0) * alpha)))
    for i := 0; i < width; i += 1 {
        ym1, ym2, xm1 := f32(0), f32(0), f32(0)
        for j := 0; j < height; j += 1 {
            at := i * height + j
            value := a1 * image[at] + a2 * xm1
            value = value + b1 * ym1; value = value + b2 * ym2; y1[at] = value
            xm1 = image[at]; ym2 = ym1; ym1 = value
        }
    }
    for i := 0; i < width; i += 1 {
        yp1, yp2, xp1, xp2 := f32(0), f32(0), f32(0), f32(0)
        for j := height; j > 0; {
            j -= 1; at := i * height + j
            value := a3 * xp1 + a4 * xp2
            value = value + b1 * yp1; value = value + b2 * yp2; y2[at] = value
            xp2 = xp1; xp1 = image[at]; yp2 = yp1; yp1 = value
        }
    }
    for i := 0; i < width; i += 1 { for j := 0; j < height; j += 1 {
        at := i * height + j; output[at] = f32(1) * (y1[at] + y2[at])
    }}
    for j := 0; j < height; j += 1 {
        tm1, ym1, ym2 := f32(0), f32(0), f32(0)
        for i := 0; i < width; i += 1 {
            at := i * height + j
            value := a5 * output[at] + a6 * tm1
            value = value + b1 * ym1; value = value + b2 * ym2; y1[at] = value
            tm1 = output[at]; ym2 = ym1; ym1 = value
        }
    }
    for j := 0; j < height; j += 1 {
        tp1, tp2, yp1, yp2 := f32(0), f32(0), f32(0), f32(0)
        for i := width; i > 0; {
            i -= 1; at := i * height + j
            value := a7 * tp1 + a8 * tp2
            value = value + b1 * yp1; value = value + b2 * yp2; y2[at] = value
            tp2 = tp1; tp1 = output[at]; yp2 = yp1; yp1 = value
        }
    }
    for at := 0; at < width * height; at += 1 { output[at] = f32(1) * (y1[at] + y2[at]) }
}

@(export)
deriche :: proc "c" (values: [^]i64, length: uint) -> f64 {
    if values == nil || length != 3 || values[0] < 1 || values[0] > MAX_WIDTH || values[1] < 1 || values[1] > MAX_HEIGHT || values[2] < 1 || values[2] > 4 do return INVALID_RESULT
    width, height := int(values[0]), int(values[1])
    var image: [MAX_PIXELS]f32
    var output: [MAX_PIXELS]f32
    var y1: [MAX_PIXELS]f32
    var y2: [MAX_PIXELS]f32
    for i := 0; i < width; i += 1 { for j := 0; j < height; j += 1 {
        image[i * height + j] = f32((313 * i + 991 * j) % 65536) / f32(65535)
    }}
    for pass := i64(0); pass < values[2]; pass += 1 {
        filter_once(width, height, &image[0], &output[0], &y1[0], &y2[0])
        for at := 0; at < width * height; at += 1 { image[at] = output[at] }
    }
    checksum := f64(0)
    for at := 0; at < width * height; at += 1 { checksum += f64(output[at]) }
    return checksum
}
