import SwiftUI

struct ContentView: View {
    @State private var counter = Counter()

    var body: some View {
        VStack(spacing: 32) {
            Text("CI Playground")
                .font(.largeTitle.bold())

            Text("\(counter.value)")
                .font(.system(size: 72, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .accessibilityIdentifier("counterValue")

            HStack(spacing: 20) {
                Button {
                    counter.decrement()
                } label: {
                    Label("Decrement", systemImage: "minus")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .disabled(counter.isAtMinimum)
                .accessibilityIdentifier("decrementButton")

                Button {
                    counter.increment()
                } label: {
                    Label("Increment", systemImage: "plus")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .disabled(counter.isAtMaximum)
                .accessibilityIdentifier("incrementButton")
            }
            .buttonStyle(.borderedProminent)

            Button("Reset") {
                counter.reset()
            }
            .accessibilityIdentifier("resetButton")
            .disabled(counter.isAtMinimum)
        }
        .padding()
        .animation(.snappy, value: counter.value)
    }
}

#Preview {
    ContentView()
}
