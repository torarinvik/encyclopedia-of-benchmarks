module tetrahedral_sequence;

const long MAX_INDEX = 3810777L;

fn long tetrahedral_sequence(long index) @export("tetrahedral_sequence") {
    if (index < 0 || index > MAX_INDEX) return -1;
    long a = index;
    long b = index + 1;
    long c = index + 2;
    if (a % 2 == 0) a /= 2;
    else if (b % 2 == 0) b /= 2;
    else c /= 2;
    if (a % 3 == 0) a /= 3;
    else if (b % 3 == 0) b /= 3;
    else c /= 3;
    return a * b * c;
}
