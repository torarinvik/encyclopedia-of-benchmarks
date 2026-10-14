module phone_letter_combinations;

fn usz letter_count(long digit)
{
    return digit == 7 || digit == 9 ? 4 : 3;
}

fn char letter_base(long digit)
{
    if (digit == 2) return 'a';
    if (digit == 3) return 'd';
    if (digit == 4) return 'g';
    if (digit == 5) return 'j';
    if (digit == 6) return 'm';
    if (digit == 7) return 'p';
    if (digit == 8) return 't';
    return 'w';
}

fn void expand(long* digits, usz length, usz index, char* output,
               usz output_offset, usz combination_count)
{
    if (index == length) return;
    usz alternatives = letter_count(digits[index]);
    usz block_count = combination_count / alternatives;
    char base = letter_base(digits[index]);
    for (usz letter = 0; letter < alternatives; letter++) {
        usz branch_offset = output_offset + letter * block_count * length;
        for (usz row = 0; row < block_count; row++) {
            output[branch_offset + row * length + index] = (char)(base + (char)letter);
        }
        expand(digits, length, index + 1, output, branch_offset, block_count);
    }
}

// Output is the lexicographic product concatenated as fixed-width digit strings.
fn long letter_combinations_of_phone_number(long* digits, usz length,
                                             char* output, usz output_capacity)
    @export("letter_combinations_of_phone_number")
{
    if (length == 0) return 0;
    if (length > 6 || digits == null) return -1;
    usz count = 1;
    for (usz index = 0; index < length; index++) {
        if (digits[index] < 2 || digits[index] > 9) return -1;
        count *= letter_count(digits[index]);
    }
    usz required = count * length;
    if (output_capacity < required || output == null) return -2;
    expand(digits, length, 0, output, 0, count);
    return (long)count;
}
