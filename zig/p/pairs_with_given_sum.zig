/// Count every pair of distinct indices whose values sum to the target.
const MAX_INPUT_LENGTH: usize = 257;

export fn pairs_with_given_sum(input: [*c]const i64, length: usize) i64 {
    if (input == null or length == 0 or length > MAX_INPUT_LENGTH) return -2;
    for (0..length) |index| {
        if (input[index] < -2_147_483_648 or input[index] > 2_147_483_647) return -2;
    }
    const target = input[0];
    const value_count = length - 1;
    var pairs: i64 = 0;
    for (0..value_count) |left| {
        for (left + 1..value_count) |right| {
            if (input[left + 1] + input[right + 1] == target) pairs += 1;
        }
    }
    return pairs;
}
