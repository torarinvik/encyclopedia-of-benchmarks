// Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
// Apache-2.0 licensed upstream kernel, bounded variant; modifications made.
const MAX_TEXT: usize = 96;

fn scan_text(text: &[u8], finals: &mut [u32; 8], transitions: &mut [u32; 8]) {
    let mut pos = 0usize;
    while pos < text.len() {
        let mut state = 0usize;
        while pos < text.len() && state != 1 {
            let ch = text[pos];
            if ch == b',' { pos += 1; break; }
            let digit = ch >= b'0' && ch <= b'9';
            match state {
                0 => { if digit {state=4} else if ch==b'+'||ch==b'-' {state=2} else if ch==b'.' {state=5} else {state=1;transitions[1]+=1} transitions[0]+=1; }
                2 => { if digit {state=4} else if ch==b'.' {state=5} else {state=1} transitions[2]+=1; }
                4 => { if ch==b'.' {state=5;transitions[4]+=1} else if !digit {state=1;transitions[4]+=1} }
                5 => { if ch==b'e'||ch==b'E' {state=3;transitions[5]+=1} else if !digit {state=1;transitions[5]+=1} }
                3 => { if ch==b'+'||ch==b'-' {state=6} else {state=1} transitions[3]+=1; }
                6 => { if digit {state=7} else {state=1} transitions[6]+=1; }
                7 => { if !digit {state=1;transitions[1]+=1} }
                _ => {}
            }
            pos += 1;
        }
        finals[state] += 1;
    }
}

#[no_mangle]
pub unsafe extern "C" fn numeric_token_state_machine(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_TEXT + 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let raw_n=values[0]; let step=values[1]; let seed=values[2];
    if raw_n<1 || raw_n>MAX_TEXT as i64 || length!=raw_n as usize+3 || step<1 || step>16 || seed<1 || seed>255 {return -1;}
    let n=raw_n as usize;
    let mut text=[0u8;MAX_TEXT];
    for i in 0..n {if values[3+i]<32||values[3+i]>126{return -1;} text[i]=values[3+i] as u8;}
    if text[0]==b','||text[n-1]==b',' {return -1;}
    for i in 1..n {if text[i]==b','&&text[i-1]==b',' {return -1;}}
    for i in (0..n).step_by(step as usize) {if text[i]!=b','&&((text[i]^(seed as u8))==b','||(text[i]^(seed as u8))==0) {return -1;}}
    let mut finals=[0u32;8]; let mut transitions=[0u32;8];
    scan_text(&text[..n],&mut finals,&mut transitions);
    for i in (0..n).step_by(step as usize) {if text[i]!=b',' {text[i]^=seed as u8;}}
    scan_text(&text[..n],&mut finals,&mut transitions);
    for i in (0..n).step_by(step as usize) {if text[i]!=b',' {text[i]^=seed as u8;}}
    if output.is_null()||capacity<64{return -2;}
    for i in 0..8 {for b in 0..4 { *output.add(i*8+b)=((finals[i]>>(8*b))&255) as u8; *output.add(i*8+4+b)=((transitions[i]>>(8*b))&255) as u8;}}
    64
}
