import AST

/// The representation of runtime value.
public protocol Value: AnyObject {

  /// The type of the value.
  var type: VILType { get }

}

// MARK: Constants

/// A literal value.
public class LiteralValue: Value {

  /// The type of the constant.
  public let type: VILType

  fileprivate init(type: VILType) {
    self.type = type
  }

}

/// A constant "unit" value.
public final class UnitValue: LiteralValue, CustomStringConvertible {

  public init(context: AST.Context) {
    super.init(type: .lower(context.unitType))
  }

  public var description: String { "unit" }

}

/// A constant integer value.
public final class IntLiteralValue: LiteralValue, CustomStringConvertible {

  /// The literal's value.
  public let value: Int

  public init(value: Int, context: AST.Context) {
    self.value = value
    super.init(type: .lower(context.getBuiltinType(named: "IntLiteral")!))
  }

  public var description: String {
    return String(describing: value)
  }

}

/// A reference to a built-in function.
public final class BuiltinFunRef: LiteralValue, CustomStringConvertible {

  /// The built-in function declaration that is being referred.
  public let decl: FunDecl

  public init(decl: FunDecl) {
    precondition(decl.isBuiltin)
    self.decl = decl
    super.init(type: .lower(decl.type))
  }

  public var description: String {
    return "b\"\(decl.name)\""
  }

}

/// A reference to a VIL function.
public final class FunRef: LiteralValue, CustomStringConvertible {

  /// The name of the function being referenced.
  public let name: String

  public init(function: Function) {
    self.name = function.name
    super.init(type: function.type)
  }

  public var description: String {
    return "@\(name)"
  }

}

/// A null location.
public final class NullAddr: LiteralValue, CustomStringConvertible {

  public override init(type: VILType) {
    assert(type.isAddress, "type must be an address type")
    super.init(type: type)
  }

  public var description: String { "null_addr" }

}

/// An error value.
public final class ErrorValue: LiteralValue, CustomStringConvertible {

  public init(context: AST.Context) {
    super.init(type: .lower(context.errorType))
  }

  public var description: String { "error" }

}

// MARK: Other values

/// The incoming argument of a block or function.
public final class ArgumentValue: Value {

  public let type: VILType

  /// The function to which the argument belongs.
  public unowned let function: Function

  init(type: VILType, function: Function) {
    self.type = type
    self.function = function
  }

}
