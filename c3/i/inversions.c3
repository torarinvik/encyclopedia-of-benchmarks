module inversions;
fn long inversions(long* values, usz length) @export("inversions") {
    if (length > 1024 || (length != 0 && values == null)) return -1;
    for (usz i=0;i<length;i++) if (values[i] < -2147483648L || values[i] > 2147483647L) return -1;
    long count = 0;
    for (usz i=0;i<length;i++) for (usz j=i+1;j<length;j++) if(values[i]>values[j]) count++;
    return count;
}
