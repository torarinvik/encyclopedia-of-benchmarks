module bitmask_assignment_count
const max_people=8
const max_tasks=12
const max_input=106
@[export:'bitmask_assignment_count']
pub fn bitmask_assignment_count(input &i64,length usize)i64{
 if isnil(input)||length<2||length>max_input{return -1};pv:=unsafe{input[0]};tv:=unsafe{input[1]};if pv<0||pv>max_people||tv<0||tv>max_tasks{return -1};people:=int(pv);tasks:=int(tv);mut freq:=[max_tasks+1][max_people]i64{};mut pos:=2
 for p in 0..people{if pos>=int(length){return -1};count:=unsafe{input[pos]};pos++;if count<0||count>12||pos+int(count)>int(length){return -1};for _ in 0..int(count){task:=unsafe{input[pos]};pos++;if task<1||task>tv{return -1};freq[int(task)][p]++}}
 if pos!=int(length){return -1};states:=1<<people;full:=states-1;mut dp:=[1<<max_people][max_tasks+2]i64{};for mask in 0..states{if mask==full{dp[mask][tasks+1]=1}}
 if tasks>0{for task:=tasks;task>=1;task--{for mask in 0..states{mut ways:=dp[mask][task+1];mut bit:=1;for p in 0..people{if freq[task][p]>0&&(mask&bit)==0{ways+=freq[task][p]*dp[mask|bit][task+1]};bit<<=1};dp[mask][task]=ways}}}
 return dp[0][1]
}
