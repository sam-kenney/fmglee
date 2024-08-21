//// # fmglee
////
//// A string formatting library for gleam.
////
//// Valid format specifiers are
//// - %s - String
//// - %d - Int
//// - %f - Float
////
//// Examples
//// ```gleam
//// import fmglee
//// import gleeunit/should
//// 
//// fmglee.new("Number %d, float %f, string %s")
//// |> fmglee.d(99)
//// |> fmglee.f(12.9)
//// |> fmglee.s("Hello!")
//// |> fmglee.build
//// |> should.equal("Number 99, float 12.9, string Hello!")
//// ```
//// ```gleam
//// fmt.fmt("Number %d, float %f, string %s", with: [fmt.D(99), fmt.F(12.9), fmt.S("Hello!")])
//// |> should.equal("Number 99, float 12.9, string Hello!")
//// ```

import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/regex
import gleam/string

type Writer =
  fn(String) -> Nil

/// Errors returned by fmtglee
pub type FmtError {
  /// The current value does not match the current placeholder.
  /// Returned when the order of `Fmt`s is not the same as the order
  /// of placeholders.
  IncorrectValueType
  /// Returned when there are more `Fmt`s than placeholders in the string.
  TooManyValues
  /// Returned when there are less `Fmt`s than placeholders in the string.
  NotEnoughValues
}

pub type Fmt {
  /// Wrap a `String` for use with `fmt(_, using: [..])`
  S(String)
  /// Wrap an `Int` for use with `fmt(_, using: [..])`
  D(Int)
  /// Wrap a `Float` for use with `fmt(_, using: [..])`
  F(Float)
}

pub type Formatter {
  /// Used to compile a format string using the pipeable methods.
  Formatter(s: String, v: List(Fmt))
}

/// Compile the format string and print the output.
/// Panics if `fmt(s, v)` would panic with the
/// provided arguments.
pub fn print(s: String, with v: List(Fmt)) {
  write(s, v, io.print)
}

/// Compile the format string and print the output
/// with a newline. Panics if `fmt(s, v)` would
/// panic with the provided arguments.
pub fn println(s: String, with v: List(Fmt)) {
  write(s, v, io.println)
}

/// Print the output of a compiled `Formatter`.
/// Panics if the `Formatter` is invalid.
pub fn printf(formatter: Formatter) {
  writef(formatter, io.print)
}

/// Print the output of a compiled `Formatter`
/// with a newline. Panics if the `Formatter`
/// is invalid.
pub fn printlnf(formatter: Formatter) {
  writef(formatter, io.println)
}

/// Write a `Formatter` to the provided writer. The `Formatter`
/// will be built using `build` which will panic if the
/// formatter is invalid.
pub fn writef(formatter: Formatter, using writer: Writer) {
  write(formatter.s, formatter.v, writer)
}

/// Write a string and list of `Fmt` to the provided `Writer`.
pub fn write(s: String, with v: List(Fmt), using writer: Writer) {
  let assert Ok(str) = try_fmt(s, v)
  writer(str)
}

/// Format a string and a list of `Fmt` values.
/// Will panic where `try_fmt(s, v)` returns an
/// `FmtError`.
pub fn fmt(s: String, with v: List(Fmt)) -> String {
  let assert Ok(str) = try_fmt(s, with: v)
  str
}

/// Format a string and a list of `Fmt` values. Substitutes
/// placeholders from left to right with values in the
/// list of Fmt. Errors if there is a type missmatch between
/// the placeholder and the value, or if the number of placeholders
/// does not match the number of values given.
pub fn try_fmt(s: String, with v: List(Fmt)) -> Result(String, FmtError) {
  let assert Ok(re) = regex.from_string("(\\%d|\\%f|\\%s)")
  let matches = list.length(regex.scan(re, s))
  let values = list.length(v)

  case matches > values, values > matches {
    True, False -> Error(NotEnoughValues)
    False, True -> Error(TooManyValues)
    // We care about False, False, but True, True is not
    // possible and I cba with a panic guard
    _, _ -> fmt_iter(s, v)
  }
}

/// Recurse over the list of `Fmt` values and replace
/// placeholders until none remain. Errors if the
/// matching value for a placeholder is not the correct
/// type.
fn fmt_iter(str: String, with values: List(Fmt)) -> Result(String, FmtError) {
  case values {
    [S(value), ..rest] -> process_fmt("%s", value, str, rest)
    [D(value), ..rest] -> process_fmt("%d", int.to_string(value), str, rest)
    [F(value), ..rest] -> process_fmt("%f", float.to_string(value), str, rest)
    [] -> Ok(str)
  }
}

/// Remove the first value from values and substitute
/// the first found placeholder with it's value.
/// If the current value is not the same type as the
/// placeholder, return `Error(IncorrectValueType)`.
fn process_fmt(
  placeholder: String,
  value: String,
  str: String,
  remaining values: List(Fmt),
) -> Result(String, FmtError) {
  case string.split_once(str, on: placeholder) {
    Ok(#(first, last)) -> fmt_iter(first <> value <> last, values)
    Error(_) -> Error(IncorrectValueType)
  }
}

/// Create a new `Formatter`.
/// # Examples
/// ```gleam
/// new("Hello, %s. You are %d years old.")
/// |> s(name)
/// |> d(age)
/// |> build
/// |> io.println
/// ```
pub fn new(s: String) -> Formatter {
  Formatter(s, [])
}

/// Add a `String` value to a `Formatter`.
pub fn s(formatter: Formatter, s: String) -> Formatter {
  Formatter(formatter.s, [S(s), ..formatter.v])
}

/// Add an `Int` value to a `Formatter`.
pub fn d(formatter: Formatter, d: Int) -> Formatter {
  Formatter(formatter.s, [D(d), ..formatter.v])
}

/// Add a `Float` value to a `Formatter`.
pub fn f(formatter: Formatter, f: Float) -> Formatter {
  Formatter(formatter.s, [F(f), ..formatter.v])
}

/// Compile a `Formatter` into a string. Errors when the
/// number of provided values does not match the number
/// of placeholders, or if an invalid type was provided
/// for a placeholder.
pub fn try_build(formatter: Formatter) -> Result(String, FmtError) {
  try_fmt(formatter.s, with: list.reverse(formatter.v))
}

/// Compile a Formatter into a string. Panics where 
/// `try_build(formatter)` returns an `FmtError`.
pub fn build(formatter: Formatter) -> String {
  let assert Ok(str) = try_build(formatter)
  str
}
