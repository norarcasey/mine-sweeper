import MineSweeperKit
import SwiftUI

/// The grid, fitted to the space it is given (see `BoardLayout`), scrolling
/// where it overflows and zooming with a pinch.
struct BoardView: View {
    let model: GameModel

    /// Zoom kept from finished pinches, and the scale of the pinch under way.
    @State private var zoom: CGFloat = 1
    @GestureState private var pinch: CGFloat = 1

    private static let zoomRange: ClosedRange<CGFloat> = 1...3
    /// The sunken frame around the grid, taken from the space the cells fit.
    private static let frame: CGFloat = 3

    var body: some View {
        GeometryReader { proxy in
            let layout = BoardLayout(
                rows: model.game.rows,
                columns: model.game.columns,
                available: CGSize(
                    width: max(0, proxy.size.width - 2 * Self.frame),
                    height: max(0, proxy.size.height - 2 * Self.frame)
                ),
                zoom: clamped(zoom * pinch)
            )
            ScrollView([.horizontal, .vertical]) {
                grid(layout)
                    .frame(
                        minWidth: proxy.size.width,
                        minHeight: proxy.size.height
                    )
            }
            .scrollBounceBehavior(.basedOnSize, axes: [.horizontal, .vertical])
            .simultaneousGesture(
                MagnifyGesture()
                    .updating($pinch) { value, state, _ in state = value.magnification }
                    .onEnded { value in zoom = clamped(zoom * value.magnification) }
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Mine Sweeper board")
        .onChange(of: model.difficulty) { zoom = 1 }
    }

    private func grid(_ layout: BoardLayout) -> some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<layout.rows, id: \.self) { drawnRow in
                GridRow {
                    ForEach(0..<layout.columns, id: \.self) { drawnColumn in
                        let position = layout.gamePosition(row: drawnRow, column: drawnColumn)
                        CellView(
                            row: position.row,
                            column: position.column,
                            appearance: model.game.appearance(row: position.row, column: position.column),
                            size: layout.cellSize,
                            onTap: { model.tap(row: position.row, column: position.column) },
                            onLongPress: { model.longPress(row: position.row, column: position.column) }
                        )
                    }
                }
            }
        }
        .padding(Self.frame)
        .bevel(Self.frame, raised: false)
    }

    private func clamped(_ value: CGFloat) -> CGFloat {
        min(max(value, Self.zoomRange.lowerBound), Self.zoomRange.upperBound)
    }
}
