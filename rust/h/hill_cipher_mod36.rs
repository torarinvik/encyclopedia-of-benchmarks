fn symbol_value(value: i64) -> Option<i32> {
    let value = if (b'a' as i64..=b'z' as i64).contains(&value) { value - (b'a' - b'A') as i64 } else { value };
    if (b'A' as i64..=b'Z' as i64).contains(&value) { Some((value - b'A' as i64) as i32) }
    else if (b'0' as i64..=b'9' as i64).contains(&value) { Some((value - b'0' as i64) as i32 + 26) }
    else { None }
}
fn map_symbol(value: i32) -> u8 { if value < 26 { b'A' + value as u8 } else { b'0' + (value - 26) as u8 } }

#[no_mangle]
pub unsafe extern "C" fn hill_cipher_mod36(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=1).contains(&values[0]) || !(1..=256).contains(&values[1]) || length != values[1] as usize + 2 { return -1; }
    let mut text = [0i32; 256]; let mut count = 0usize;
    for &byte in &values[2..] { if !(0..=127).contains(&byte) { return -1; } if let Some(value)=symbol_value(byte){text[count]=value;count+=1;} }
    if count == 0 { return -1; }
    if count % 2 != 0 { text[count] = text[count-1]; count += 1; }
    if output.is_null() || capacity < count { return -2; }
    let result = std::slice::from_raw_parts_mut(output, count);
    let decrypt = values[0] == 1;
    for i in (0..count).step_by(2) { let (a,b)=(text[i],text[i+1]);
        let first=if decrypt{(6*a+25*b)%36}else{(2*a+5*b)%36};
        let second=if decrypt{(5*a+26*b)%36}else{(a+6*b)%36};
        result[i]=map_symbol(first);result[i+1]=map_symbol(second);
    }
    count as i64
}
