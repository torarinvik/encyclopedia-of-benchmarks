module leonardo_number;

// Iteratively compute L(0)=L(1)=1 and L(n)=L(n-1)+L(n-2)+1.
fn long leonardo_number(long input) @export("leonardo_number")
{
    if (input < 0 || input > 89) return -1;
    long previous = 1;
    long current = 1;
    long index = 2;
    while (index <= input) {
        long next = current + previous + 1;
        previous = current;
        current = next;
        index++;
    }
    return current;
}
