/// Iteratively compute L(0)=L(1)=1 and L(n)=L(n-1)+L(n-2)+1.
export fn leonardo_number(input: i64) i64 {
    if (input < 0 or input > 89) return -1;
    var previous: i64 = 1;
    var current: i64 = 1;
    var index: i64 = 2;
    while (index <= input) : (index += 1) {
        const next = current + previous + 1;
        previous = current;
        current = next;
    }
    return current;
}
