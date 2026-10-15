module magic_number;

fn long magic_number(long n) @export("magic_number")
{
    return n > 0 && n % 9 == 1 ? 1 : 0;
}
