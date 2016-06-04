println b
ext ->
  b = 3

println b

task copy(type : Copy), ->
  from 'source'
  into 'dest'
  _x = 9
  println _x
  println b
  b = 5
  println b

println _x
println b
