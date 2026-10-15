export fn golombs_sequence(index: i64) i64 {
    if (index < 0 or index > 64) return -1;
    if (index == 0) return 1;
    if (index <= 2) return 2;
    var queue: [65]i64 = [_]i64{0} ** 65;
    queue[0] = 2;
    var head: usize = 0;
    var tail: usize = 1;
    var generated: i64 = 3;
    var value: i64 = 3;
    while (generated <= index) {
        const repetitions = queue[head];
        head += 1;
        var repeated: i64 = 0;
        while (repeated < repetitions and generated <= index) : (repeated += 1) {
            queue[tail] = value;
            tail += 1;
            if (generated == index) return value;
            generated += 1;
        }
        value += 1;
    }
    return -1;
}
