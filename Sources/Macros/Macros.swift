import ErrorHandle

@attached(extension, conformances: ErrList, names: arbitrary)
public macro ErrorList() = #externalMacro(
    module: "MacrosImplements",
    type: "ErrorListMacro"
)

@attached(member, names: arbitrary)
public macro ErrorBuilder<T: RawError>(
    _ errType: String? = nil,
    _ rawType: T.Type = BscRawError.self
) = #externalMacro(
    module: "MacrosImplements",
    type: "ErrorBuilderMacro"
)

@attached(peer)
public macro Mode(
    _ category: String
) = #externalMacro(
    module: "MacrosImplements",
    type: "ModeMacro"
)
