/// Convert fully parenthesized bounded ASCII infix expressions to prefix.
const MAX: usize = 256;
fn operand(c:i64) bool { return (c>=48 and c<=57) or (c>=65 and c<=90) or (c>=97 and c<=122); }
fn operation(c:i64) bool { return c==43 or c==45 or c==42 or c==47 or c==94; }
fn precedence(c:i64) i64 { return if(c==43 or c==45) 1 else if(c==42 or c==47) 2 else 3; }
fn valid(input:[*]const i64,n:usize) bool {
    var stage:[MAX]u8=@splat(0);var depth:usize=0;var done=false;
    for(0..n)|i|{const ch=input[i];
        if(depth==0){if(done)return false;if(operand(ch)){done=true;}else if(ch==40){stage[depth]=0;depth+=1;}else{return false;}}
        else if(stage[depth-1]==0 or stage[depth-1]==2){if(operand(ch)){stage[depth-1]=if(stage[depth-1]==0) 1 else 3;}else if(ch==40 and depth<MAX){stage[depth]=0;depth+=1;}else{return false;}}
        else if(stage[depth-1]==1){if(!operation(ch))return false;stage[depth-1]=2;}
        else{if(ch!=41)return false;depth-=1;if(depth==0){done=true;}else if(stage[depth-1]==0){stage[depth-1]=1;}else if(stage[depth-1]==2){stage[depth-1]=3;}else{return false;}}
    }
    return depth==0 and done;
}
pub export fn infix_to_prefix(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize) i64 {
    if(length>MAX or (length>0 and input==null))return -1;if(length==0)return 0;
    const values=input[0..length];if(!valid(values.ptr,length))return -1;
    var stack:[MAX]u8=@splat(0);var post:[MAX]u8=@splat(0);var top:usize=0;var count:usize=0;
    var i=length;while(i>0){i-=1;const ch=values[i];
        if(operand(ch)){post[count]=@intCast(ch);count+=1;}else if(ch==41){stack[top]=')';top+=1;}else if(ch==40){while(top>0 and stack[top-1]!=')'){top-=1;post[count]=stack[top];count+=1;}if(top>0)top-=1;}
        else{while(top>0 and stack[top-1]!=')' and precedence(ch)<precedence(stack[top-1])){top-=1;post[count]=stack[top];count+=1;}stack[top]=@intCast(ch);top+=1;}
    }
    while(top>0){top-=1;post[count]=stack[top];count+=1;}
    if(capacity<count or (count>0 and output==null))return -2;
    for(0..count)|j|output[j]=post[count-1-j];return @intCast(count);
}
