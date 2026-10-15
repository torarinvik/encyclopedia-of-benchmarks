package infix_to_prefix

import "core:c"
MAX :: 256
operand :: proc "contextless" (ch:i64)->bool { return (ch>=48&&ch<=57)||(ch>=65&&ch<=90)||(ch>=97&&ch<=122) }
operation :: proc "contextless" (ch:i64)->bool { return ch==43||ch==45||ch==42||ch==47||ch==94 }
precedence :: proc "contextless" (ch:i64)->i64 { if ch==43||ch==45{return 1};if ch==42||ch==47{return 2};return 3 }
valid :: proc "contextless" (input:[^]i64,n:c.size_t)->bool {
    stage:[MAX]u8;depth:usize=0;done:=false
    for i:c.size_t=0;i<n;i+=1 {ch:=input[i]
        if depth==0 {if done{return false};if operand(ch){done=true}else if ch==40{stage[depth]=0;depth+=1}else{return false}}
        else if stage[depth-1]==0||stage[depth-1]==2 {if operand(ch){if stage[depth-1]==0{stage[depth-1]=1}else{stage[depth-1]=3}}else if ch==40&&depth<MAX{stage[depth]=0;depth+=1}else{return false}}
        else if stage[depth-1]==1 {if !operation(ch){return false};stage[depth-1]=2}
        else {if ch!=41{return false};depth-=1;if depth==0{done=true}else if stage[depth-1]==0{stage[depth-1]=1}else if stage[depth-1]==2{stage[depth-1]=3}else{return false}}
    }
    return depth==0&&done
}
@(export)
infix_to_prefix :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if length>MAX||(length>0&&input==nil) do return -1
    if length==0 do return 0
    if !valid(input,length) do return -1
    stack:[MAX]u8;post:[MAX]u8;top,count:usize=0,0
    i:=length
    for i>0 {i-=1;ch:=input[i]
        if operand(ch){post[count]=u8(ch);count+=1}else if ch==41{stack[top]=41;top+=1}else if ch==40{for top>0&&stack[top-1]!=41{top-=1;post[count]=stack[top];count+=1};if top>0{top-=1}}
        else {for top>0&&stack[top-1]!=41&&precedence(ch)<precedence(i64(stack[top-1])){top-=1;post[count]=stack[top];count+=1};stack[top]=u8(ch);top+=1}
    }
    for top>0{top-=1;post[count]=stack[top];count+=1}
    if capacity<count||(count>0&&output==nil) do return -2
    for j:usize=0;j<count;j+=1{output[j]=post[count-1-j]}
    return i64(count)
}
