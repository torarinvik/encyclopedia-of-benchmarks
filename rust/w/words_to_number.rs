const MAX_INPUT: usize = 128;
const MAX_TOKENS: usize = 128;
const MAX_FRACTION_WORDS: usize = 3;
const WORDS: [&[u8]; 36] = [
    b"zero", b"one", b"two", b"three", b"four", b"five", b"six", b"seven", b"eight", b"nine",
    b"ten", b"eleven", b"twelve", b"thirteen", b"fourteen", b"fifteen", b"sixteen", b"seventeen", b"eighteen", b"nineteen",
    b"twenty", b"thirty", b"forty", b"fifty", b"sixty", b"seventy", b"eighty", b"ninety", b"hundred", b"thousand",
    b"million", b"billion", b"trillion", b"and", b"point", b"negative",
];
fn word_id(input: *const i64, start: usize, end: usize) -> i32 {
    for (index, word) in WORDS.iter().enumerate() {
        if word.len() != end - start { continue; }
        let mut matched = true;
        for (offset, &expected) in word.iter().enumerate() {
            let mut ch = unsafe { *input.add(1 + start + offset) } as u8;
            if ch.is_ascii_uppercase() { ch += 32; }
            if ch != expected { matched = false; break; }
        }
        if matched { return index as i32 + 1; }
    }
    0
}
fn number_value(id: i32) -> i64 {
    if (1..=20).contains(&id) { return (id - 1) as i64; }
    if (21..=28).contains(&id) { return ((id - 19) * 10) as i64; }
    -1
}
fn digits10(mut value: i64) -> i32 { let mut digits=1; while value>=10 { value/=10; digits+=1; } digits }
fn append_uint(out: &mut Vec<u8>, mut value: i64) { let mut reversed=[0u8;24];let mut used=0;loop{reversed[used]=b'0'+(value%10) as u8;used+=1;value/=10;if value==0{break;}}while used>0{used-=1;out.push(reversed[used]);} }
fn is_separator(value:i64)->bool { value==32||value==44||value==45 }
unsafe fn parse(input:*const i64, byte_count:usize)->Result<Vec<u8>,i64>{
    let mut tokens=[0i32;MAX_TOKENS];let mut count=0usize;let mut start=MAX_INPUT+1;
    for i in 0..byte_count {let ch=*input.add(1+i);if ch<32||ch>126{return Err(-1);}if is_separator(ch){if start!=MAX_INPUT+1{if count>=MAX_TOKENS{return Err(-1);}tokens[count]=word_id(input,start,i);count+=1;start=MAX_INPUT+1;}}else if start==MAX_INPUT+1{start=i;}}
    if start!=MAX_INPUT+1{if count>=MAX_TOKENS{return Err(-1);}tokens[count]=word_id(input,start,byte_count);count+=1;}
    if count==0{return Err(-3);}
    let negative=tokens[0]==36;let pos=if negative{1}else{0};let mut chunks=Vec::<i64>::new();let mut current=0i64;let mut prev_hundred=false;let mut prev_scale=false;let mut fraction=Vec::<u8>::new();let mut has_point=false;
    for i in pos..count {let id=tokens[i];
        if id==34{if i+1>=count{return Err(-10);}let next=tokens[i+1];let value=number_value(next);let after=if i+2<count{tokens[i+2]}else{-1};if (!prev_hundred&&!prev_scale)||value<0||!(value>=10||after==-1||after==35){return Err(-10);}continue;}
        if id==29{if current>=10||prev_scale{return Err(-5);}if current==0{current=1;}current*=100;prev_hundred=true;continue;}
        prev_hundred=false;
        if (30..=33).contains(&id){if current==0||prev_scale{return Err(-5);}let scale=match id{30=>1000,31=>1_000_000,32=>1_000_000_000, _=>1_000_000_000_000};let next=current*scale;if !chunks.is_empty()&&digits10(*chunks.last().unwrap())<=digits10(next){return Err(-5);}chunks.push(next);current=0;prev_scale=true;continue;}
        prev_scale=false;
        let value=number_value(id);if value>=0{if value==0&&!(current==0&&chunks.is_empty()){return Err(-5);}if current!=0&&digits10(current)<=digits10(value){return Err(-5);}current+=value;continue;}
        if id==35{if current!=0{chunks.push(current);}current=0;has_point=true;let mut words=0;for j in i+1..count{let digit=number_value(tokens[j]);if digit<0{return Err(-6);}words+=1;if words>MAX_FRACTION_WORDS{return Err(-1);}append_uint(&mut fraction,digit);}if words==0{return Err(-7);}break;}
        if id==36{return Err(if negative{-8}else{-9});}return Err(-4);
    }
    if current!=0{chunks.push(current);}let total:i64=chunks.iter().sum();let fraction_nonzero=fraction.iter().any(|&b|b!=b'0');let mut out=Vec::with_capacity(64);if negative&&(total!=0||fraction_nonzero){out.push(b'-');}append_uint(&mut out,total);if has_point{out.push(b'.');out.extend_from_slice(&fraction);}Ok(out)
}
#[no_mangle]
pub unsafe extern "C" fn words_to_number(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<1||length>MAX_INPUT+1{return -1;}let n=*input;if n<0||n as usize>MAX_INPUT||length!=n as usize+1{return -1;}
    let text=match parse(input,n as usize){Ok(v)=>v,Err(code)=>return code};if output.is_null()||capacity<text.len(){return -2;}std::ptr::copy_nonoverlapping(text.as_ptr(),output,text.len());text.len() as i64
}
