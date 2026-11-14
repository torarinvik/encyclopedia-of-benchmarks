// Independent polynomial-tree difference product draft; see package README.
const MODULUS: i64 = 998_244_353;

fn power(mut value: i64, mut exponent: i64) -> i64 {
    let mut result = 1;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * value % MODULUS; }
        value = value * value % MODULUS;
        exponent >>= 1;
    }
    result
}

fn transform(values: &mut [i64], inverse: bool) {
    let n = values.len();
    let mut reversed = 0usize;
    for i in 1..n {
        let mut bit = n >> 1;
        while reversed & bit != 0 { reversed ^= bit; bit >>= 1; }
        reversed ^= bit;
        if i < reversed { values.swap(i, reversed); }
    }
    let mut width = 2;
    while width <= n {
        let mut step = power(3, (MODULUS - 1) / width as i64);
        if inverse { step = power(step, MODULUS - 2); }
        for block in (0..n).step_by(width) {
            let mut root = 1;
            for offset in 0..width / 2 {
                let a = values[block + offset];
                let b = values[block + offset + width / 2] * root % MODULUS;
                values[block + offset] = (a + b) % MODULUS;
                values[block + offset + width / 2] = (a - b + MODULUS) % MODULUS;
                root = root * step % MODULUS;
            }
        }
        width *= 2;
    }
    if inverse {
        let scale = power(n as i64, MODULUS - 2);
        for value in values { *value = *value * scale % MODULUS; }
    }
}

fn multiply(a: &[i64], b: &[i64]) -> Vec<i64> {
    if a.is_empty() || b.is_empty() { return vec![]; }
    let output = a.len() + b.len() - 1;
    if a.len().min(b.len()) <= 32 {
        let mut result = vec![0; output];
        for (i, &x) in a.iter().enumerate() {
            for (j, &y) in b.iter().enumerate() {
                result[i + j] = (result[i + j] + x * y) % MODULUS;
            }
        }
        return result;
    }
    let size = output.next_power_of_two();
    let mut left = vec![0; size];
    let mut right = vec![0; size];
    left[..a.len()].copy_from_slice(a);
    right[..b.len()].copy_from_slice(b);
    transform(&mut left, false);
    transform(&mut right, false);
    for i in 0..size { left[i] = left[i] * right[i] % MODULUS; }
    transform(&mut left, true);
    left.truncate(output);
    left
}

fn series_inverse(f: &[i64], count: usize) -> Vec<i64> {
    let mut result = vec![power(f[0], MODULUS - 2)];
    while result.len() < count {
        let n = count.min(2 * result.len());
        let mut correction = multiply(&f[..f.len().min(n)], &result);
        correction.resize(n, 0);
        for coefficient in &mut correction { *coefficient = (MODULUS - *coefficient) % MODULUS; }
        correction[0] = (correction[0] + 2) % MODULUS;
        result = multiply(&result, &correction);
        result.truncate(n);
    }
    result
}

fn remainder(dividend: &[i64], divisor: &[i64]) -> Vec<i64> {
    if dividend.len() < divisor.len() { return dividend.to_vec(); }
    if divisor.len() == 1 { return vec![]; }
    let q_len = dividend.len() - divisor.len() + 1;
    let high: Vec<_> = dividend.iter().rev().take(q_len).copied().collect();
    let reversed: Vec<_> = divisor.iter().rev().copied().collect();
    let mut quotient = multiply(&high, &series_inverse(&reversed, q_len));
    quotient.truncate(q_len);
    quotient.reverse();
    let removed = multiply(&quotient, divisor);
    let mut result = vec![0; divisor.len() - 1];
    for i in 0..result.len() {
        result[i] = (dividend[i] - removed.get(i).copied().unwrap_or(0) + MODULUS) % MODULUS;
    }
    while result.last() == Some(&0) { result.pop(); }
    result
}

struct PointTree { size: usize, count: usize, products: Vec<Vec<i64>> }

impl PointTree {
    fn new(points: &[i64]) -> Self {
        let size = points.len().max(1).next_power_of_two();
        let mut products = vec![Vec::new(); 2 * size];
        for i in 0..size {
            products[size + i] = if i < points.len() { vec![(MODULUS - points[i]) % MODULUS, 1] } else { vec![1] };
        }
        for i in (1..size).rev() { products[i] = multiply(&products[2 * i], &products[2 * i + 1]); }
        Self { size, count: points.len(), products }
    }

    fn visit(&self, node: usize, value: &[i64], output: &mut [i64]) {
        if node >= self.size {
            let index = node - self.size;
            if index < self.count && !value.is_empty() { output[index] = value[0]; }
            return;
        }
        let left = remainder(value, &self.products[node * 2]);
        let right = remainder(value, &self.products[node * 2 + 1]);
        self.visit(node * 2, &left, output);
        self.visit(node * 2 + 1, &right, output);
    }

    fn evaluate(&self, polynomial: &[i64]) -> Vec<i64> {
        let mut output = vec![0; self.count];
        if self.count != 0 {
            self.visit(1, &remainder(polynomial, &self.products[1]), &mut output);
        }
        output
    }
}

fn ordered_product(points: &[i64]) -> i64 {
    if points.len() <= 32 {
        let mut result = 1;
        for i in 0..points.len() {
            for j in i + 1..points.len() { result = result * ((points[i] - points[j] + MODULUS) % MODULUS) % MODULUS; }
        }
        return result;
    }
    let mid = points.len() / 2;
    let (left, right) = points.split_at(mid);
    let mut result = ordered_product(left) * ordered_product(right) % MODULUS;
    if result == 0 { return 0; }
    let left_tree = PointTree::new(left);
    let right_tree = PointTree::new(right);
    for value in right_tree.evaluate(&left_tree.products[1]) { result = result * value % MODULUS; }
    if left.len() & 1 != 0 && right.len() & 1 != 0 && result != 0 { result = MODULUS - result; }
    result
}

#[no_mangle]
pub unsafe extern "C" fn difference_product(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || *input < 0 || *input > 65536 { return -1; }
    let count = *input as usize;
    if length != count + 1 { return -1; }
    let points = std::slice::from_raw_parts(input.add(1), count);
    if points.iter().any(|&x| x < 0 || x >= MODULUS) { return -1; }
    ordered_product(points)
}
