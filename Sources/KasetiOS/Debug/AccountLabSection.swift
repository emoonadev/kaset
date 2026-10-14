import SwiftUI

/// Debug account panel (S5): sign in, sign out, and a read-only list of the accounts on the login.
struct AccountLabSection: View {
    @Environment(AuthService.self) private var authService
    @Environment(AccountService.self) private var accountService

    @State private var isSigningOut = false

    var body: some View {
        Section("Account") {
            LabeledContent("Session", value: self.stateDescription)

            if self.authService.state.isLoggedIn {
                if let current = self.accountService.currentAccount {
                    LabeledContent("Current", value: current.name)
                }
                ForEach(self.accountService.accounts) { account in
                    HStack {
                        Text(account.name)
                        Spacer()
                        if account.id == self.accountService.currentAccount?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                Button("Sign out", role: .destructive) {
                    self.isSigningOut = true
                    Task {
                        _ = await self.authService.signOut()
                        self.isSigningOut = false
                    }
                }
                .disabled(self.isSigningOut)
            } else {
                Button("Sign in") {
                    self.authService.startLogin()
                }
            }
        }
        .sheet(isPresented: self.loginPresented) {
            LoginSheet()
        }
    }

    private var loginPresented: Binding<Bool> {
        Binding(
            get: { self.authService.state == .loggingIn },
            set: { _ in }
        )
    }

    private var stateDescription: String {
        switch self.authService.state {
        case .initializing: "initializing"
        case .loggedOut: "signed out"
        case .loggingIn: "signing in"
        case .loggedIn: "signed in"
        }
    }
}
