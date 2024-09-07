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
//// fmglee.sprintf("Number %d, float %f, string %s", with: [fmglee.D(99), fmglee.F(12.9), fmglee.S("Hello!")])
//// |> should.equal("Number 99, float 12.9, string Hello!")
//// ```
//// ```gleam
//// fmglee.sprintf("%,.2f", [fmglee.F(1234.554)])
//// |> should.equal("1,234.55")
//// ```

import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/regex
import gleam/result
import gleam/string

type Writer =
  fn(String) -> Nil

/// Errors returned by fmtglee
pub type FmtError {
  /// The current value does not match the current placeholder.
  /// Returned when the order of `Fmt`s is not the same as the order
  /// of placeholders.
  IncorrectValueType(expected: String, got: Fmt)
  /// Returned when there are more `Fmt`s than placeholders in the string.
  TooManyValues
  /// Returned when there are less `Fmt`s than placeholders in the string.
  NotEnoughValues
  /// Returned when a number has no floating point.
  InvalidFloat(String)
  /// Returned when an invalid Integer value is provided to a Float formatter.
  InvalidInt(String)
  /// Returned when a float format specifier cannot be parsed.
  /// Can also occur when a `Float` value is provided alongside a `String`
  /// or `Int` placeholder.
  InvalidFloatFormatSpecifier(String)
}

pub type Fmt {
  /// Wrap a `String` for use with `sprintf(_, using: [..])`
  S(String)
  /// Wrap an `Int` for use with `sprintf(_, using: [..])`
  D(Int)
  /// Wrap a `Float` for use with `fmt(_, using: [..])`
  F(Float)
}

pub type Formatter {
  /// Used to compile a format string using the pipeable methods.
  Formatter(s: String, v: List(Fmt))
}

/// Compile the format string and print the output.
/// Panics if `sprintf(s, v)` would panic with the
/// provided arguments.
pub fn print(s: String, with v: List(Fmt)) {
  write(s, v, io.print)
}

/// Compile the format string and print the output
/// with a newline. Panics if `sprintf(s, v)` would
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
  let assert Ok(str) = try_sprintf(s, v)
  writer(str)
}

@deprecated("Use sprintf instead")
pub fn fmt(s: String, using v: List(Fmt)) -> String {
  sprintf(s, v)
}

/// Format a string and a list of `Fmt` values.
/// Will panic where `try_sprintf(s, v)` returns an
/// `FmtError`.
pub fn sprintf(s: String, with v: List(Fmt)) -> String {
  let assert Ok(str) = try_sprintf(s, with: v)
  str
}

@deprecated("Use try_sprintf instead")
pub fn try_fmt(s: String, with v: List(Fmt)) -> Result(String, FmtError) {
  try_sprintf(s, v)
}

/// Format a string and a list of `Fmt` values. Substitutes
/// placeholders from left to right with values in the
/// list of Fmt. Errors if there is a type missmatch between
/// the placeholder and the value, or if the number of placeholders
/// does not match the number of values given.
pub fn try_sprintf(s: String, with v: List(Fmt)) -> Result(String, FmtError) {
  let assert Ok(re) = regex.from_string("(\\%d|\\%s|\\%[\\W]?f|%[\\W]?\\.\\df)")
  let matches =
    regex.scan(re, s)
    |> list.map(fn(m) { m.content })

  let num_matches = list.length(matches)
  let num_values = list.length(v)

  case num_matches > num_values, num_values > num_matches {
    True, False -> Error(NotEnoughValues)
    False, True -> Error(TooManyValues)
    // We care about False, False, but True, True is not
    // possible and I cba with a panic guard
    _, _ -> do_fmt(s, v, matches)
  }
}

