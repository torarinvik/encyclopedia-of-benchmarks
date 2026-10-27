const MAX_N: usize = 32;
const MAX_INPUT: usize = 35;
const MAX_OUTPUT: usize = 4096;
const MAX_RESULT: usize = 512;

fn emit_bit(out: &mut [u8; MAX_OUTPUT], used: &mut usize, value: bool) {
    out[*used] = if value { b'1' } else { b'0' };
    *used += 1;
}
fn emit_byte(out: &mut [u8; MAX_OUTPUT], used: &mut usize, value: u8) { out[*used] = value; *used += 1; }
fn emit_number(out: &mut [u8; MAX_OUTPUT], used: &mut usize, value: u64, width: i32) {
    for shift in (0..width).rev() { emit_bit(out, used, ((value >> shift) & 1) != 0); }
}
fn emit_unary(out: &mut [u8; MAX_OUTPUT], used: &mut usize, value: u64) {
    for _ in 0..value { emit_bit(out, used, true); }
    emit_bit(out, used, false);
}
fn floor_log2(value: u64) -> i32 { 63 - value.leading_zeros() as i32 }
fn emit_minimal(out: &mut [u8; MAX_OUTPUT], used: &mut usize, value: u64, universe: u64) {
    if universe == 1 { return; }
    let low_width = floor_log2(universe);
    let short_count = (1u64 << (low_width + 1)) - universe;
    if value < short_count { emit_number(out, used, value, low_width); }
    else { emit_number(out, used, value + short_count, low_width + 1); }
}
fn emit_gamma(out: &mut [u8; MAX_OUTPUT], used: &mut usize, value: u64) {
    let shifted = value + 1;
    let width = floor_log2(shifted);
    emit_unary(out, used, width as u64);
    emit_number(out, used, shifted - (1u64 << width), width);
}
fn emit_delta(out: &mut [u8; MAX_OUTPUT], used: &mut usize, value: u64) {
    let shifted = value + 1;
    let width = floor_log2(shifted);
    emit_gamma(out, used, width as u64);
    emit_number(out, used, shifted - (1u64 << width), width);
}
fn emit_interpolative(out: &mut [u8; MAX_OUTPUT], used: &mut usize, values: &[i64],
                      left: usize, right: usize, low: i64, high: i64) {
    if left >= right { return; }
    let middle = left + (right - left - 1) / 2;
    let value = values[middle];
    let lower = low + (middle - left) as i64;
    let upper = high - (right - middle - 1) as i64;
    emit_minimal(out, used, (value - lower) as u64, (upper - lower) as u64);
    emit_interpolative(out, used, values, left, middle, low, value);
    emit_interpolative(out, used, values, middle + 1, right, value + 1, high);
}
fn emit_simple9(out: &mut [u8; MAX_OUTPUT], used: &mut usize, values: &[i64]) {
    const SLOTS: [usize; 9] = [28,14,9,7,5,4,3,2,1];
    const WIDTHS: [u32; 9] = [1,2,3,4,5,7,9,14,28];
    let mut position=0;
    while position < values.len() {
        let mut chosen=0usize;
        let mut take=0usize;
        for selector in 0..9 {
            let count=SLOTS[selector].min(values.len()-position);
            if values[position..position+count].iter().all(|&x| (x as u64) < (1u64<<WIDTHS[selector])) {
                chosen=selector;take=count;break;
            }
        }
        let width=WIDTHS[chosen] as usize;
        let mut word=(chosen as u64)<<28;
        for j in 0..take {
            let shift=28-width*(j+1);
            word|=(values[position+j] as u64)<<shift;
        }
        emit_number(out,used,word,32);
        position+=take;
    }
}

