fn main()
{
  let mut x:i32 = 52;
  let y:i32 = &mut x;
    
  *y = 5;
  println!(*y);
  
  return;
}
