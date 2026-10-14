module levenshtein_distance;

// Unit-cost Levenshtein distance over two ASCII byte sequences.
fn long levenshtein_distance(long* values, usz length) @export("levenshtein_distance")
{
    if (length < 2) return -1;
    long left_length_value = values[0];
    long right_length_value = values[1];
    if (left_length_value < 0 || left_length_value > 255 ||
        right_length_value < 0 || right_length_value > 255) return -1;
    usz left_length = (usz)left_length_value;
    usz right_length = (usz)right_length_value;
    if (length != 2 + left_length + right_length) return -1;
    long* left = values + 2;
    long* right = left + left_length;
    for (usz index = 0; index < left_length; index++) {
        if (left[index] < 0 || left[index] > 127) return -1;
    }
    for (usz index = 0; index < right_length; index++) {
        if (right[index] < 0 || right[index] > 127) return -1;
    }

    long[256] row;
    for (usz column = 0; column <= right_length; column++) row[column] = (long)column;
    for (usz row_index = 1; row_index <= left_length; row_index++) {
        long diagonal = row[0];
        row[0] = (long)row_index;
        for (usz column = 1; column <= right_length; column++) {
            long above = row[column];
            long deletion = above + 1;
            long insertion = row[column - 1] + 1;
            long substitution = diagonal + (left[row_index - 1] == right[column - 1] ? 0 : 1);
            long best = deletion < insertion ? deletion : insertion;
            if (substitution < best) best = substitution;
            row[column] = best;
            diagonal = above;
        }
    }
    return row[right_length];
}
