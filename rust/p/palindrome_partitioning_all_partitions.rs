const MAX_LENGTH: usize = 12;
const OUT_CAP: usize = 16000;
struct Context<'a> { text: &'a [i64], ends: [usize;MAX_LENGTH], packed: [i64;OUT_CAP], used: usize, partitions: usize }
fn is_palindrome(ctx:&Context<'_>,start:usize,end:usize)->bool{let(mut left,mut right)=(start,end);while left<right{if ctx.text[left]!=ctx.text[right-1]{return false;}left+=1;right-=1;}true}
fn enumerate(ctx:&mut Context<'_>,start:usize,depth:usize){if start==ctx.text.len(){ctx.partitions+=1;ctx.packed[ctx.used]=depth as i64;ctx.used+=1;for i in 0..depth{ctx.packed[ctx.used]=ctx.ends[i] as i64;ctx.used+=1;}return;}for end in start+1..=ctx.text.len(){if is_palindrome(ctx,start,end){ctx.ends[depth]=end;enumerate(ctx,end,depth+1);}}}

#[no_mangle]
pub unsafe extern "C" fn palindrome_partitioning_all_partitions(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<1{return -1;}
    let values=std::slice::from_raw_parts(input,length);
    if !(0..=MAX_LENGTH as i64).contains(&values[0])||length!=values[0] as usize+1{return -1;}
    let n=values[0] as usize;let text=&values[1..];if text.iter().any(|&x|!(0..=127).contains(&x)){return -1;}
    let mut ctx=Context{text,ends:[0;MAX_LENGTH],packed:[0;OUT_CAP],used:1,partitions:0};enumerate(&mut ctx,0,0);ctx.packed[0]=ctx.partitions as i64;
    let required=ctx.used*8;if output.is_null()||capacity<required{return -2;}
    for (i,&value) in ctx.packed[..ctx.used].iter().enumerate(){for byte in 0..8{*output.add(i*8+byte)=(value as u64>>(byte*8))as u8;}}
    required as i64
}
