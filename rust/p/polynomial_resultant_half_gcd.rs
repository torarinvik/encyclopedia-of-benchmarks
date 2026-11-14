// Draft implementation: no compilation or execution has been performed.
const P: i64 = 998_244_353;
type Poly = Vec<i64>;

fn power(mut x: i64, mut n: usize) -> i64 {
    let mut y = 1;
    while n != 0 {
        if n & 1 != 0 { y = y * x % P; }
        x = x * x % P;
        n >>= 1;
    }
    y
}

fn trim(a: &mut Poly) { while a.last() == Some(&0) { a.pop(); } }

fn ntt(a: &mut [i64], inverse: bool) {
    let n = a.len();
    let mut j = 0;
    for i in 1..n {
        let mut bit = n >> 1;
        while j & bit != 0 { j ^= bit; bit >>= 1; }
        j ^= bit;
        if i < j { a.swap(i, j); }
    }
    let mut width = 2;
    while width <= n {
        let mut w = power(3, (P as usize - 1) / width);
        if inverse { w = power(w, P as usize - 2); }
        for base in (0..n).step_by(width) {
            let mut z = 1;
            for k in 0..width / 2 {
                let u = a[base + k];
                let v = a[base + k + width / 2] * z % P;
                a[base + k] = (u + v) % P;
                a[base + k + width / 2] = (u - v + P) % P;
                z = z * w % P;
            }
        }
        width *= 2;
    }
    if inverse {
        let scale = power(n as i64, P as usize - 2);
        for x in a { *x = *x * scale % P; }
    }
}

fn mul(a: &[i64], b: &[i64]) -> Poly {
    if a.is_empty() || b.is_empty() { return vec![]; }
    let count = a.len() + b.len() - 1;
    let mut out = vec![0; count];
    if a.len().min(b.len()) <= 32 {
        for (i, &x) in a.iter().enumerate() {
            for (j, &y) in b.iter().enumerate() {
                out[i + j] = (out[i + j] + x * y) % P;
            }
        }
    } else {
        let n = count.next_power_of_two();
        let mut x = a.to_vec();
        let mut y = b.to_vec();
        x.resize(n, 0); y.resize(n, 0);
        ntt(&mut x, false); ntt(&mut y, false);
        for i in 0..n { x[i] = x[i] * y[i] % P; }
        ntt(&mut x, true);
        out.copy_from_slice(&x[..count]);
    }
    trim(&mut out); out
}

fn add(a: &[i64], b: &[i64]) -> Poly {
    let mut out = vec![0; a.len().max(b.len())];
    for (i, &x) in a.iter().enumerate() { out[i] = x; }
    for (i, &x) in b.iter().enumerate() { out[i] = (out[i] + x) % P; }
    trim(&mut out); out
}

fn divrem(a: &[i64], b: &[i64]) -> (Poly, Poly) {
    if a.len() < b.len() { return (vec![], a.to_vec()); }
    let count = a.len() - b.len() + 1;
    let reverse_b: Poly = b.iter().rev().copied().collect();
    let high: Poly = a.iter().rev().take(count).copied().collect();
    let mut inverse = vec![power(reverse_b[0], P as usize - 2)];
    while inverse.len() < count {
        let size = count.min(2 * inverse.len());
        let mut correction = mul(&reverse_b[..size.min(reverse_b.len())], &inverse);
        correction.resize(size, 0);
        for x in &mut correction { *x = (P - *x) % P; }
        correction[0] = (correction[0] + 2) % P;
        inverse = mul(&inverse, &correction);
        inverse.resize(size, 0);
    }
    let mut q = mul(&high, &inverse);
    q.resize(count, 0); q.reverse();
    let removed = mul(&q, b);
    let mut r = vec![0; b.len() - 1];
    for i in 0..r.len() { r[i] = (a[i] - removed.get(i).copied().unwrap_or(0) + P) % P; }
    trim(&mut q); trim(&mut r); (q, r)
}

