module lerp;

// Binary64 interpolation in the classic start + t * (end - start) form.
fn double lerp(double start, double end, double t) @export("lerp")
{
    return start + t * (end - start);
}
