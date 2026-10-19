module mccat_qbsort;
const usz MAX_ITEMS = 32;
fn void bubble(int* a, usz n) {
    usz end = n;
    while (end > 1) { end--; usz i = 0; while (i + 1 < end) { if (a[i + 1] < a[i]) { int t = a[i]; a[i] = a[i + 1]; a[i + 1] = t; } i++; } }
}
fn void quick(int* a, usz n) {
    if (n < 2) { return; }
    int pivot = a[0]; int[32] lower = {0}, upper = {0}; usz nl = 0, nu = 0;
    for (usz i = 1; i < n; i++) { if (a[i] < pivot) { lower[nl++] = a[i]; } else { upper[nu++] = a[i]; } }
    quick(&upper[0], nu); quick(&lower[0], nl); usz k = 0;
    for (usz i = 0; i < nl; i++) { a[k++] = lower[i]; } a[k++] = pivot;
    for (usz i = 0; i < nu; i++) { a[k++] = upper[i]; }
}
fn void put_le(uint8* out, usz i, int value) { uint32 bits = (uint32)value; for (usz b = 0; b < 4; b++) { out[4 * i + b] = (uint8)(bits >> (8 * b)); } }
fn long mccat_qbsort(long* input, usz length, uint8* output, usz capacity) @export("mccat_qbsort") {
    if (input == null || length < 3 || length > 34) { return -1; }
    long mode = input[0], cv = input[1]; if ((mode != 0 && mode != 1) || cv < 1 || cv > 32) { return -1; }
    usz n = (usz)cv; if (length != n + 2) { return -1; }
    int[32] values = {0}; for (usz i = 0; i < n; i++) { if (input[i + 2] < -2147483648 || input[i + 2] > 2147483647) { return -1; } values[i] = (int)input[i + 2]; }
    for (usz pass = 0; pass < 1000; pass++) { for (usz i = 0; i < n; i++) { values[i] = (int)input[i + 2]; } if (mode == 0) { bubble(&values[0], n); } else { quick(&values[0], n); } }
    usz need = n * 4; if (output == null || capacity < need) { return -2; }
    for (usz i = 0; i < n; i++) { put_le(output, i, values[i]); } return (long)need;
}
