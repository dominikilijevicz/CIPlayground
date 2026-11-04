import Foundation

/// A tiny piece of domain logic that exists purely to give CI something
/// meaningful to test. Deliberately pure and synchronous: no UI, no I/O.
public struct Counter: Equatable, Sendable {
    /// The inclusive range the value is kept within.
    public let bounds: ClosedRange<Int>

    public private(set) var value: Int

    public init(value: Int = 0, bounds: ClosedRange<Int> = 0...10) {
        precondition(bounds.contains(value), "initial value must be inside bounds")
        self.bounds = bounds
        self.value = value
    }

    /// True when the value sits at the top of its range.
    public var isAtMaximum: Bool { value == bounds.upperBound }

    /// True when the value sits at the bottom of its range.
    public var isAtMinimum: Bool { value == bounds.lowerBound }

    /// Increases the value by `amount`, clamped to `bounds`.
    public mutating func increment(by amount: Int = 1) {
        value = min(bounds.upperBound, value + amount)
    }

    /// Decreases the value by `amount`, clamped to `bounds`.
    public mutating func decrement(by amount: Int = 1) {
        value = max(bounds.lowerBound, value - amount)
    }

    /// Returns the value to the bottom of its range.
    public mutating func reset() {
        value = bounds.lowerBound
    }
}
