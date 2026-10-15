const CHECK_LETTERS = "TRWAGMYFPDXBNJZSQVHLCKE";

export fn is_spain_national_id(input: [*]const i64, length: usize) i64 {
    if (length != 9 and length != 10) return -1;
    for (input[0..length]) |value| {
        if (value < 0 or value > 127) return -1;
    }
    if (length == 10 and input[8] != 45) return -1;
    var number: i64 = 0;
    for (0..8) |index| {
        const value = input[index];
        if (value < 48 or value > 57) return -1;
        number = number * 10 + value - 48;
    }
    var letter = input[length - 1];
    if (letter >= 97 and letter <= 122) letter -= 32;
    if (letter < 65 or letter > 90) return -1;
    return if (letter == @as(i64, CHECK_LETTERS[@intCast(@mod(number, 23))])) 1 else 0;
}
