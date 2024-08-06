import fmglee as fmt
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn build_test() {
  fmt.new("Hello, %s. %d is an integer, %f is a float.")
  |> fmt.s("world")
  |> fmt.d(42)
  |> fmt.f(6.9)
  |> fmt.build
  |> should.equal("Hello, world. 42 is an integer, 6.9 is a float.")
}

pub fn try_build_too_many_values_test() {
  fmt.new("")
  |> fmt.s("")
  |> fmt.try_build
  |> should.equal(Error(fmt.TooManyValues))
}

pub fn try_build_not_enough_values_test() {
  fmt.new("%s")
  |> fmt.try_build
  |> should.equal(Error(fmt.NotEnoughValues))
}

pub fn try_build_wrong_type_test() {
  fmt.new("%d")
  |> fmt.f(6.9)
  |> fmt.try_build
  |> should.equal(Error(fmt.IncorrectValueType))
}

pub fn try_build_ok_test() {
  fmt.new("%s is %d years old")
  |> fmt.s("John")
  |> fmt.d(42)
  |> fmt.try_build
  |> should.equal(Ok("John is 42 years old"))
}

pub fn fmt_test() {
  fmt.fmt("%s is %d years old", [fmt.S("John"), fmt.D(42)])
  |> should.equal("John is 42 years old")
}

pub fn try_fmt_not_enough_values_test() {
  fmt.try_fmt("%s", [])
  |> should.equal(Error(fmt.NotEnoughValues))
}

pub fn try_fmt_too_many_values_test() {
  fmt.try_fmt("", [fmt.S("John")])
  |> should.equal(Error(fmt.TooManyValues))
}

pub fn try_fmt_incorrect_value_type_test() {
  fmt.try_fmt("%s", [fmt.D(42)])
  |> should.equal(Error(fmt.IncorrectValueType))
}

pub fn try_fmt_ok_test() {
  fmt.try_fmt("%s is %d years old", [fmt.S("John"), fmt.D(42)])
  |> should.equal(Ok("John is 42 years old"))
}
