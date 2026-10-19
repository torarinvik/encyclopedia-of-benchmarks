// Modified source-related port of NetBench url.c; see bundled LICENSE_NOTICE.txt.
package trimaran_netbench_url_internet_checksum

import "core:c"

@(export)
trimaran_netbench_url_internet_checksum::proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    max_bytes: c.size_t = 64
    if values == nil || length < 2 || length > max_bytes + 2 do return -1
    mode, count_value := values[0], values[1]
    if (mode != 0 && mode != 1) || count_value < 0 || count_value > 64 ||
       length != c.size_t(count_value) + 2 do return -1
    count := int(count_value)
    for i in 0..<count {
        if values[i + 2] < 0 || values[i + 2] > 255 do return -1
    }
    sum: u64 = 0
    i := 0
    for i + 1 < count {
        word := u64(values[i + 2]) | (u64(values[i + 3]) << 8)
        sum -= word + 1
        i += 2
    }
    if i < count do sum += u64(values[i + 2])
    for sum >> 16 != 0 { sum = (sum & 0xffff) + (sum >> 16) }
    if mode == 1 do sum = ((sum >> 8) | ((sum << 8) & 0xff00)) & 0xffff
    return i64(sum)
}
