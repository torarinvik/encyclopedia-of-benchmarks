// Modified source-related port of NetBench url.c; see bundled LICENSE_NOTICE.txt.
module trimaran_netbench_url_internet_checksum;

fn long trimaran_netbench_url_internet_checksum(long* values, usz length) @export("trimaran_netbench_url_internet_checksum") {
    const usz MAX_BYTES = 64;
    if (values == null || length < 2 || length > MAX_BYTES + 2) return -1;
    long mode = values[0], count_value = values[1];
    if ((mode != 0 && mode != 1) || count_value < 0 || count_value > 64 ||
        length != (usz)count_value + 2) return -1;
    usz count = (usz)count_value;
    for (usz i = 0; i < count; i++)
        if (values[i + 2] < 0 || values[i + 2] > 255) return -1;
    ulong sum = 0;
    usz i = 0;
    for (; i + 1 < count; i += 2) {
        ulong word = (ulong)values[i + 2] | ((ulong)values[i + 3] << 8);
        sum -= word + 1;
    }
    if (i < count) sum += (ulong)values[i + 2];
    while ((sum >> 16) != 0) sum = (sum & 0xffff) + (sum >> 16);
    if (mode == 1) sum = ((sum >> 8) | ((sum << 8) & 0xff00)) & 0xffff;
    return (long)sum;
}
