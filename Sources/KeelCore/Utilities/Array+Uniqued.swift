extension Array where Element: Hashable {
    /// The elements in their original order, without duplicates.
    public func uniqued() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
