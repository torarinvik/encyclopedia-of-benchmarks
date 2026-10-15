const MAX_INPUT: usize = 4096;
const MAX_PADDED: usize = 4160;

fn rol(value: u32, shift: u32) -> u32 { value.rotate_left(shift) }

#[no_mangle]
pub unsafe extern "C" fn sha1(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if length > MAX_INPUT || (length > 0 && input.is_null()) { return -1; }
    let values = if length == 0 { &[][..] } else { std::slice::from_raw_parts(input, length) };
    if values.iter().any(|&value| !(0..=255).contains(&value)) { return -1; }
    let mut padded = [0_u8; MAX_PADDED];
    for (i, &value) in values.iter().enumerate() { padded[i] = value as u8; }
    padded[length] = 0x80;
    let blocks = (length + 9 + 63) / 64;
    let padded_length = blocks * 64;
    let bit_length = (length as u64) * 8;
    padded[padded_length - 8..padded_length].copy_from_slice(&bit_length.to_be_bytes());
    let (mut h0,mut h1,mut h2,mut h3,mut h4)=(0x67452301_u32,0xEFCDAB89,0x98BADCFE,0x10325476,0xC3D2E1F0);
    for block in 0..blocks {
        let mut w=[0_u32;80];
        for i in 0..16 { let p=block*64+i*4;w[i]=u32::from_be_bytes([padded[p],padded[p+1],padded[p+2],padded[p+3]]); }
        for i in 16..80 { w[i]=rol(w[i-3]^w[i-8]^w[i-14]^w[i-16],1); }
        let (mut a,mut b,mut c,mut d,mut e)=(h0,h1,h2,h3,h4);
        for i in 0..80 {
            let (f,k)=if i<20 {((b&c)|(!b&d),0x5A827999)} else if i<40 {(b^c^d,0x6ED9EBA1)} else if i<60 {((b&c)|(b&d)|(c&d),0x8F1BBCDC)} else {(b^c^d,0xCA62C1D6)};
            let temp=rol(a,5).wrapping_add(f).wrapping_add(e).wrapping_add(k).wrapping_add(w[i]);
            e=d;d=c;c=rol(b,30);b=a;a=temp;
        }
        h0=h0.wrapping_add(a);h1=h1.wrapping_add(b);h2=h2.wrapping_add(c);h3=h3.wrapping_add(d);h4=h4.wrapping_add(e);
    }
    if output.is_null() || capacity < 20 { return -2; }
    let digest=[h0,h1,h2,h3,h4];
    for (i,word) in digest.iter().enumerate() { std::ptr::copy_nonoverlapping(word.to_be_bytes().as_ptr(),output.add(i*4),4); }
    20
}
