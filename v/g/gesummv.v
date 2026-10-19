module gesummv

const max_dimension = 64
const invalid_result = -1.0e300

@[export: 'gesummv']
pub fn gesummv(values &i64, length usize) f64 {
    if unsafe { values == nil } || length != 1 { return invalid_result }
    unsafe {
        if values[0] < 1 || values[0] > max_dimension { return invalid_result }
        n := int(values[0])
        mut x := []f64{len: max_dimension, init: 0.0}
        for i in 0 .. n { x[i] = f64(i % n) / f64(n) }
        mut result := 0.0
        for i in 0 .. n {
            mut temporary := 0.0
            mut y := 0.0
            for j in 0 .. n {
                a := f64((i * j + 1) % n) / f64(n)
                b := f64((i * j + 2) % n) / f64(n)
                temporary = a * x[j] + temporary
                y = b * x[j] + y
            }
            y = 1.5 * temporary + 1.2 * y
            result += y
        }
        return result
    }
}