#[derive(Clone)]
struct Matrix { a: Poly, b: Poly, c: Poly, d: Poly }
impl Matrix {
    fn identity() -> Self { Self { a: vec![1], b: vec![], c: vec![], d: vec![1] } }
    fn step(q: &[i64]) -> Self {
        Self { a: vec![], b: vec![1], c: vec![1], d: q.iter().map(|&x| (P - x) % P).collect() }
    }
    fn compose(&self, rhs: &Self) -> Self {
        Self { a: add(&mul(&self.a, &rhs.a), &mul(&self.b, &rhs.c)),
               b: add(&mul(&self.a, &rhs.b), &mul(&self.b, &rhs.d)),
               c: add(&mul(&self.c, &rhs.a), &mul(&self.d, &rhs.c)),
               d: add(&mul(&self.c, &rhs.b), &mul(&self.d, &rhs.d)) }
    }
    fn apply(&self, a: &[i64], b: &[i64]) -> (Poly, Poly) {
        (add(&mul(&self.a, a), &mul(&self.b, b)), add(&mul(&self.c, a), &mul(&self.d, b)))
    }
}

fn upper(a: &[i64], shift: usize) -> &[i64] { &a[shift.min(a.len())..] }

fn half_reduce(a: &[i64], b: &[i64], heads: &mut Vec<(usize, i64)>) -> Matrix {
    if b.is_empty() { return Matrix::identity(); }
    let degree = a.len() - 1;
    let threshold = (degree + 1) / 2;
    if b.len() <= threshold { return Matrix::identity(); }
    if degree <= 64 {
        let (mut x, mut y) = (a.to_vec(), b.to_vec());
        let mut result = Matrix::identity();
        while !y.is_empty() && y.len() > threshold {
            let (q, r) = divrem(&x, &y);
            heads.push((q.len() - 1, q[q.len() - 1]));
            result = Matrix::step(&q).compose(&result);
            x = y; y = r;
        }
        return result;
    }
    let first = half_reduce(upper(a, threshold), upper(b, threshold), heads);
    let (c, d) = first.apply(a, b);
    if d.is_empty() || d.len() <= threshold { return first; }
    let (q, r) = divrem(&c, &d);
    heads.push((q.len() - 1, q[q.len() - 1]));
    let prefix = Matrix::step(&q).compose(&first);
    if r.is_empty() { return prefix; }
    let shift = 2 * threshold - (d.len() - 1);
    if upper(&r, shift).is_empty() { return prefix; }
    half_reduce(upper(&d, shift), upper(&r, shift), heads).compose(&prefix)
}

fn resultant(mut a: Poly, mut b: Poly) -> i64 {
    let mut answer = 1;
    if a.len() < b.len() {
        if (a.len() - 1) & 1 != 0 && (b.len() - 1) & 1 != 0 { answer = P - answer; }
        std::mem::swap(&mut a, &mut b);
    }
    loop {
        if b.len() == 1 { return answer * power(b[0], a.len() - 1) % P; }
        let mut heads = Vec::new();
        let reduced = if a.len() == b.len() { None } else {
            let m = half_reduce(&a, &b, &mut heads);
            if heads.is_empty() { None } else { Some(m.apply(&a, &b)) }
        };
        if let Some((c, d)) = reduced {
            if d.is_empty() { return 0; }
            let (mut da, mut db, mut lead) = (a.len() - 1, b.len() - 1, b[b.len() - 1]);
            for i in 0..heads.len() {
                let last = i + 1 == heads.len();
                let dr = if last { d.len() - 1 } else { db - heads[i + 1].0 };
                if da & 1 != 0 && db & 1 != 0 { answer = P - answer; }
                answer = answer * power(lead, da - dr) % P;
                if !last { lead = lead * power(heads[i + 1].1, P as usize - 2) % P; }
                da = db; db = dr;
            }
            a = c; b = d;
        } else {
            let (_, r) = divrem(&a, &b);
            if r.is_empty() { return 0; }
            let (da, db, dr) = (a.len() - 1, b.len() - 1, r.len() - 1);
            if da & 1 != 0 && db & 1 != 0 { answer = P - answer; }
            answer = answer * power(b[b.len() - 1], da - dr) % P;
            a = b; b = r;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn polynomial_resultant_half_gcd(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > 100_002 { return -1; }
    let data = std::slice::from_raw_parts(input, length);
    let (m, n) = (data[0], data[1]);
    if !(0..=50_000).contains(&m) || !(0..=50_000).contains(&n) || m + n > 99_998 { return -1; }
    let (m, n) = (m as usize, n as usize);
    if length != m + n + 4 || data[2..].iter().any(|&x| x < 0 || x >= P)
        || data[2 + m] == 0 || data[length - 1] == 0 { return -1; }
    resultant(data[2..3 + m].to_vec(), data[3 + m..].to_vec())
}
