import Combine

extension Store {
  /// Calls one of two closures depending on whether a store's optional state is `nil` or not, and
  /// whenever this condition changes for as long as the cancellable lives.
  ///
  /// If the store's state is non-`nil`, it will safely unwrap the value and bundle it into a new
  /// store of non-optional state that is passed to the first closure. If the store's state is
  /// `nil`, the second closure is called instead.
  ///
  /// This method is useful for handling navigation in UIKit. The state for a screen the user wants
  /// to navigate to can be held as an optional value in the parent, and when that value goes from
  /// `nil` to non-`nil`, or non-`nil` to `nil`, you can update the navigation stack accordingly:
  ///
  /// ```swift
  /// class ParentViewController: UIViewController {
  ///   let store: Store<ParentState, ParentAction>
  ///   var cancellables: Set<AnyCancellable> = []
  ///   // ...
  ///   func viewDidLoad() {
  ///     // ...
  ///     store
  ///       .scope(state: \.optionalChild, action: \.child)
  ///       .ifLet(
  ///         then: { [weak self] childStore in
  ///           self?.navigationController?.pushViewController(
  ///             ChildViewController(store: childStore),
  ///             animated: true
  ///           )
  ///         },
  ///         else: { [weak self] in
  ///           guard let self else { return }
  ///           navigationController?.popToViewController(self, animated: true)
  ///         }
  ///       )
  ///       .store(in: &cancellables)
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - unwrap: A function that is called with a store of non-optional state when the store's
  ///     state is non-`nil`, or whenever it goes from `nil` to non-`nil`.
  ///   - else: A function that is called when the store's optional state is `nil`, or whenever it
  ///     goes from non-`nil` to `nil`.
  /// - Returns: A cancellable that maintains a subscription to updates whenever the store's state
  ///   goes from `nil` to non-`nil` and vice versa, so that the caller can react to these changes.
  @available(iOS, deprecated: 9999, message: "Use 'observe' and 'if let store.scope', instead.")
  @available(macOS, deprecated: 9999, message: "Use 'observe' and 'if let store.scope', instead.")
  @available(tvOS, deprecated: 9999, message: "Use 'observe' and 'if let store.scope', instead.")
  @available(watchOS, deprecated: 9999, message: "Use 'observe' and 'if let store.scope', instead.")
  public func ifLet<Wrapped>(
    then unwrap: @escaping (_ store: Store<Wrapped, Action>) -> Void,
    else: @escaping () -> Void = {}
  ) -> any Cancellable where State == Wrapped? {
    return self
      .publisher
      .removeDuplicates(by: { ($0 != nil) == ($1 != nil) })
      .sink { [weak self] state in
        if let self, let state {
          @MainActor
          func open(_ core: some Core<State, Action>) -> any Core<Wrapped, Action> {
            IfLetCore(
              base: core,
              cachedState: state,
              stateKeyPath: \.self,
              actionKeyPath: \.self
            )
          }
          unwrap(self.scope(id: nil, childCore: open(self.core)))
        } else {
          `else`()
        }
      }
  }
}
