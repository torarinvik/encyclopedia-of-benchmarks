/// Iteratively compute L(0)=L(1)=1 and L(n)=L(n-1)+L(n-2)+1.
#[no_mangle]
pub extern "C" fn leonardo_number(input: i64) -> i64 {
    if !(0..=89).contains(&input) { return -1; }
    let (mut previous, mut current) = (1i64, 1i64);
    for _ in 2..=input {
        let next = current + previous + 1;
        previous = current;
        current = next;
    }
    current
}
