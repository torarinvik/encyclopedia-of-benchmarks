module max_number_of_balloons;

// Count how many copies of balloon the text can supply.
fn long max_number_of_balloons(long* text, usz length) @export("max_number_of_balloons")
{
    if (length > 256) return -1;
    long b = 0;
    long a = 0;
    long l = 0;
    long o = 0;
    long n = 0;
    for (usz index = 0; index < length; index++) {
        long value = text[index];
        if (value < 97 || value > 122) return -1;
        if (value == 98) { b++; }
        else if (value == 97) { a++; }
        else if (value == 108) { l++; }
        else if (value == 111) { o++; }
        else if (value == 110) { n++; }
    }
    l /= 2;
    o /= 2;
    long minimum = b;
    if (a < minimum) minimum = a;
    if (l < minimum) minimum = l;
    if (o < minimum) minimum = o;
    if (n < minimum) minimum = n;
    return minimum;
}
