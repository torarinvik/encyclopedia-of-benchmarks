package closest_pair_sweep
import "core:c"

Tree :: struct {
    key: [65]i64,
    height, left, right: [65]int,
}

node_height :: proc(tree: ^Tree, node: int) -> int {
    if node==0 do return 0
    return tree.height[node]
}
refresh :: proc(tree: ^Tree, node: int) {
    tree.height[node]=1+max(node_height(tree,tree.left[node]),node_height(tree,tree.right[node]))
}
rotate_right :: proc(tree: ^Tree, root: int) -> int {
    pivot:=tree.left[root]
    tree.left[root]=tree.right[pivot]; tree.right[pivot]=root
    refresh(tree,root); refresh(tree,pivot); return pivot
}
rotate_left :: proc(tree: ^Tree, root: int) -> int {
    pivot:=tree.right[root]
    tree.right[root]=tree.left[pivot]; tree.left[pivot]=root
    refresh(tree,root); refresh(tree,pivot); return pivot
}
balance :: proc(tree: ^Tree, root: int) -> int {
    refresh(tree,root)
    difference:=node_height(tree,tree.left[root])-node_height(tree,tree.right[root])
    if difference>1 {
        child:=tree.left[root]
        if node_height(tree,tree.left[child])<node_height(tree,tree.right[child]) { tree.left[root]=rotate_left(tree,child) }
        return rotate_right(tree,root)
    }
    if difference< -1 {
        child:=tree.right[root]
        if node_height(tree,tree.right[child])<node_height(tree,tree.left[child]) { tree.right[root]=rotate_right(tree,child) }
        return rotate_left(tree,root)
    }
    return root
}
insert :: proc(tree: ^Tree, root,index: int) -> int {
    if root==0 do return index
    if tree.key[index]<tree.key[root] { tree.left[root]=insert(tree,tree.left[root],index) }
    else { tree.right[root]=insert(tree,tree.right[root],index) }
    return balance(tree,root)
}
erase :: proc(tree: ^Tree, root: int, key: i64) -> int {
    if root==0 do return 0
    if key<tree.key[root] { tree.left[root]=erase(tree,tree.left[root],key) }
    else if key>tree.key[root] { tree.right[root]=erase(tree,tree.right[root],key) }
    else if tree.left[root]==0 { return tree.right[root] }
    else if tree.right[root]==0 { return tree.left[root] }
    else {
        successor:=tree.right[root]
        for tree.left[successor]!=0 { successor=tree.left[successor] }
        replacement:=tree.key[successor]
        tree.key[root]=replacement; tree.right[root]=erase(tree,tree.right[root],replacement)
    }
    return balance(tree,root)
}
range_best :: proc(tree: ^Tree, root: int, low,high,x,y,initial: i64) -> i64 {
    if root==0 do return initial
    key:=tree.key[root]; best:=initial
    if key>=low { best=range_best(tree,tree.left[root],low,high,x,y,best) }
    if key>=low && key<=high {
        dx:=x-(key%2001-1000); dy:=y-(key/2001-1000)
        best=min(best,dx*dx+dy*dy)
    }
    if key<=high { best=range_best(tree,tree.right[root],low,high,x,y,best) }
    return best
}

@(export)
closest_pair_sweep :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input==nil || length<5 || length>130 do return -1
    if input[0]<2 || input[0]>64 do return -1
    n:=int(input[0])
    if length!=c.size_t(1+2*n) do return -1
    points: [64]i64; scratch: [64]i64
    for i:=0; i<n; i+=1 {
        x,y:=input[1+2*i],input[2+2*i]
        if x< -1000 || x>1000 || y< -1000 || y>1000 do return -1
        points[i]=(x+1000)*2001+y+1000
    }
    for width:=1; width<n; width*=2 {
        for begin:=0; begin<n; begin+=2*width {
            middle:=min(begin+width,n); end:=min(begin+2*width,n)
            i,j:=begin,middle
            for k:=begin; k<end; k+=1 {
                if j==end || (i<middle && points[i]<=points[j]) { scratch[k]=points[i]; i+=1 }
                else { scratch[k]=points[j]; j+=1 }
            }
        }
        for i:=0; i<n; i+=1 { points[i]=scratch[i] }
    }
    for i:=1; i<n; i+=1 { if points[i]==points[i-1] do return 0 }
    tree: Tree = {}
    root,oldest:=0,0
    best:=i64(8000001)
    for i:=0; i<n; i+=1 {
        x,y:=points[i]/2001-1000,points[i]%2001-1000
        for oldest<i {
            old_x:=points[oldest]/2001-1000; dx:=x-old_x
            if dx*dx<=best do break
            old_y:=points[oldest]%2001-1000
            root=erase(&tree,root,(old_y+1000)*2001+old_x+1000)
            oldest+=1
        }
        lo,hi:=i64(0),i64(3000)
        for lo<hi {
            middle:=(lo+hi+1)/2
            if middle*middle<=best { lo=middle } else { hi=middle-1 }
        }
        best=range_best(&tree,root,(y-lo+1000)*2001,(y+lo+1000)*2001+2000,x,y,best)
        index:=i+1
        tree.key[index]=(y+1000)*2001+x+1000; tree.height[index]=1
        root=insert(&tree,root,index)
    }
    return best
}
