
fn take(v: &mut Vec<i32>) {
    v[0] = 42
}
fn main() {
    let v = vec![1, 2, 3];
    take(&v);
    let x = v[0];
}
