/// Search triangular-number products for the rectangle count nearest the target.
const MAX_TARGET: i64 = 2_000_000_000;

fn triangle(side: i64) -> i64 {
    side * (side + 1) / 2
}

fn absolute_difference(left: i64, right: i64) -> i64 {
    (left - right).abs()
}

#[no_mangle]
pub extern "C" fn problem85(target: i64) -> i64 {
    if target < 0 || target > MAX_TARGET {
        return -1;
    }
    let bound = (((target * 2) as f64).sqrt() * 1.1).ceil() as i64;
    let mut best_product = 0i64;
    let mut area = 0i64;
    let mut triangle_a = 0i64;
    for a in 1..bound {
        triangle_a += a;
        let estimate = (-1.0 + (1.0 + 8.0 * target as f64 / triangle_a as f64).sqrt()) / 2.0;
        let b_floor = estimate.floor() as i64;
        let b_ceil = estimate.ceil() as i64;
        let first_product = triangle_a * triangle(b_floor);
        let second_product = triangle_a * triangle(b_ceil);
        if absolute_difference(target, first_product) < absolute_difference(target, best_product) {
            best_product = first_product;
            area = a * b_floor;
        }
        if absolute_difference(target, second_product) < absolute_difference(target, best_product) {
            best_product = second_product;
            area = a * b_ceil;
        }
    }
    area
}
