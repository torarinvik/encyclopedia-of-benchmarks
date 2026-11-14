module closest_pair_sweep;

struct SweepTree {
    long[65] key;
    int[65] height, left, right;
}

fn int node_height(SweepTree* tree, int node) { return node == 0 ? 0 : tree.height[node]; }
fn void refresh(SweepTree* tree, int node) {
    int lh=node_height(tree,tree.left[node]), rh=node_height(tree,tree.right[node]);
    tree.height[node]=1+(lh>rh ? lh : rh);
}
fn int rotate_right(SweepTree* tree, int root) {
    int pivot=tree.left[root]; tree.left[root]=tree.right[pivot]; tree.right[pivot]=root;
    refresh(tree,root); refresh(tree,pivot); return pivot;
}
fn int rotate_left(SweepTree* tree, int root) {
    int pivot=tree.right[root]; tree.right[root]=tree.left[pivot]; tree.left[pivot]=root;
    refresh(tree,root); refresh(tree,pivot); return pivot;
}
fn int balance(SweepTree* tree, int root) {
    refresh(tree,root);
    int difference=node_height(tree,tree.left[root])-node_height(tree,tree.right[root]);
    if (difference>1) {
        int child=tree.left[root];
        if (node_height(tree,tree.left[child])<node_height(tree,tree.right[child])) tree.left[root]=rotate_left(tree,child);
        return rotate_right(tree,root);
    }
    if (difference< -1) {
        int child=tree.right[root];
        if (node_height(tree,tree.right[child])<node_height(tree,tree.left[child])) tree.right[root]=rotate_right(tree,child);
        return rotate_left(tree,root);
    }
    return root;
}
fn int insert(SweepTree* tree, int root, int index) {
    if (root==0) return index;
    if (tree.key[index]<tree.key[root]) tree.left[root]=insert(tree,tree.left[root],index);
    else tree.right[root]=insert(tree,tree.right[root],index);
    return balance(tree,root);
}
fn int erase(SweepTree* tree, int root, long key) {
    if (root==0) return 0;
    if (key<tree.key[root]) tree.left[root]=erase(tree,tree.left[root],key);
    else if (key>tree.key[root]) tree.right[root]=erase(tree,tree.right[root],key);
    else if (tree.left[root]==0) return tree.right[root];
    else if (tree.right[root]==0) return tree.left[root];
    else {
        int successor=tree.right[root];
        while (tree.left[successor]!=0) successor=tree.left[successor];
        long replacement=tree.key[successor];
        tree.key[root]=replacement;
        tree.right[root]=erase(tree,tree.right[root],replacement);
    }
    return balance(tree,root);
}
fn long range_best(SweepTree* tree, int root, long low, long high, long x, long y, long initial) {
    if (root==0) return initial;
    long key=tree.key[root], best=initial;
    if (key>=low) best=range_best(tree,tree.left[root],low,high,x,y,best);
    if (key>=low && key<=high) {
        long dx=x-(key%2001-1000), dy=y-(key/2001-1000);
        long distance=dx*dx+dy*dy;
        if (distance<best) best=distance;
    }
    if (key<=high) best=range_best(tree,tree.right[root],low,high,x,y,best);
    return best;
}

fn long closest_pair_sweep(long* input, usz length) @export("closest_pair_sweep") {
    if (input==null || length<5 || length>130 || input[0]<2 || input[0]>64) return -1;
    usz n=input[0].usz();
    if (length!=1+2*n) return -1;
    long[64] points, scratch;
    for (usz i=0; i<n; i++) {
        long x=input[1+2*i], y=input[2+2*i];
        if (x< -1000 || x>1000 || y< -1000 || y>1000) return -1;
        points[i]=(x+1000)*2001+y+1000;
    }
    for (usz width=1; width<n; width*=2) {
        for (usz begin=0; begin<n; begin+=2*width) {
            usz middle=begin+width<n ? begin+width : n;
            usz end=begin+2*width<n ? begin+2*width : n;
            usz i=begin, j=middle;
            for (usz k=begin; k<end; k++) {
                if (j==end || (i<middle && points[i]<=points[j])) scratch[k]=points[i++];
                else scratch[k]=points[j++];
            }
        }
        for (usz i=0; i<n; i++) points[i]=scratch[i];
    }
    for (usz i=1; i<n; i++) if (points[i]==points[i-1]) return 0;
    SweepTree tree=zeroed;
    int root=0;
    usz oldest=0;
    long best=8000001;
    for (usz i=0; i<n; i++) {
        long x=points[i]/2001-1000, y=points[i]%2001-1000;
        while (oldest<i) {
            long old_x=points[oldest]/2001-1000, dx=x-old_x;
            if (dx*dx<=best) break;
            long old_y=points[oldest]%2001-1000;
            root=erase(&tree,root,(old_y+1000)*2001+old_x+1000);
            oldest++;
        }
        long lo=0, hi=3000;
        while (lo<hi) { long middle=(lo+hi+1)/2; if (middle*middle<=best) lo=middle; else hi=middle-1; }
        best=range_best(&tree,root,(y-lo+1000)*2001,(y+lo+1000)*2001+2000,x,y,best);
        int index=(int)(i+1);
        tree.key[index]=(y+1000)*2001+x+1000; tree.height[index]=1;
        root=insert(&tree,root,index);
    }
    return best;
}
