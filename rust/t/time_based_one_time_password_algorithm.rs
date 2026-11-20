const MAX_KEY: usize = 64;
const MAX_WORDS: usize = 67;
const OUT_BYTES: usize = 6;

fn rol(x: u32, n: u32) -> u32 { x.rotate_left(n) }

fn compress(h: &mut [u32; 5], block: &[u8; 64]) {
    let mut w = [0u32; 80];
    for i in 0..16 { let j=4*i; w[i]=u32::from_be_bytes([block[j],block[j+1],block[j+2],block[j+3]]); }
    for i in 16..80 { w[i]=rol(w[i-3]^w[i-8]^w[i-14]^w[i-16],1); }
    let (mut a,mut b,mut c,mut d,mut e)=(h[0],h[1],h[2],h[3],h[4]);
    for (i,word) in w.iter().enumerate() {
        let (f,k)=if i<20 {((b&c)|(!b&d),0x5a827999)} else if i<40 {(b^c^d,0x6ed9eba1)} else if i<60 {((b&c)|(b&d)|(c&d),0x8f1bbcdc)} else {(b^c^d,0xca62c1d6)};
        let t=rol(a,5).wrapping_add(f).wrapping_add(e).wrapping_add(k).wrapping_add(*word);
        e=d;d=c;c=rol(b,30);b=a;a=t;
    }
    h[0]=h[0].wrapping_add(a);h[1]=h[1].wrapping_add(b);h[2]=h[2].wrapping_add(c);h[3]=h[3].wrapping_add(d);h[4]=h[4].wrapping_add(e);
}

fn initial() -> [u32;5] { [0x67452301,0xefcdab89,0x98badcfe,0x10325476,0xc3d2e1f0] }
fn serialize(h: &[u32;5], out: &mut [u8;20]) { for i in 0..5 { out[4*i..4*i+4].copy_from_slice(&h[i].to_be_bytes()); } }

fn compute(input: &[i64], key_len: usize) -> [u8;6] {
    let mut key=[0u8;64]; for i in 0..key_len { key[i]=input[i+1] as u8; }
    let mut block=[0u8;64]; for i in 0..64 { block[i]=key[i]^0x36; }
    let mut h=initial();compress(&mut h,&block);block.fill(0);
    let counter=(input[key_len+1] as u64)/30;
    block[..8].copy_from_slice(&counter.to_be_bytes());block[8]=0x80;block[62]=0x02;block[63]=0x40;
    compress(&mut h,&block);let mut inner=[0u8;20];serialize(&h,&mut inner);
    for i in 0..64 { block[i]=key[i]^0x5c; }h=initial();compress(&mut h,&block);block.fill(0);block[..20].copy_from_slice(&inner);
    block[20]=0x80;block[62]=0x02;block[63]=0xa0;compress(&mut h,&block);serialize(&h,&mut inner);
    let off=(inner[19]&15) as usize;let word=u32::from_be_bytes([inner[off],inner[off+1],inner[off+2],inner[off+3]])&0x7fffffff;
    let mut value=word%1_000_000;let mut out=[0u8;6];for i in (0..6).rev(){out[i]=b'0'+(value%10) as u8;value/=10;}out
}

#[no_mangle]
pub unsafe extern "C" fn time_based_one_time_password_algorithm(input_ptr:*const i64,length:usize,output_ptr:*mut u8,capacity:usize)->i64{
    if input_ptr.is_null()||!(3..=MAX_WORDS).contains(&length){return -1;}let input=unsafe{std::slice::from_raw_parts(input_ptr,length)};
    let kw=input[0];if kw<16||kw>MAX_KEY as i64||length!=kw as usize+2{return -1;}let n=kw as usize;
    if input[1..=n].iter().any(|&x|!(0..=255).contains(&x))||input[n+1]<0{return -1;}
    let staged=compute(input,n);if output_ptr.is_null()||capacity<OUT_BYTES{return -2;}unsafe{std::ptr::copy_nonoverlapping(staged.as_ptr(),output_ptr,OUT_BYTES);}OUT_BYTES as i64
}
