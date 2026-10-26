#[no_mangle]
pub unsafe extern "C" fn beebs_bit_compress(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 {
        return -1;
    }
    let data_value = unsafe { *values };
    let mask_value = unsafe { *values.add(1) };
    if data_value < 0 || data_value > 4_294_967_295 ||
       mask_value < 0 || mask_value > 4_294_967_295 {
        return -1;
    }
    let mut data = data_value as u32;
    let mut mask = mask_value as u32;
    let mut packed = 0u32;
    let mut output_bit = 1u32;
    while mask != 0 {
        if mask & 1 != 0 {
            if data & 1 != 0 {
                packed |= output_bit;
            }
            output_bit <<= 1;
        }
        data >>= 1;
        mask >>= 1;
    }
    packed as i64
}
