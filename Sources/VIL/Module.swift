/// A VIL module.
///
/// A VIL module is essentially a collection of VIL functions that have been lowered from a module
/// declaration.
public final class Module {

  /// The module's identifier.
  public let id: String

  /// The functions in the module.
  public var functions: [String: Function] = [:]

  /// The witness tables in the module.
  public var witnessTables: [WitnessTable] = []

  public init(id: String) {
    self.id = id
  }

}
