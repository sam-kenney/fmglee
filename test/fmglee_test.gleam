import fmglee
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn build_test() {
  fmglee.new("Hello, %s. %d is an integer, %f is a float.")
  |> fmglee.s("world")
  |> fmglee.d(42)
  |> fmglee.f(6.9)
  |> fmglee.build
  |> should.equal("Hello, world. 42 is an integer, 6.9 is a float.")
}

pub fn try_build_too_many_values_test() {
  fmglee.new("")
  |> fmglee.s("")
  |> fmglee.try_build
  |> should.equal(Error(fmglee.TooManyValues))
}

pub fn try_build_not_enough_values_test() {
  fmglee.new("%s")
  |> fmglee.try_build
  |> should.equal(Error(fmglee.NotEnoughValues))
}

pub fn try_build_wrong_type_test() {
  fmglee.new("%d")
  |> fmglee.f(6.9)
  |> fmglee.try_build
  |> should.equal(Error(fmglee.InvalidFloatFormatSpecifier("%d")))
}

pub fn try_build_ok_test() {
  fmglee.new("%s is %d years old")
  |> fmglee.s("John")
  |> fmglee.d(42)
  |> fmglee.try_build
  |> should.equal(Ok("John is 42 years old"))
}

pub fn sprintf_test() {
  fmglee.sprintf("%s is %d years old", [fmglee.S("John"), fmglee.D(42)])
  |> should.equal("John is 42 years old")
}

pub fn try_sprintf_not_enough_values_test() {
  fmglee.try_sprintf("%s", [])
  |> should.equal(Error(fmglee.NotEnoughValues))
}

pub fn try_sprintf_too_many_values_test() {
  fmglee.try_sprintf("", [fmglee.S("John")])
  |> should.equal(Error(fmglee.TooManyValues))
}

pub fn try_sprintf_incorrect_value_type_test() {
  fmglee.try_sprintf("%s", [fmglee.D(42)])
  |> should.equal(Error(fmglee.IncorrectValueType("%s", fmglee.D(42))))
}

pub fn try_sprintf_ok_test() {
  fmglee.try_sprintf("%s is %d years old", [fmglee.S("John"), fmglee.D(42)])
  |> should.equal(Ok("John is 42 years old"))
}

pub fn write_test() {
  fn(s: String) { should.equal(s, "John is 42 years old") }
  |> fmglee.write("%s is %d years old", [fmglee.S("John"), fmglee.D(42)], _)
}

pub fn try_fmt_float_decimal_test() {
  fmglee.new("%.2f")
  |> fmglee.f(3.1415926)
  |> fmglee.try_build
  |> should.equal(Ok("3.14"))
}

pub fn try_fmt_float_decimal_less_test() {
  fmglee.new("%.2f")
  |> fmglee.f(1.0)
  |> fmglee.try_build
  |> should.equal(Ok("1.00"))
}

pub fn try_fmt_float_delimiter_test() {
  fmglee.new("%,f")
  |> fmglee.f(1234.0)
  |> fmglee.try_build
  |> should.equal(Ok("1,234.0"))
}

pub fn try_fmt_float_delimiter_no_remainder_test() {
  fmglee.new("%,.0f")
  |> fmglee.f(1234.0)
  |> fmglee.try_build
  |> should.equal(Ok("1,234"))
}

pub fn try_fmt_float_round_no_remainder_test() {
  fmglee.new("%.0f")
  |> fmglee.f(1234.1234)
  |> fmglee.try_build
  |> should.equal(Ok("1234"))
}
