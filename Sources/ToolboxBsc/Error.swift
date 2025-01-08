protocol ErrListWithAddition where Self.ErrType: Err, Self.RawValue == String {
    associatedtype ErrType
    associatedtype RawValue
    var rawValue: RawValue { get }
    
    func d(_ addition: ErrType.AdditionType, _ file: String, _ line: Int) -> ErrType
    func d(_ mark: Int, _ addition: ErrType.AdditionType, _ file: String, _ line: Int) -> ErrType
    func d(_ explain: String, _ addition: ErrType.AdditionType, _ loc: (String, Int)) -> ErrType
    func d(_ explain: String, _ mark: Int, _ addition: ErrType.AdditionType, _ loc: (String, Int)) -> ErrType
}

extension ErrListWithAddition {
    func d(_ addition: ErrType.AdditionType, _ file: String, _ line: Int) -> ErrType { detail(addition: addition, loc: (file, line)) }
    func d(_ mark: Int, _ addition: ErrType.AdditionType, _ file: String, _ line: Int) -> ErrType { detail(mark: mark, addition: addition, loc: (file, line)) }
    func d(_ explain: String, _ addition: ErrType.AdditionType, _ loc: (String, Int)) -> ErrType { detail(explain: explain, addition: addition, loc: loc) }
    func d(_ explain: String, _ mark: Int, _ addition: ErrType.AdditionType, _ loc: (String, Int)) -> ErrType { detail(explain: explain, mark: mark, addition: addition, loc: loc) }
    
    fileprivate func detail(explain: String? = nil, mark: Int? = nil, addition: ErrType.AdditionType, loc: (file: String, line: Int)) -> ErrType { ErrType(description: self.rawValue, explain: explain, mark: mark, addition: addition, file: loc.file, line: loc.line) }
}

protocol ErrList: ErrListWithAddition {
    func d(_ file: String, _ line: Int) -> ErrType
    func d(_ mark: Int, _ file: String, _ line: Int) -> ErrType
    func d(_ explain: String, _ loc: (String, Int)) -> ErrType
    func d(_ explain: String, _ mark: Int, _ loc: (String, Int)) -> ErrType
}

extension ErrList where ErrType.AdditionType: ExpressibleByNilLiteral {
    func d(_ file: String, _ line: Int) -> ErrType { detail(addition: nil, loc: (file, line)) }
    func d(_ mark: Int, _ file: String, _ line: Int) -> ErrType { detail(mark: mark, addition: nil, loc: (file, line)) }
    func d(_ explain: String, _ loc: (String, Int)) -> ErrType { detail(explain: explain, addition: nil, loc: loc) }
    func d(_ explain: String, _ mark: Int, _ loc: (String, Int)) -> ErrType { detail(explain: explain, mark: mark, addition: nil, loc: loc) }
}

class ErrorAdditionTypeNull {}

protocol Err: Error {
    associatedtype AdditionType = ErrorAdditionTypeNull?

    var description: String! { get set }
    var explain: String? { get set }
    var mark: Int? { get set }
    var file: String! { get set }
    var line: Int! { get set }

    init()
    init(description: String, explain: String?, mark: Int?, addition: AdditionType, file: String, line: Int)
    func initAddtions(_ data: AdditionType)
}

extension Err {
    init(description: String, explain: String?, mark: Int?, addition: AdditionType, file: String, line: Int) {
        self.init()
        self.description = description
        self.mark = mark
        self.file = file
        self.line = line
        initAddtions(addition)
    }
}

extension Err where AdditionType == ErrorAdditionTypeNull? {
    func initAddtions(_ data: AdditionType) {}
}