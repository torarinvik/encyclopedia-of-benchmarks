from std.collections import InlineArray

fn pifft_transform(inout re: InlineArray[Float64, 8], inout im: InlineArray[Float64, 8], inverse: Bool):
    var j = 0
    for i in range(1, 8):
        var bit = 4
        while (j & bit) != 0:
            j = j ^ bit
            bit >>= 1
        j = j ^ bit
        if i < j:
            let r = re[i]
            let t = im[i]
            re[i] = re[j]
            im[i] = im[j]
            re[j] = r
            im[j] = t
    for stage in range(1, 4):
        let size = 1 << stage
        let half = size // 2
        var wr: Float64 = -1.0
        var wi: Float64 = 0.0
        if size == 4:
            wr = 0.0
            wi = 1.0 if inverse else -1.0
        elif size == 8:
            wr = 0.7071067811865476
            wi = 0.7071067811865476 if inverse else -0.7071067811865476
        var start = 0
        while start < 8:
            var tr: Float64 = 1.0
            var ti: Float64 = 0.0
            for offset in range(half):
                let even = start + offset
                let odd = even + half
                let rr = re[odd] * tr - im[odd] * ti
                let ri = re[odd] * ti + im[odd] * tr
                let er = re[even]
                let ei = im[even]
                re[even] = er + rr
                im[even] = ei + ri
                re[odd] = er - rr
                im[odd] = ei - ri
                let next_r = tr * wr - ti * wi
                ti = tr * wi + ti * wr
                tr = next_r
            start += size
    if inverse:
        for i in range(8):
            re[i] /= 8.0
            im[i] /= 8.0

fn pifft_multiply(left: Int64, right: Int64) -> Int64:
    var x = left
    var y = right
    var sign: Int64 = 1
    if x < 0: sign = -sign; x = -x
    if y < 0: sign = -sign; y = -y
    var xr = InlineArray[Float64, 8](fill=0.0)
    var xi = InlineArray[Float64, 8](fill=0.0)
    var yr = InlineArray[Float64, 8](fill=0.0)
    var yi = InlineArray[Float64, 8](fill=0.0)
    for i in range(3):
        xr[i] = Float64(x % 1000)
        yr[i] = Float64(y % 1000)
        x //= 1000
        y //= 1000
    pifft_transform(xr, xi, False)
    pifft_transform(yr, yi, False)
    for i in range(8):
        let r = xr[i] * yr[i] - xi[i] * yi[i]
        let im = xr[i] * yi[i] + xi[i] * yr[i]
        xr[i] = r
        xi[i] = im
    pifft_transform(xr, xi, True)
    var product: Int64 = 0
    var place: Int64 = 1
    for i in range(5):
        product += Int64(xr[i] + 0.5) * place
        place *= 1000
    return sign * ((product + 500000) // 1000000)

fn pifft_sqrt(value: Int64) -> Int64:
    if value <= 0: return 0
    let radicand = value * 1000000
    var root = radicand
    while True:
        let next = (root + radicand // root) // 2
        if next >= root: break
        root = next
    if (root + 1) * (root + 1) - radicand < radicand - root * root: return root + 1
    return root

fn pifft_half(value: Int64) -> Int64:
    if value < 0: return -((-value) // 2)
    return value // 2

fn pifft_divide(numerator: Int64, denominator: Int64) -> Int64:
    if denominator <= 0: return 0
    let scaled = numerator * 1000000
    if scaled < 0: return -((-scaled + denominator // 2) // denominator)
    return (scaled + denominator // 2) // denominator

@export("freebench_pifft")
fn freebench_pifft(nfft: Int64) abi("C") -> Int64:
    if nfft != 8: return -1
    var c = pifft_sqrt(125000)
    var a = Int64(1000000) + 3 * c
    var b = pifft_sqrt(a)
    var e = b - 625000
    b *= 2
    c = e - c
    a += e
    var power: Int64 = 4
    for _ in range(8):
        power *= 2
        e = pifft_half(a + b)
        b = pifft_sqrt(pifft_multiply(a, b))
        e -= b
        b *= 2
        c -= e
        a = e + b
        if e >= -1 and e <= 1: break
    e = pifft_half(e)
    e = pifft_multiply(e, e)
    a += b
    let numerator = pifft_multiply(a, a) - e - pifft_half(e)
    let denominator = pifft_multiply(a, c) - e
    let pi = (pifft_divide(numerator, denominator) + power // 2) // power
    return (pi + 500) // 1000
