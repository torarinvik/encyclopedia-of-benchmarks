module is_sum_tree;
const MAX_NODES = 400;
const INVALID_RESULT = -9000000000000000000;

fn long subtree_sum(long* nodes, long index) {
    if (index < 0) return 0;
    return nodes[3*index] + subtree_sum(nodes,nodes[3*index+1]) + subtree_sum(nodes,nodes[3*index+2]);
}
fn bool check_node(long* nodes, long index) {
    long value=nodes[3*index], left=nodes[3*index+1], right=nodes[3*index+2];
    if(left==-1 && right==-1)return true;
    long left_sum=subtree_sum(nodes,left), right_sum=subtree_sum(nodes,right);
    bool left_ok=left==-1 || check_node(nodes,left);
    bool right_ok=right==-1 || check_node(nodes,right);
    return value==left_sum+right_sum && left_ok && right_ok;
}
fn long is_sum_tree(long* nodes, usz count, long root) @export("is_sum_tree") {
    if(nodes==null||count==0||count>MAX_NODES||root<0||(ulong)root>=count)return INVALID_RESULT;
    bool seen[MAX_NODES]={}; long stack[MAX_NODES*2]={}; usz top=0; stack[top++]=root;
    while(top>0){long i=stack[--top];if(i<0||(ulong)i>=count||seen[i])return INVALID_RESULT;seen[i]=true;
        long value=nodes[3*i],left=nodes[3*i+1],right=nodes[3*i+2];
        if(value < -1000000000||value>1000000000||left < -1||right < -1||(left>=0&&(ulong)left>=count)||(right>=0&&(ulong)right>=count))return INVALID_RESULT;
        if(left>=0)stack[top++]=left;if(right>=0)stack[top++]=right;
    }
    return check_node(nodes,root)?1:0;
}
