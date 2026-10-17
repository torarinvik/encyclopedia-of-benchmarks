const MAX_INPUT: usize = 4096;
const MAX_PADDED: usize = 4160;
const K: [u32;64] = [
0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2];

#[no_mangle]
unsafe fn proof_of_work_hash(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if length>MAX_INPUT||(length>0&&input.is_null()){return -1;}
    let values=if length==0{&[][..]}else{std::slice::from_raw_parts(input,length)};
    if values.iter().any(|&v|!(0..=255).contains(&v)){return -1;}
    let mut padded=[0_u8;MAX_PADDED];for(i,&v)in values.iter().enumerate(){padded[i]=v as u8;}padded[length]=0x80;
    let blocks=(length+9+63)/64;let padded_length=blocks*64;let bit_length=(length as u64)*8;
    padded[padded_length-8..padded_length].copy_from_slice(&bit_length.to_be_bytes());
    let mut h=[0x6a09e667_u32,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19];
    for block in 0..blocks{
        let mut w=[0_u32;64];
        for i in 0..16{let p=block*64+i*4;w[i]=u32::from_be_bytes([padded[p],padded[p+1],padded[p+2],padded[p+3]]);}
        for i in 16..64{let x=w[i-15];let y=w[i-2];let s0=x.rotate_right(7)^x.rotate_right(18)^(x>>3);let s1=y.rotate_right(17)^y.rotate_right(19)^(y>>10);w[i]=s1.wrapping_add(w[i-7]).wrapping_add(s0).wrapping_add(w[i-16]);}
        let(mut a,mut b,mut c,mut d,mut e,mut f,mut g,mut hh)=(h[0],h[1],h[2],h[3],h[4],h[5],h[6],h[7]);
        for i in 0..64{let s1=e.rotate_right(6)^e.rotate_right(11)^e.rotate_right(25);let ch=(e&f)^(!e&g);let t1=hh.wrapping_add(s1).wrapping_add(ch).wrapping_add(K[i]).wrapping_add(w[i]);let s0=a.rotate_right(2)^a.rotate_right(13)^a.rotate_right(22);let maj=(a&b)^(a&c)^(b&c);let t2=s0.wrapping_add(maj);hh=g;g=f;f=e;e=d.wrapping_add(t1);d=c;c=b;b=a;a=t1.wrapping_add(t2);}
        h[0]=h[0].wrapping_add(a);h[1]=h[1].wrapping_add(b);h[2]=h[2].wrapping_add(c);h[3]=h[3].wrapping_add(d);h[4]=h[4].wrapping_add(e);h[5]=h[5].wrapping_add(f);h[6]=h[6].wrapping_add(g);h[7]=h[7].wrapping_add(hh);
    }
    if output.is_null()||capacity<32{return -2;}
    for(i,word)in h.iter().enumerate(){std::ptr::copy_nonoverlapping(word.to_be_bytes().as_ptr(),output.add(i*4),4);}
    32
}


const HEADER:usize=5;const MAX_VALUES:usize=134;
fn append_decimal(out:&mut [i64;151],mut p:usize,mut v:u64)->usize{let mut d=[0u8;20];let mut n=0;loop{d[n]=b'0'+(v%10)as u8;n+=1;v/=10;if v==0{break}}while n>0{n-=1;out[p]=d[n]as i64;p+=1}p}
fn zero_prefix(d:&[u8;32],difficulty:i64)->bool{for i in 0..difficulty as usize{let b=d[i/2];if(if i%2==0{b>>4}else{b&15})!=0{return false}}true}
#[no_mangle]
pub unsafe extern "C" fn simple_proof_of_work(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<HEADER||length>MAX_VALUES{return -1}let v=std::slice::from_raw_parts(input,length);let(block,diff,maxn,tl,pl)=(v[0],v[1],v[2],v[3],v[4]);if block<0||!(0..=2).contains(&diff)||!(0..=4096).contains(&maxn)||!(0..=64).contains(&tl)||!(0..=64).contains(&pl){return -1}if length!=HEADER+tl as usize+pl as usize{return -1}let tx=&v[HEADER..HEADER+tl as usize];let prev=&v[HEADER+tl as usize..];if tx.iter().chain(prev).any(|&x|!(0..=127).contains(&x)){return -1}if output.is_null()||capacity<72{return -2}const HEX:&[u8;16]=b"0123456789abcdef";
 for nonce in 0..=maxn as u64{let mut m=[0i64;151];let mut n=append_decimal(&mut m,0,block as u64);for &x in tx{m[n]=x;n+=1}for &x in prev{m[n]=x;n+=1}n=append_decimal(&mut m,n,nonce);let mut d=[0u8;32];if proof_of_work_hash(m.as_ptr(),n,d.as_mut_ptr(),32)!=32{return -1}if zero_prefix(&d,diff){for i in 0..8{*output.add(i)=(nonce>>(8*i))as u8}for i in 0..32{*output.add(8+2*i)=HEX[(d[i]>>4)as usize];*output.add(9+2*i)=HEX[(d[i]&15)as usize]}return 72}}-3
}
