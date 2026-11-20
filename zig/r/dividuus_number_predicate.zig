const MAX_N: i64 = 100_000;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn digitSum(value_arg: i64) i64 {
    var value = value_arg;
    var total: i64 = 0;
    while (value > 0) {
        total += @rem(value, 10);
        value = @divTrunc(value, 10);
    }
    return total;
}

fn digitProduct(value_arg: i64) i64 {
    var value = value_arg;
    var product: i64 = 1;
    while (value > 0) {
        product *= @rem(value, 10);
        value = @divTrunc(value, 10);
    }
    return product;
}

fn digitalRoot(value_arg: i64) i64 {
    var value = value_arg;
    while (value >= 10) value = digitSum(value);
    return value;
}

fn multiplicativeRoot(value_arg: i64) i64 {
    var value = value_arg;
    while (value >= 10) value = digitProduct(value);
    return value;
}

fn isDividuus(n: i64) bool {
    const sum = digitSum(n);
    const product = digitProduct(n);
    const root = digitalRoot(n);
    const mroot = multiplicativeRoot(n);
    if (sum == 0 or product == 0 or root == 0 or mroot == 0) return false;
    return @rem(n, sum) == 0 and @rem(n, product) == 0 and @rem(n, root) == 0 and @rem(n, mroot) == 0;
}

export fn dividuus_number_predicate(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1) return -1;
    const n = values[0];
    if (n < 1 or n > MAX_N) return -1;
    return if (isDividuus(n)) 1 else 0;
}
