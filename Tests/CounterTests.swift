import Testing
@testable import CIPlayground

@Suite("Counter")
struct CounterTests {

    @Test("starts at the value it was given")
    func startsAtInitialValue() {
        let counter = Counter(value: 3)
        #expect(counter.value == 3)
    }

    @Test("increments and decrements by one")
    func incrementsAndDecrements() {
        var counter = Counter()
        counter.increment()
        counter.increment()
        #expect(counter.value == 2)

        counter.decrement()
        #expect(counter.value == 1)
    }

    @Test("clamps at the upper bound instead of overflowing")
    func clampsAtUpperBound() {
        var counter = Counter(value: 9, bounds: 0...10)
        counter.increment(by: 5)
        #expect(counter.value == 10)
        #expect(counter.isAtMaximum)
    }

    @Test("clamps at the lower bound instead of going negative")
    func clampsAtLowerBound() {
        var counter = Counter(value: 1, bounds: 0...10)
        counter.decrement(by: 5)
        #expect(counter.value == 0)
        #expect(counter.isAtMinimum)
    }

    @Test("reset returns to the bottom of the range")
    func resetReturnsToLowerBound() {
        var counter = Counter(value: 4, bounds: 2...8)
        counter.reset()
        #expect(counter.value == 2)
    }

    // A parameterised test: one declaration, many cases, each reported separately.
    @Test("incrementing by an amount lands on the expected value",
          arguments: [(0, 1, 1), (0, 3, 3), (5, 2, 7), (8, 9, 10)])
    func incrementBy(start: Int, amount: Int, expected: Int) {
        var counter = Counter(value: start)
        counter.increment(by: amount)
        #expect(counter.value == expected)
    }
}
