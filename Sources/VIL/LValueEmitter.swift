import AST

/// A visitor that emits the VIL code of an l-value.
struct LValueEmitter: ExprVisitor {

  typealias ExprResult = Result<Value, EmitterError>

  /// The function emitter that owns this emitter.
  unowned let parent: FunctionEmitter

  func visit(_ node: IntLiteralExpr) -> ExprResult {
    fatalError()
  }

  func visit(_ node: AssignExpr) -> ExprResult {
    fatalError()
  }

  func visit(_ node: TupleExpr) -> ExprResult {
    fatalError()
  }

  func visit(_ node: CallExpr) -> ExprResult {
    fatalError()
  }

  func visit(_ node: UnresolvedDeclRefExpr) -> ExprResult {
    fatalError()
  }

  func visit(_ node: UnresolvedMemberExpr) -> ExprResult {
    fatalError()
  }

  func visit(_ node: UnresolvedQualDeclRefExpr) -> ExprResult {
    fatalError()
  }

  func visit(_ node: OverloadedDeclRefExpr) -> ExprResult {
    fatalError()
  }

  func visit(_ node: DeclRefExpr) -> ExprResult {
    // If the expression refers to a variable, we have to emit its access.
    if let decl = node.decl as? VarDecl {
      guard decl.hasStorage else { return .failure(.immutableLocation) }

      // If the variable is already in the local symbol table, just return its value.
      if let lv = parent.locals[ObjectIdentifier(node.decl)] {
        guard lv.type.isAddress else { return .failure(.immutableLocation) }
        return .success(lv)
      }

      // If the variable declaration resides in a nominal type declaration, then the expression
      // probably refers to a member declaration implicitly (i.e., without spelling `self`).
      if decl.parentDeclSpace is NominalTypeDecl {
        // Make sure that `self` is mutable.
        let selfDecl = parent.funDecl.selfDecl!
        guard selfDecl.type is InoutType else {
          return .failure(.immutableSelf)
        }

        let base = parent.locals[ObjectIdentifier(selfDecl)]!
        return .success(parent.builder.buildRecordMemberAddr(record: base, memberDecl: decl))
      }

      fatalError("unreachable")
    }

    // If the expression refers to a local function argument, just lookup the symbol table.
    if let decl = node.decl as? FunParamDecl {
      let lv = parent.locals[ObjectIdentifier(decl)]!
      guard lv.type.isAddress else { return .failure(.immutableLocation) }
      return .success(lv)
    }

    // FIXME: Handle global symbols.
    fatalError("unreachable")
  }

  func visit(_ node: TypeDeclRefExpr) -> ExprResult {
    fatalError()
  }

  func visit(_ node: MemberRefExpr) -> ExprResult {
    // Note that the base has to be emittable as an l-value.
    switch node.base.accept(self) {
    case .success(let base):
      // Make sure the base has an address type.
      guard case .address(let baseType) = base.type
      else { return .failure(.immutableLocation) }

      // The expression must refer to a variable declaration; function are never l-values.
      guard let decl = node.decl as? VarDecl,
            decl.hasStorage
      else { return .failure(.immutableLocation) }

      if baseType is ProductType {
        return .success(parent.builder.buildRecordMemberAddr(record: base, memberDecl: decl))
      } else {
        fatalError()
      }

    case let failure:
      return failure
    }

  }

  func visit(_ node: AddrOfExpr) -> ExprResult {
    fatalError()
  }

  func visit(_ node: WildcardExpr) -> ExprResult {
    fatalError()
  }

  func visit(_ node: ErrorExpr) -> ExprResult {
    fatalError()
  }

}
