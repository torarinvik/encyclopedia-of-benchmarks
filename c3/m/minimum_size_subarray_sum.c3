module minimum_size_subarray_sum;

fn long minimum_size_subarray_sum(long* packed, usz length) @export("minimum_size_subarray_sum")
{
    if (length < 2) return -1;
    long target = packed[0];
    long count = packed[1];
    if (target < 1 || target > 1000000 || count < 0 || count > 256
        || length != (usz)count + 2) return -1;
    for (long index = 0; index < count; index++) {
        if (packed[index + 2] < 1 || packed[index + 2] > 1000000) return -1;
    }
    long left = 0;
    long sum = 0;
    long best = count + 1;
    for (long right = 0; right < count; right++) {
        sum += packed[right + 2];
        while (sum >= target) {
            long width = right - left + 1;
            if (width < best) best = width;
            sum -= packed[left + 2];
            left++;
        }
    }
    return best <= count ? best : 0;
}
