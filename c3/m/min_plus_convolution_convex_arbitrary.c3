module min_plus_convolution_convex_arbitrary;

const int MAX_INPUT = 67;
const usz MAX_OUTPUT = 504;
const usz MAX_N = 32;
const usz MAX_M = 32;

fn void store_i64_le(uint8 *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (uint8)(bits & 255ul); bits >>= 8; }
}

fn long min_plus_convolution_convex_arbitrary(long *input, usz length, uint8 *output, usz capacity)
    @export("min_plus_convolution_convex_arbitrary") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > MAX_N || m0 < 1 || m0 > MAX_M) return -1;
    usz n = (usz)n0, m = (usz)m0;
    if (length != 2 + n + m) return -1;
    long *a = input + 2, *b = input + 2 + n;
    for (usz i = 0; i < n + m; i++) if (input[2+i] < 0 || input[2+i] > 1000000000) return -1;
    for (usz i = 0; i + 2 < n; i++) if (a[i+1]-a[i] > a[i+2]-a[i+1]) return -1;
    usz count = n + m - 1, bytes = 8 * count;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == null || capacity < bytes) return -2;
    long[63] result;
    usz[128][4] stack;
    usz top = 0;
    stack[top][0] = 0; stack[top][1] = count-1; stack[top][2] = 0; stack[top][3] = m-1; top++;
    while (top > 0) {
        top--;
        usz left=stack[top][0], right=stack[top][1], ol=stack[top][2], or=stack[top][3];
        if (left > right) continue;
        usz mid=left+(right-left)/2, low=ol, high=or;
        if (mid > n-1 && low < mid-(n-1)) low=mid-(n-1);
        if (high > m-1) high=m-1;
        if (high > mid) high=mid;
        long best=9223372036854775807l; usz best_j=low;
        for (usz j=low; j<=high; j++) { long candidate=a[mid-j]+b[j]; if (candidate<best) {best=candidate;best_j=j;} }
        result[mid]=best;
        if (mid<right) {stack[top][0]=mid+1;stack[top][1]=right;stack[top][2]=best_j;stack[top][3]=or;top++;}
        if (left<mid) {stack[top][0]=left;stack[top][1]=mid-1;stack[top][2]=ol;stack[top][3]=best_j;top++;}
    }
    for (usz i=0;i<count;i++) store_i64_le(output,8*i,result[i]);
    return (long)bytes;
}
