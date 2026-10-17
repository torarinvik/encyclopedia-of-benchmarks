module euler_problem_6;

fn long euler_problem_6(long* input, usz length) @export("euler_problem_6") {
    if (input == null || length < 1 || length > 2 || length != 1 || input[0] < 1 || input[0] > 100) return -1;
    long sum = 0;
    long sum_of_squares = 0;
    for (long value = 1; value <= input[0]; ++value) {
        sum += value;
        sum_of_squares += value * value;
    }
    return sum * sum - sum_of_squares;
}
