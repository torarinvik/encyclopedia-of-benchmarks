struct Matrix {
    prefix: [[usize; 65]; 11],
    zeros: [usize; 11],
}

impl Matrix {
    fn less(&self, mut l: usize, mut r: usize, key: usize) -> usize {
        let mut count = 0;
        for level in 0..11 {
            let zl = self.prefix[level][l];
            let zr = self.prefix[level][r];
            if key & (1 << (10 - level)) != 0 {
                count += zr - zl;
                l = self.zeros[level] + l - zl;
                r = self.zeros[level] + r - zr;
            } else {
                l = zl;
                r = zr;
            }
        }
        count
    }
    fn quantile(&self, mut l: usize, mut r: usize, mut k: usize) -> i64 {
        let mut value = 0;
        for level in 0..11 {
            let zl = self.prefix[level][l];
            let zr = self.prefix[level][r];
            if k < zr - zl {
                l = zl;
                r = zr;
            } else {
                k -= zr - zl;
                value |= 1 << (10 - level);
                l = self.zeros[level] + l - zl;
                r = self.zeros[level] + r - zr;
            }
        }
        value - 1000
    }
}

#[no_mangle]
pub unsafe extern "C" fn wavelet_matrix(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(2..=706).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if !(1..=64).contains(&input[0]) { return -1; }
    let n = input[0] as usize;
    if length < n + 2 || input[1..n + 1].iter().any(|x| !(-1000..=1000).contains(x)) { return -1; }
    let q = input[n + 1];
    if !(0..=128).contains(&q) || length != n + 2 + 5 * q as usize { return -1; }
    let mut matrix = Matrix { prefix: [[0; 65]; 11], zeros: [0; 11] };
    let mut current = [0_usize; 64];
    let mut scratch = [0_usize; 64];
    for i in 0..n { current[i] = (input[1 + i] + 1000) as usize; }
    for level in 0..11 {
        let bit = 10 - level;
        for i in 0..n {
            matrix.prefix[level][i + 1] = matrix.prefix[level][i] + usize::from(current[i] & (1 << bit) == 0);
        }
        let zeros = matrix.prefix[level][n];
        matrix.zeros[level] = zeros;
        let (mut z, mut o) = (0, zeros);
        for &value in &current[..n] {
            if value & (1 << bit) == 0 { scratch[z] = value; z += 1; }
            else { scratch[o] = value; o += 1; }
        }
        current[..n].copy_from_slice(&scratch[..n]);
    }
    let mut total = 0_i64;
    for j in 0..q as usize {
        let at = n + 2 + 5*j;
        let (op, a, b, c, d) = (input[at], input[at+1], input[at+2], input[at+3], input[at+4]);
        let answer = match op {
            0 => {
                if !(-1000..=1000).contains(&a) || b < -1 || b >= n as i64 { return -1; }
                let right = (b + 1) as usize;
                (matrix.less(0, right, (a + 1001) as usize) - matrix.less(0, right, (a + 1000) as usize)) as i64
            }
            1 => {
                if a < 0 || a > b || b >= n as i64 || c < 0 || c > b - a { return -1; }
                matrix.quantile(a as usize, b as usize + 1, c as usize)
            }
            2 => {
                if a < 0 || a > b || b >= n as i64 || c < -1000 || c > d || d > 1000 { return -1; }
                (matrix.less(a as usize, b as usize + 1, (d + 1001) as usize)
                    - matrix.less(a as usize, b as usize + 1, (c + 1000) as usize)) as i64
            }
            _ => return -1,
        };
        total += (j as i64 + 1) * (answer + 1_000_001);
    }
    total
}
