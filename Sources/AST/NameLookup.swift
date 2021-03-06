extension DeclSpace {

  public func lookup(unqualified name: String, in context: Context) -> LookupResult {
    var space: DeclSpace = self
    var result = LookupResult()

    // Only function and type declarations are overloadable. Thus we must filter out every other
    // value declaration once the first has been found.
    var hasNonOverloadableDecl = false

    while true {
      // Enumerate the symbols declared directly within the current space.
      var locals = space.lookup(qualified: name)
      if hasNonOverloadableDecl {
        locals = locals.filter({ $0.isOverloadable })
      } else {
        hasNonOverloadableDecl = locals.contains(where: { !$0.isOverloadable })
      }

      result.append(contentsOf: locals)
      if let parent = space.parentDeclSpace {
        space = parent
      } else if let stdlib = context.stdlib, space !== stdlib {
        space = stdlib
      } else {
        break
      }
    }

    // Handle the implicit import of the built-in module in the standard library.
    if context.isCompilingStdLib && (name == "Builtin") {
      result.types.append(context.builtin)
    }

    return result
  }

}

extension ValType {

  public func lookup(member memberName: String) -> LookupResult {
    switch self {
    case let baseType as NominalType:
      return baseType.decl.lookup(qualified: memberName)

    case let baseType as InoutType:
      return baseType.base.lookup(member: memberName)

    case let baseType as SkolemType:
      guard let conformances = baseType.genericEnv.conformances(of: baseType) else {
        return LookupResult()
      }

      var result = LookupResult()
      for conf in conformances {
        result.append(contentsOf: conf.viewDecl.lookup(qualified: memberName))
      }
      return result

    default:
      return LookupResult()
    }
  }

}

extension IterableDeclSpace {

  public func lookup(qualified name: String) -> LookupResult {
    var types : [TypeDecl]  = []
    var values: [ValueDecl] = []

    for node in decls where node.state != .invalid {
      switch node {
      case let typeDecl as TypeDecl where typeDecl.name == name:
        types.append(typeDecl)

      case let valueDecl as ValueDecl where valueDecl.name == name:
        values.append(valueDecl)

      case let pbDecl as PatternBindingDecl:
        for pattern in pbDecl.pattern.namedPatterns where pattern.decl.name == name {
          values.append(pattern.decl)
        }

      default:
        continue
      }
    }

    return LookupResult(types: types, values: values)
  }

}

/// The result of a name lookup in a declaration space.
///
/// This is essentially a wrapper around two collections of type and value declarations.
public struct LookupResult {

  public init(types: [TypeDecl] = [], values: [ValueDecl] = []) {
    self.types = types
    self.values = values
  }

  /// The type declarations that were found.
  public var types: [TypeDecl]

  /// The value declarations that were found.
  public var values: [ValueDecl]

  /// Filters the lookup result with the given predicate.
  ///
  /// - Parameter isIncluded: A closure that accepts either a type or  avalue declarations and
  ///   returns whether is should be included in the returned set.
  public func filter(_ isIncluded: (TypeOrValueDecl) throws -> Bool) rethrows -> LookupResult {
    return LookupResult(
      types: try types.filter(isIncluded),
      values: try values.filter(isIncluded))
  }

  /// Appends the declarations of another lookup result.
  ///
  /// - Parameter other: Another lookup result.
  public mutating func append(contentsOf other: LookupResult) {
    types.append(contentsOf: other.types)
    values.append(contentsOf: other.values)
  }

}

extension LookupResult: Collection {

  public var startIndex: Int { 0 }

  public var endIndex: Int {
    return types.count + values.count
  }

  public func index(after position: Int) -> Int {
    return position + 1
  }

  public subscript(position: Int) -> TypeOrValueDecl {
    if position < types.count {
      return types[position]
    } else {
      return values[position - types.count]
    }
  }

}