/// Recurse over the list of `Fmt` values and replace
/// placeholders until none remain. Errors if the
/// matching value for a placeholder is not the correct
/// type.
fn do_fmt(
  str: String,
  values: List(Fmt),
  matches: List(String),
) -> Result(String, FmtError) {
  case values, matches {
    [], [] -> Ok(str)
    [S(value), ..rest], ["%s", ..matches] ->
      process_fmt("%s", value, str, rest, matches)
    [D(value), ..rest], ["%d", ..matches] ->
      process_fmt("%d", int.to_string(value), str, rest, matches)
    [F(value), ..rest], [placeholder, ..matches] ->
      process_float_fmt(placeholder, value, str, rest, matches)
    [got, ..], [expected, ..] -> Error(IncorrectValueType(expected, got))
    _, _ -> Error(TooManyValues)
  }
}

fn process_float_fmt(
  placeholder: String,
  value: Float,
  str: String,
  values: List(Fmt),
  matches: List(String),
) -> Result(String, FmtError) {
  case string.split(placeholder, "") {
    ["%", c, "f"] -> {
      use val <- result.try(format_delimited_float(value, c))
      process_fmt(placeholder, val, str, values, matches)
    }
    ["%", c, ".", n, "f"] -> {
      use val <- result.try(format_delimited_float(value, c))
      use rounded <- result.try(round_float(val, n))
      process_fmt(placeholder, rounded, str, values, matches)
    }
    ["%", ".", n, "f"] -> {
      use val <- result.try(
        float.to_string(value)
        |> round_float(n),
      )
      process_fmt(placeholder, val, str, values, matches)
    }
    ["%", "f"] ->
      process_fmt("%f", float.to_string(value), str, values, matches)
    _ -> Error(InvalidFloatFormatSpecifier(placeholder))
  }
}

fn round_float(value: String, n: String) -> Result(String, FmtError) {
  use n <- result.try({
    int.parse(n)
    |> result.replace_error(InvalidInt(n))
  })

  case n {
    0 -> {
      case string.split(value, ".") {
        [num, _] -> Ok(num)
        _ -> Error(InvalidFloat(value))
      }
    }
    _ -> {
      case string.split(value, ".") {
        [num, remainder] -> {
          let parts = string.split(remainder, "")

          let len_parts = list.length(parts)

          let rounded =
            case len_parts > n {
              True -> {
                list.take(parts, n)
              }
              False -> {
                let pad = list.repeat("0", { n - len_parts })
                list.append(parts, pad)
              }
            }
            |> string.join("")

          Ok(num <> "." <> rounded)
        }
        _ -> Error(InvalidFloat(value))
      }
    }
  }
}

fn format_delimited_float(
  value: Float,
  delimiter: String,
) -> Result(String, FmtError) {
  let val = float.to_string(value)
  case string.split(val, on: ".") {
    [num, remainder] -> {
      let intersparced =
        string.split(num, "")
        |> list.reverse
        |> list.index_map(fn(v, i) {
          case i % 3 {
            0 -> [delimiter, v]
            _ -> [v]
          }
        })
        |> list.flatten

      let s =
        case intersparced {
          [val, ..vals] if val == delimiter -> vals
          vals -> vals
        }
        |> list.reverse
        |> string.join("")
      Ok(s <> "." <> remainder)
    }
    _ -> Error(InvalidFloat(float.to_string(value)))
  }
}

/// Remove the first value from values and substitute
/// the first found placeholder with it's value.
fn process_fmt(
  placeholder: String,
  value: String,
  str: String,
  values: List(Fmt),
  matches: List(String),
) -> Result(String, FmtError) {
  case string.split_once(str, on: placeholder) {
    Ok(#(first, last)) -> do_fmt(first <> value <> last, values, matches)
    Error(_) -> Error(IncorrectValueType(expected: placeholder, got: S(value)))
  }
}

/// Create a new `Formatter`.
/// # Examples
/// ```gleam
/// new("Hello, %s. You are %d years old.")
/// |> s(name)
/// |> d(age)
/// |> build
/// 
/// new("Hello, %s. You are %d years old.")
/// |> s(name)
/// |> d(age)
/// |> printlnf
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
  try_sprintf(formatter.s, with: list.reverse(formatter.v))
}

/// Compile a Formatter into a string. Panics where 
/// `try_build(formatter)` returns an `FmtError`.
pub fn build(formatter: Formatter) -> String {
  let assert Ok(str) = try_build(formatter)
  str
}
