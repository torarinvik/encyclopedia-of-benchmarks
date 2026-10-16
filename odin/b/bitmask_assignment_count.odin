package bitmask_assignment_count
import "core:c"
MAX_PEOPLE :: 8
MAX_TASKS :: 12
MAX_INPUT :: 106
@(export)
bitmask_assignment_count :: proc "c" (input:[^]i64,length:c.size_t)->i64{
 if input==nil||length<2||length>MAX_INPUT||input[0]<0||input[0]>MAX_PEOPLE||input[1]<0||input[1]>MAX_TASKS do return -1
 people:=int(input[0]);tasks:=int(input[1]);freq:[MAX_TASKS+1][MAX_PEOPLE]i64;pos:=2
 for p:=0;p<people;p+=1{if pos>=int(length) do return -1;count:=input[pos];pos+=1;if count<0||count>i64(MAX_TASKS)||pos+int(count)>int(length) do return -1;for j:=0;j<int(count);j+=1{task:=input[pos];pos+=1;if task<1||task>i64(tasks) do return -1;freq[int(task)][p]+=1}}
 if pos!=int(length) do return -1;states:=1<<people;full:=states-1;dp:[1<<MAX_PEOPLE][MAX_TASKS+2]i64
 for mask:=0;mask<states;mask+=1{if mask==full{dp[mask][tasks+1]=1}}
 for task:=tasks;task>=1;task-=1{for mask:=0;mask<states;mask+=1{ways:=dp[mask][task+1];bit:=1;for p:=0;p<people;p+=1{if freq[task][p]>0&&(mask&bit)==0{ways+=freq[task][p]*dp[mask|bit][task+1]};bit*=2};dp[mask][task]=ways}}
 return dp[0][1]
}
