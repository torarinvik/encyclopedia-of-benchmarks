fn popcount(mut value: u32) -> u32 { let mut count=0; while value!=0 { count+=value&1; value>>=1; } count }
fn put_i64_le(output:&mut [u8],offset:usize,value:i64){ output[offset..offset+8].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn association(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<2{return -1;}
    let values=std::slice::from_raw_parts(input,length);
    let (transactions64,items64)=(values[0],values[1]);
    if !(1..=64).contains(&transactions64)||!(1..=11).contains(&items64){return -1;}
    let (transactions,items)=(transactions64 as usize,items64 as u32);
    if length!=2+transactions{return -1;}
    let limit=1u32<<items; let valid_bits=(limit-1) as i64;
    if values[2..].iter().any(|&row|row<0||row>valid_bits){return -1;}
    let mut frequent=[false;2048]; let mut masks=[0i64;2047]; let mut supports=[0i64;2047]; let mut count=0usize;
    for size in 1..=items { for mask in 1..limit {
        if popcount(mask)!=size {continue;}
        if size>1 { let mut ok=true; for bit in 0..items { if mask&(1<<bit)!=0&&!frequent[(mask^(1<<bit)) as usize]{ok=false;} } if !ok{continue;} }
        let support=values[2..].iter().filter(|&&row|(row as u32&mask)==mask).count() as i64;
        if support>0 { frequent[mask as usize]=true; masks[count]=mask as i64; supports[count]=support; count+=1; }
    }}
    let required=count*16; if capacity<required||(required>0&&output.is_null()){return -2;}
    if required==0{return 0;}
    let bytes=std::slice::from_raw_parts_mut(output,required);
    for i in 0..count { put_i64_le(bytes,i*16,masks[i]); put_i64_le(bytes,i*16+8,supports[i]); }
    required as i64
}
