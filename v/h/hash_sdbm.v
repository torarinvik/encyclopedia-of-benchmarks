module hash_sdbm

const max_bytes = 64
const high_bit = u64(1) << 63

fn hash_sdbm_signed_bits(value u64) i64 {
    if value < high_bit { return i64(value) }
    return i64(-9223372036854775807 - 1) + i64(value - high_bit)
}

@[export: 'hash_sdbm']
pub fn hash_sdbm(input &i64, length usize) i64 {
    if length == 0 || length > max_bytes { return -1 }
    unsafe {
        mut hash := u64(0)
        for index in 0 .. int(length) {
            byte := input[index]
            if byte < 1 || byte > 127 { return -1 }
            value := u64(byte)
            hash = value + (hash << 6) + (hash << 16) - hash
        }
        return hash_sdbm_signed_bits(hash)
    }
}
