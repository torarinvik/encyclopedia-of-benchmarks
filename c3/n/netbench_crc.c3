module netbench_crc;

const usz MAX_LENGTH = 256;
const ulong POLYNOMIAL = 0x04c11db7;

fn long netbench_crc(long* values, usz length) @export("netbench_crc") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -1;
    for (usz index = 0; index < length; index++)
        if (values[index] < 0 || values[index] > 255) return -1;

    ulong[256] table = zeroed;
    for (ulong byte = 0; byte < 256; byte++) {
        ulong remainder = byte << 24;
        for (usz bit = 0; bit < 8; bit++) {
            if ((remainder & 0x80000000) != 0)
                remainder = (remainder << 1) ^ POLYNOMIAL;
            else
                remainder = remainder << 1;
        }
        table[(usz)byte] = remainder;
    }

    ulong crc = 0;
    for (usz index = 0; index < length; index++) {
        ulong byte = (ulong)values[index];
        usz table_index = (usz)(((crc >> 24) ^ byte) & 0xff);
        crc = (crc << 8) ^ table[table_index];
    }
    return (long)(crc & 0xffffffff);
}
