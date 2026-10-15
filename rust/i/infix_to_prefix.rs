/// Convert fully parenthesized bounded ASCII infix expressions to prefix.
const MAX: usize = 256;
fn operand(c:i64)->bool {(48..=57).contains(&c)||(65..=90).contains(&c)||(97..=122).contains(&c)}
fn operation(c:i64)->bool {matches!(c,43|45|42|47|94)}
fn precedence(c:i64)->i64 {if matches!(c,43|45){1}else if matches!(c,42|47){2}else{3}}
fn valid(input:&[i64])->bool {
    let mut stage=[0u8;MAX]; let mut depth=0usize; let mut done=false;
    for &ch in input { if depth==0 { if done{return false} if operand(ch){done=true}else if ch==40{stage[depth]=0;depth+=1}else{return false} }
        else if stage[depth-1]==0||stage[depth-1]==2 {if operand(ch){stage[depth-1]=if stage[depth-1]==0{1}else{3}}else if ch==40&&depth<MAX{stage[depth]=0;depth+=1}else{return false}}
        else if stage[depth-1]==1 {if !operation(ch){return false}stage[depth-1]=2}
        else {if ch!=41{return false}depth-=1;if depth==0{done=true}else if stage[depth-1]==0{stage[depth-1]=1}else if stage[depth-1]==2{stage[depth-1]=3}else{return false}}
    } depth==0&&done
}
#[no_mangle]
pub unsafe extern "C" fn infix_to_prefix(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64 {
    if length>MAX||(length>0&&input.is_null()){return -1} if length==0{return 0}
    let values=std::slice::from_raw_parts(input,length); if !valid(values){return -1}
    let mut stack=[0u8;MAX];let mut post=[0u8;MAX];let(mut top,mut count)=(0usize,0usize);
    for i in (0..length).rev(){let ch=values[i];if operand(ch){post[count]=ch as u8;count+=1}else if ch==41{stack[top]=b')';top+=1}else if ch==40{while top>0&&stack[top-1]!=b')'{top-=1;post[count]=stack[top];count+=1}if top>0{top-=1}}else{while top>0&&stack[top-1]!=b')'&&precedence(ch)<precedence(stack[top-1] as i64){top-=1;post[count]=stack[top];count+=1}stack[top]=ch as u8;top+=1}}
    while top>0{top-=1;post[count]=stack[top];count+=1} if capacity<count||(count>0&&output.is_null()){return -2}
    for i in 0..count{*output.add(i)=post[count-1-i]} count as i64
}