#[no_mangle]
pub unsafe extern "C" fn integer_sequence_codes(input: *const i64, length: usize,
                                                   output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let mode = words[0];
    let n0 = words[1];
    let parameter = words[2];
    if !(0..=9).contains(&mode) || !(1..=MAX_N as i64).contains(&n0) || length != n0 as usize + 3 { return -1; }
    let n = n0 as usize;
    let values = &words[3..];
    if mode == 0 {
        if parameter != 0 || values.iter().any(|&x| !(0..=31).contains(&x)) { return -1; }
    } else if mode == 1 {
        if !(2..=1_000_000).contains(&parameter) || values.iter().any(|&x| x < 0 || x >= parameter) { return -1; }
    } else if mode == 2 || mode == 3 {
        if parameter != 0 || values.iter().any(|&x| !(0..=1_000_000).contains(&x)) { return -1; }
    } else if mode == 4 {
        if !(1..=128).contains(&parameter) || values.iter().any(|&x| !(0..=127).contains(&x)) { return -1; }
    } else if mode == 7 {
        if parameter != 0 || values.iter().any(|&x| !(0..=1_000_000).contains(&x)) { return -1; }
    } else if mode == 8 {
        if parameter != 0 || values.iter().any(|&x| x < 0 || x >= (1i64<<28)) { return -1; }
    } else if mode == 9 {
        if !(1..=20).contains(&parameter) || values.iter().any(|&x| !(0..=1_000_000).contains(&x)) { return -1; }
    } else {
        if !(2..=4096).contains(&parameter) || n as i64 > parameter
            || values.iter().any(|&x| x < 0 || x >= parameter)
            || values.windows(2).any(|pair| pair[0] >= pair[1]) { return -1; }
    }
    let mut staged = [0u8; MAX_OUTPUT];
    let mut used = 0usize;
    match mode {
        0 => for &value in values { emit_unary(&mut staged, &mut used, value as u64); },
        1 => for &value in values { emit_minimal(&mut staged, &mut used, value as u64, parameter as u64); },
        2 => for &value in values { emit_gamma(&mut staged, &mut used, value as u64); },
        3 => for &value in values { emit_delta(&mut staged, &mut used, value as u64); },
        4 => for &value in values {
            let b = parameter as u64;
            emit_unary(&mut staged, &mut used, value as u64 / b);
            emit_minimal(&mut staged, &mut used, value as u64 % b, b);
        },
        5 => {
            let mut width = 0usize;
            while n as u64 * (1u64 << (width + 1)) <= parameter as u64 { width += 1; }
            let bucket_size = 1u64 << width;
            let buckets = (parameter as u64 + bucket_size - 1) / bucket_size;
            let mut counts = [0u8; 4096];
            for &value in values { counts[value as usize / bucket_size as usize] += 1; }
            for bucket in 0..buckets as usize { emit_unary(&mut staged, &mut used, counts[bucket] as u64); }
            for &value in values { emit_number(&mut staged, &mut used, value as u64 % bucket_size, width as i32); }
        },
        6 => emit_interpolative(&mut staged, &mut used, values, 0, n, 0, parameter),
        7 => for &value in values {
            let x=value as u64;
            let mut highest=floor_log2(x);
            if highest<0 {highest=0;} else {highest=(highest/7)*7;}
            let mut shift=highest;
            while shift>=0 {let mut byte=((x>>shift)&0x7f) as u8;if shift!=0{byte|=0x80;}emit_byte(&mut staged,&mut used,byte);shift-=7;}
        },
        8 => emit_simple9(&mut staged,&mut used,values),
        _ => {
            let width=parameter as u32;
            let mask=(1u64<<width)-1;
            let mut exception_count=0u64;
            for &value in values {let x=value as u64;emit_number(&mut staged,&mut used,x&mask,width as i32);if x >= (1u64<<width){exception_count+=1;}}
            emit_number(&mut staged,&mut used,exception_count,6);
            let position_width=if n<=1 {0} else {usize::BITS as usize-(n-1).leading_zeros() as usize};
            for (position,&value) in values.iter().enumerate(){let x=value as u64;if x >= (1u64<<width){emit_number(&mut staged,&mut used,position as u64,position_width as i32);emit_number(&mut staged,&mut used,x,20);}}
        },
    }
    if output.is_null() { return -2; }
    if mode==7 {if capacity<used{return -2;}std::ptr::copy_nonoverlapping(staged.as_ptr(),output,used);return used as i64;}
    let bytes=(used+7)/8;if capacity<bytes{return -2;}let mut packed=[0u8;MAX_RESULT];
    for i in 0..used{if staged[i]==b'1'{packed[i/8]|=1<<(7-i%8);}}
    std::ptr::copy_nonoverlapping(packed.as_ptr(),output,bytes);bytes as i64
}
