module infix_to_prefix
const max_expression = 256
fn is_operand(ch i64) bool { return (ch>=48&&ch<=57)||(ch>=65&&ch<=90)||(ch>=97&&ch<=122) }
fn is_operator(ch i64) bool { return ch==43||ch==45||ch==42||ch==47||ch==94 }
fn precedence(ch i64) i64 { if ch==43||ch==45{return 1};if ch==42||ch==47{return 2};return 3 }
fn valid(input &i64,n usize) bool {
    unsafe { mut stage := [max_expression]u8{};mut depth:=0;mut done:=false
        for i in 0..int(n) {ch:=input[i]
            if depth==0 {if done{return false};if is_operand(ch){done=true}else if ch==40{stage[depth]=0;depth++}else{return false}}
            else if stage[depth-1]==0||stage[depth-1]==2 {if is_operand(ch){if stage[depth-1]==0{stage[depth-1]=1}else{stage[depth-1]=3}}else if ch==40&&depth<max_expression{stage[depth]=0;depth++}else{return false}}
            else if stage[depth-1]==1 {if !is_operator(ch){return false};stage[depth-1]=2}
            else {if ch!=41{return false};depth--;if depth==0{done=true}else if stage[depth-1]==0{stage[depth-1]=1}else if stage[depth-1]==2{stage[depth-1]=3}else{return false}}
        }
        return depth==0&&done
    }
}
@[export: 'infix_to_prefix']
pub fn infix_to_prefix(input &i64,length usize,output &u8,output_capacity usize) i64 {
    if length>max_expression||(length>0&&unsafe{input==nil}){return -1};if length==0{return 0};if !valid(input,length){return -1}
    unsafe {mut stack:=[max_expression]u8{};mut post:=[max_expression]u8{};mut top:=0;mut count:=0
        for i:=int(length);i>0;{i--;ch:=input[i]
            if is_operand(ch){post[count]=u8(ch);count++}else if ch==41{stack[top]=41;top++}else if ch==40{for top>0&&stack[top-1]!=41{top--;post[count]=stack[top];count++};if top>0{top--}}
            else{for top>0&&stack[top-1]!=41&&precedence(ch)<precedence(i64(stack[top-1])){top--;post[count]=stack[top];count++};stack[top]=u8(ch);top++}
        }
        for top>0{top--;post[count]=stack[top];count++}
        if output_capacity<count||output==nil{return -2};for j in 0..count{output[j]=post[count-1-j]};return i64(count)
    }
}
